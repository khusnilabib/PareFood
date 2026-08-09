-- 0002_profiles.sql
-- Sprint 1 (PF-SPRINT-01, task B2)
-- profiles + addresses with RLS (PF-DOC-13 §3.2 Auth/Identity, PF-DOC-19 §3.3).

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  role        text not null check (role in ('customer', 'business', 'driver', 'admin')) default 'customer',
  full_name   text not null default '',
  phone       text not null,
  avatar_url  text,
  status      text not null check (status in ('active', 'suspended', 'deleted')) default 'active',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (phone)
);

-- Only admins may change a role; self-service blocks role mutation via RLS below.
create index if not exists idx_profiles_role on public.profiles (role);
create index if not exists idx_profiles_status on public.profiles (status);

-- Mirror role changes into the auth JWT claims (function lives in 0001; the
-- trigger must be created here, where the profiles table exists).
drop trigger if exists profiles_sync_role_claim on public.profiles;
create trigger profiles_sync_role_claim
after insert or update of role on public.profiles
for each row
execute function public.sync_role_claim();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

-- Auto-create a profile row on auth signup (FR-AUTH-001/002).
-- Role is fixed per app entry point; client passes it in signUpOptions data.
-- Phone falls back to `auth.users.phone` so phone-OTP signups (which set the
-- auth column, not metadata) still populate `profiles.phone`.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'role', 'customer'),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'phone', ''), new.phone, '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- addresses
-- ---------------------------------------------------------------------------
create table if not exists public.addresses (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  label         text not null default 'Home',
  address_line  text not null,
  geo           geography (Point, 4326) not null,
  is_default    boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_addresses_user on public.addresses (user_id);

drop trigger if exists addresses_set_updated_at on public.addresses;
create trigger addresses_set_updated_at
before update on public.addresses
for each row
execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.addresses enable row level security;

-- profiles: read/update self (non-role fields); admin all (PF-DOC-19 §3.3).
create policy profiles_select_self on public.profiles
  for select using (id = auth.uid() or auth.jwt() ->> 'role' = 'admin');

create policy profiles_update_self on public.profiles
  for update using (id = auth.uid() or auth.jwt() ->> 'role' = 'admin')
  with check (
    (id = auth.uid() and role = (select role from public.profiles where id = auth.uid()))
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy profiles_admin_all on public.profiles
  for all using (auth.jwt() ->> 'role' = 'admin');

-- addresses: owner CRUD; admin read.
create policy addresses_select_own on public.addresses
  for select using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');

create policy addresses_insert_own on public.addresses
  for insert with check (user_id = auth.uid());

create policy addresses_update_own on public.addresses
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy addresses_delete_own on public.addresses
  for delete using (user_id = auth.uid());
