-- 0011_user_roles.sql
-- Sprint 2 (FR-AUTH-006: multi-role accounts; PF-DOC-13 §5.1 `user_roles`).
--
-- One user may hold multiple roles (e.g. a merchant who also orders as a
-- customer, or a driver who also runs a restaurant). The `profiles.role`
-- column remains the *active* role mirrored into the JWT; this table holds
-- the full set of roles a user may switch to.
--
-- Switching the active role updates profiles.role, which the existing
-- `profiles_sync_role_claim` trigger (0002) mirrors into
-- auth.users.raw_app_meta_data['role'] → JWT app_metadata.role. The next
-- token refresh (re-login) carries the new active role.

create table if not exists public.user_roles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  role        text not null check (role in ('customer', 'business', 'driver', 'admin')),
  is_active   boolean not null default false,
  granted_by  uuid references public.profiles (id),
  created_at  timestamptz not null default now(),
  unique (user_id, role)
);

create index if not exists idx_user_roles_user on public.user_roles (user_id);
create index if not exists idx_user_roles_active on public.user_roles (user_id) where is_active;

-- RLS: self read own roles; admin all; inserts/updates only via service role
-- (Edge Functions) or admin. Self cannot grant themselves a role (PF-DOC-19).
alter table public.user_roles enable row level security;

create policy user_roles_select_self on public.user_roles
  for select using (
    user_id = auth.uid()
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy user_roles_insert_none on public.user_roles
  for insert with check (false);

create policy user_roles_update_none on public.user_roles
  for update with check (false);

create policy user_roles_delete_none on public.user_roles
  for delete using (false);

-- ---------------------------------------------------------------------------
-- Function: switch_active_role(p_user uuid, p_role text)
-- Sets one role active for the user and deactivates the rest; mirrors the
-- active role into profiles.role so the JWT claim updates on next refresh.
-- SECURITY DEFINER so it can write both tables; callable only by the user
-- themselves or an admin (enforced inside).
-- ---------------------------------------------------------------------------
create or replace function public.switch_active_role(p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_count integer;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  -- The caller must hold the role they want to switch to.
  select count(*) into v_count
    from public.user_roles
   where user_id = v_user and role = p_role;
  if v_count = 0 then
    raise exception 'Role % not held by user', p_role using errcode = '42501';
  end if;

  -- Deactivate all the user's roles, activate the chosen one.
  update public.user_roles set is_active = false where user_id = v_user;
  update public.user_roles set is_active = true
   where user_id = v_user and role = p_role;

  -- Mirror into profiles.role → trigger syncs the JWT claim.
  update public.profiles set role = p_role where id = v_user;
end;
$$;

-- Auto-grant the signup role as the first user_role row (FR-AUTH-002).
-- Runs after profile creation; idempotent.
create or replace function public.grant_signup_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_roles (user_id, role, is_active)
  values (new.id, new.role, true)
  on conflict (user_id, role) do nothing;
  return new;
end;
$$;

drop trigger if exists profiles_grant_signup_role on public.profiles;
create trigger profiles_grant_signup_role
after insert on public.profiles
for each row
execute function public.grant_signup_role();

-- Backfill: grant every existing profile its current role as an active
-- user_role row (safe to re-run; ON CONFLICT skips existing).
insert into public.user_roles (user_id, role, is_active)
select id, role, true from public.profiles
on conflict (user_id, role) do nothing;

-- end migration
