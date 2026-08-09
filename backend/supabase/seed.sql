-- Dev seed + test harness (PF-DOC-10 backend/seeds → supabase/seed.sql)
-- Idempotent; safe to re-run on `supabase db reset`.
--
-- Doubles as the harness for `supabase test db` (tests/database/*): creates
-- the app roles, three fixed auth users (profiles via the signup trigger),
-- and the fixture restaurants/menu the policy tests assert against.
--
-- Fixed UUIDs used across tests:
--   customer 00000000-0000-0000-0000-000000000001
--   business 00000000-0000-0000-0000-000000000002
--   admin    00000000-0000-0000-0000-000000000003
--   restaurant (active, owned by business)  00000000-0000-0000-0000-000000000002
--   restaurant (pending, owned by admin)    00000000-0000-0000-0000-000000000099

-- ---------------------------------------------------------------------------
-- App roles (tests run `set local role <role>` + request.jwt.claims)
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'customer') then
    create role customer nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'business') then
    create role business nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'driver') then
    create role driver nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'admin') then
    create role admin nologin;
  end if;
end
$$;

grant usage on schema public to customer, business, driver, admin;
grant select, insert, update, delete on all tables in schema public
  to customer, business, driver, admin;
grant usage on schema storage to customer, business, driver, admin;
grant select, insert, update, delete on storage.objects
  to customer, business, driver, admin;

-- Future tables (later sprints) get the same DML grants automatically.
alter default privileges in schema public
  grant select, insert, update, delete on tables
  to customer, business, driver, admin;

-- ---------------------------------------------------------------------------
-- Auth users (profiles auto-created by the handle_new_user trigger, which
-- also mirrors the role claim into auth.users.raw_app_meta_data).
-- ---------------------------------------------------------------------------
insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
   phone, phone_confirmed_at, raw_app_meta_data, raw_user_meta_data,
   created_at, updated_at, confirmation_token, recovery_token)
select
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000001',
  'authenticated', 'authenticated',
  'customer@parefood.local',
  crypt('password123', gen_salt('bf')),
  now(),
  '+6281200000001', now(),
  '{"provider":"email","providers":["email"]}',
  '{"role":"customer","full_name":"Rina Customer","phone":"+6281200000001"}',
  now(), now(), '', ''
where not exists (
  select 1 from auth.users where id = '00000000-0000-0000-0000-000000000001'
);

insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
   phone, phone_confirmed_at, raw_app_meta_data, raw_user_meta_data,
   created_at, updated_at, confirmation_token, recovery_token)
select
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000002',
  'authenticated', 'authenticated',
  'business@parefood.local',
  crypt('password123', gen_salt('bf')),
  now(),
  '+6281200000002', now(),
  '{"provider":"email","providers":["email"]}',
  '{"role":"business","full_name":"Budi Business","phone":"+6281200000002"}',
  now(), now(), '', ''
where not exists (
  select 1 from auth.users where id = '00000000-0000-0000-0000-000000000002'
);

insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
   phone, phone_confirmed_at, raw_app_meta_data, raw_user_meta_data,
   created_at, updated_at, confirmation_token, recovery_token)
select
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000003',
  'authenticated', 'authenticated',
  'admin@parefood.local',
  crypt('password123', gen_salt('bf')),
  now(),
  '+6281200000003', now(),
  '{"provider":"email","providers":["email"]}',
  '{"role":"admin","full_name":"Ayu Admin","phone":"+6281200000003"}',
  now(), now(), '', ''
where not exists (
  select 1 from auth.users where id = '00000000-0000-0000-0000-000000000003'
);

-- ---------------------------------------------------------------------------
-- Restaurants: one active (business-owned) + one pending (admin-owned).
-- No hours are seeded: the policy tests insert their own and assert counts.
-- ---------------------------------------------------------------------------
insert into public.restaurants
  (id, owner_id, name, slug, description, status, geo, commission_rate_pct)
values
  ('00000000-0000-0000-0000-000000000002',
   '00000000-0000-0000-0000-000000000002',
   'Warung Nusantara',
   'warung-nusantara',
   'Masakan Indonesia otentik',
   'active',
   ST_SetSRID(ST_Point(106.8456, -6.2088), 4326),
   15.00)
on conflict (id) do nothing;

insert into public.restaurants
  (id, owner_id, name, slug, description, status, geo, commission_rate_pct)
values
  ('00000000-0000-0000-0000-000000000099',
   '00000000-0000-0000-0000-000000000003',
   'Warung Verifikasi',
   'warung-verifikasi',
   'Menunggu verifikasi admin',
   'pending',
   ST_SetSRID(ST_Point(106.8500, -6.2100), 4326),
   15.00)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Menu: exactly one category + one available item for the active restaurant.
-- Test 03 relies on these counts (it inserts its own item, then hides it).
-- ---------------------------------------------------------------------------
insert into public.menu_categories (restaurant_id, name, sort_order)
select '00000000-0000-0000-0000-000000000002', 'Makanan', 0
where not exists (
  select 1 from public.menu_categories
  where restaurant_id = '00000000-0000-0000-0000-000000000002'
);

insert into public.menu_items (restaurant_id, category_id, name, description, price, sort_order)
select
  '00000000-0000-0000-0000-000000000002',
  c.id,
  'Nasi Goreng Spesial',
  'Nasi goreng dengan telur dan ayam suwir',
  25000,
  0
from public.menu_categories c
where c.restaurant_id = '00000000-0000-0000-0000-000000000002'
  and not exists (
    select 1 from public.menu_items
    where restaurant_id = '00000000-0000-0000-0000-000000000002'
  );
