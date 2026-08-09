-- 0003_restaurants.sql
-- Sprint 1 (PF-SPRINT-01, task B3)
-- restaurants + restaurant_hours with RLS (PF-DOC-13 §3.2 Catalog, PF-DOC-19 §3.3).

-- ---------------------------------------------------------------------------
-- restaurants
-- ---------------------------------------------------------------------------
create table if not exists public.restaurants (
  id                   uuid primary key default gen_random_uuid(),
  owner_id             uuid not null references public.profiles (id) on delete cascade,
  name                 text not null,
  slug                 text not null unique,
  description          text,
  logo_url             text,
  cover_url            text,
  status               text not null check (status in ('pending', 'active', 'suspended', 'closed')) default 'pending',
  commission_rate_pct  numeric (5, 2) not null default 15.00,
  delivery_radius_km   numeric (4, 1) not null default 5.0,
  rating_avg           numeric (3, 2) not null default 0,
  review_count         integer not null default 0,
  geo                  geography (Point, 4326) not null,
  is_featured          boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index if not exists idx_restaurants_geo on public.restaurants using gist (geo);
create index if not exists idx_restaurants_status on public.restaurants (status);
create index if not exists idx_restaurants_owner on public.restaurants (owner_id);

-- Nearest-first restaurant lookup (FR-DISC-001, NFR-003).
-- Exposed via PostgREST RPC: /rest/v1/rpc/nearby_restaurants.
create or replace function public.nearby_restaurants(
  lat double precision,
  lng double precision,
  radius_km numeric default 5
)
returns table (
  id uuid,
  name text,
  slug text,
  description text,
  logo_url text,
  rating_avg numeric,
  review_count integer,
  is_featured boolean,
  distance_km numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select r.id, r.name, r.slug, r.description, r.logo_url,
         r.rating_avg, r.review_count, r.is_featured,
         round((ST_Distance(r.geo, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) / 1000)::numeric, 1)
  from public.restaurants r
  where r.status = 'active'
    and ST_DWithin(
          r.geo,
          ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
          radius_km * 1000
        )
  order by r.geo <-> ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography;
$$;

drop trigger if exists restaurants_set_updated_at on public.restaurants;
create trigger restaurants_set_updated_at
before update on public.restaurants
for each row
execute function public.set_updated_at();

-- Status is admin-owned (BR: merchant verification gates activation). Owners
-- may update every other column; any statement that assigns `status` as a
-- non-admin raises. `update of status` fires only when the column is in the
-- statement's SET list, so ordinary owner updates are unaffected.
create or replace function public.guard_restaurant_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(auth.jwt() ->> 'role', '') <> 'admin' then
    raise exception 'restaurant status changes are reserved for admin';
  end if;
  return new;
end;
$$;

drop trigger if exists restaurants_status_guard on public.restaurants;
create trigger restaurants_status_guard
before update of status on public.restaurants
for each row
execute function public.guard_restaurant_status_change();

-- ---------------------------------------------------------------------------
-- restaurant_hours
-- ---------------------------------------------------------------------------
create table if not exists public.restaurant_hours (
  id              uuid primary key default gen_random_uuid(),
  restaurant_id   uuid not null references public.restaurants (id) on delete cascade,
  day_of_week     smallint not null check (day_of_week between 0 and 6),
  open_time       time not null,
  close_time      time not null,
  is_closed       boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (restaurant_id, day_of_week)
);

create index if not exists idx_restaurant_hours_restaurant on public.restaurant_hours (restaurant_id);

drop trigger if exists restaurant_hours_set_updated_at on public.restaurant_hours;
create trigger restaurant_hours_set_updated_at
before update on public.restaurant_hours
for each row
execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.restaurants enable row level security;
alter table public.restaurant_hours enable row level security;

-- Realtime (FR-MENU-001: menu/restaurant changes propagate to customers ≤30s).
alter publication supabase_realtime add table public.restaurants;
alter publication supabase_realtime add table public.restaurant_hours;

-- restaurants: public read of active; owner (business) read/write own; admin all.
create policy restaurants_select_active on public.restaurants
  for select using (
    status = 'active'
    or owner_id = auth.uid()
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy restaurants_insert_owner on public.restaurants
  for insert with check (owner_id = auth.uid() and auth.jwt() ->> 'role' = 'business');

create policy restaurants_update_owner on public.restaurants
  for update using (owner_id = auth.uid() and auth.jwt() ->> 'role' = 'business')
  with check (owner_id = auth.uid());

create policy restaurants_admin_all on public.restaurants
  for all using (auth.jwt() ->> 'role' = 'admin');

-- restaurant_hours: public read; owner read/write own; admin all.
create policy restaurant_hours_select on public.restaurant_hours
  for select using (
    exists (select 1 from public.restaurants r
            where r.id = restaurant_id and (r.status = 'active' or r.owner_id = auth.uid()))
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy restaurant_hours_insert_owner on public.restaurant_hours
  for insert with check (
    exists (select 1 from public.restaurants r
            where r.id = restaurant_id and r.owner_id = auth.uid())
  );

create policy restaurant_hours_update_owner on public.restaurant_hours
  for update using (
    exists (select 1 from public.restaurants r
            where r.id = restaurant_id and r.owner_id = auth.uid())
  );

create policy restaurant_hours_delete_owner on public.restaurant_hours
  for delete using (
    exists (select 1 from public.restaurants r
            where r.id = restaurant_id and r.owner_id = auth.uid())
  );

create policy restaurant_hours_admin_all on public.restaurant_hours
  for all using (auth.jwt() ->> 'role' = 'admin');
