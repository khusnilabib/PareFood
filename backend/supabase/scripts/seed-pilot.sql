-- seed-pilot.sql — Pilot launch seed data
-- Run AFTER all migrations (0001-0012) are applied on the production project.
-- Creates: 1 admin, 3 test merchants, 2 test drivers, sample restaurants + menus.
--
-- IMPORTANT: change the phone numbers / emails before running on production.
-- Passwords are set via Supabase Auth (not here) — use the dashboard or
-- supabase auth admin API to create the auth.users rows first, then this
-- script links the profiles.

-- ===========================================================================
-- 1. Admin account (provisioned server-side, no self-signup)
-- ===========================================================================
-- Create the auth user first via:
--   supabase auth admin create-user --email admin@parefood.co --password <password>
-- Then link the profile:

insert into public.profiles (id, role, full_name, phone, status)
values (
  '00000000-0000-0000-0000-000000000010',
  'admin',
  'PareFood Admin',
  '+628110000010',
  'active'
)
on conflict (id) do update set
  role = 'admin',
  full_name = 'PareFood Admin',
  status = 'active';

-- Grant admin role
insert into public.user_roles (user_id, role, is_active)
values ('00000000-0000-0000-0000-000000000010', 'admin', true)
on conflict (user_id, role) do nothing;

-- ===========================================================================
-- 2. Test merchants (3 restaurants)
-- ===========================================================================

-- Merchant 1: Warung Nasi Goreng Pak Budi
insert into public.profiles (id, role, full_name, phone, status)
values (
  '00000000-0000-0000-0000-000000000020',
  'business',
  'Pak Budi',
  '+628110000020',
  'active'
)
on conflict (id) do update set role = 'business', full_name = 'Pak Budi', status = 'active';

insert into public.user_roles (user_id, role, is_active)
values ('00000000-0000-0000-0000-000000000020', 'business', true)
on conflict (user_id, role) do nothing;

insert into public.restaurants (id, owner_id, name, slug, description, status, commission_rate_pct, delivery_radius_km, geo)
values (
  '00000000-0000-0000-0000-000000000021',
  '00000000-0000-0000-0000-000000000020',
  'Warung Nasi Goreng Pak Budi',
  'nasi-goreng-pak-budi',
  'Nasi goreng spesial dengan bumbu rahasia',
  'active',
  15.00,
  5.0,
  st_setsrid(st_makepoint(106.816666, -6.200000), 4326)::geography
)
on conflict (id) do nothing;

-- Menu for merchant 1
insert into public.menu_categories (id, restaurant_id, name, sort_order)
values ('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000021', 'Makanan', 0)
on conflict (id) do nothing;

insert into public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, sort_order)
values
  ('00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000021', 'Nasi Goreng Spesial', 'Dengan telur dan ayam', 25000, true, 0),
  ('00000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000021', 'Nasi Goreng Ayam', 'Dengan potongan ayam', 30000, true, 1),
  ('00000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000021', 'Mie Goreng', 'Mie goreng ala rumahan', 20000, true, 2)
on conflict (id) do nothing;

-- Merchant 2: Bakso Joss
insert into public.profiles (id, role, full_name, phone, status)
values (
  '00000000-0000-0000-0000-000000000030',
  'business',
  'Bu Sari',
  '+628110000030',
  'active'
)
on conflict (id) do update set role = 'business', full_name = 'Bu Sari', status = 'active';

insert into public.user_roles (user_id, role, is_active)
values ('00000000-0000-0000-0000-000000000030', 'business', true)
on conflict (user_id, role) do nothing;

insert into public.restaurants (id, owner_id, name, slug, description, status, commission_rate_pct, delivery_radius_km, geo)
values (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000030',
  'Bakso Joss',
  'bakso-joss',
  'Bakso sapi premium dengan kuah kaldu',
  'active',
  15.00,
  4.0,
  st_setsrid(st_makepoint(106.820000, -6.210000), 4326)::geography
)
on conflict (id) do nothing;

insert into public.menu_categories (id, restaurant_id, name, sort_order)
values ('00000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000031', 'Bakso', 0)
on conflict (id) do nothing;

insert into public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, sort_order)
values
  ('00000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000032', 'Bakso Komplit', 'Urat, tetelan, iga', 35000, true, 0),
  ('00000000-0000-0000-0000-000000000034', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000032', 'Bakso Biasa', 'Bakso halus', 20000, true, 1)
on conflict (id) do nothing;

-- Merchant 3: Es Teh Manis Segar
insert into public.profiles (id, role, full_name, phone, status)
values (
  '00000000-0000-0000-0000-000000000040',
  'business',
  'Pak Joko',
  '+628110000040',
  'active'
)
on conflict (id) do update set role = 'business', full_name = 'Pak Joko', status = 'active';

insert into public.user_roles (user_id, role, is_active)
values ('00000000-0000-0000-0000-000000000040', 'business', true)
on conflict (user_id, role) do nothing;

insert into public.restaurants (id, owner_id, name, slug, description, status, commission_rate_pct, delivery_radius_km, geo)
values (
  '00000000-0000-0000-0000-000000000041',
  '00000000-0000-0000-0000-000000000040',
  'Es Teh Manis Segar',
  'es-teh-manis-segar',
  'Minuman segar untuk cuaca panas',
  'active',
  15.00,
  3.0,
  st_setsrid(st_makepoint(106.815000, -6.195000), 4326)::geography
)
on conflict (id) do nothing;

insert into public.menu_categories (id, restaurant_id, name, sort_order)
values ('00000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000041', 'Minuman', 0)
on conflict (id) do nothing;

insert into public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, sort_order)
values
  ('00000000-0000-0000-0000-000000000043', '00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000042', 'Es Teh Manis', 'Teh manis dingin', 5000, true, 0),
  ('00000000-0000-0000-0000-000000000044', '00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000042', 'Es Jeruk', 'Jeruk peras dingin', 8000, true, 1)
on conflict (id) do nothing;

-- ===========================================================================
-- 3. Test drivers (2)
-- ===========================================================================

insert into public.profiles (id, role, full_name, phone, status)
values
  ('00000000-0000-0000-0000-000000000050', 'driver', 'Andi Driver', '+628110000050', 'active'),
  ('00000000-0000-0000-0000-000000000060', 'driver', 'Budi Driver', '+628110000060', 'active')
on conflict (id) do update set role = 'driver', status = 'active';

insert into public.user_roles (user_id, role, is_active)
values
  ('00000000-0000-0000-0000-000000000050', 'driver', true),
  ('00000000-0000-0000-0000-000000000060', 'driver', true)
on conflict (user_id, role) do nothing;

-- Driver profiles
insert into public.driver_profiles (user_id, vehicle_type, status, rating_avg, review_count)
values
  ('00000000-0000-0000-0000-000000000050', 'motorcycle', 'approved', 4.8, 25),
  ('00000000-0000-0000-0000-000000000060', 'motorcycle', 'approved', 4.9, 32)
on conflict (user_id) do nothing;

-- ===========================================================================
-- 4. Sample promotions
-- ===========================================================================

insert into public.promotions (code, type, value, min_subtotal, max_discount, status, starts_at, ends_at)
values
  ('PROMO10K', 'fixed', 10000, 50000, 10000, 'active', now(), now() + interval '30 days'),
  ('DISKON20', 'percent', 20, 100000, 30000, 'active', now(), now() + interval '30 days'),
  ('GratisOngkir', 'free_delivery', 0, 25000, null, 'active', now(), now() + interval '30 days')
on conflict (code) do nothing;

-- ===========================================================================
-- Done
-- ===========================================================================
select 'Pilot seed data inserted successfully' as result;
select count(*) as restaurant_count from public.restaurants where status = 'active';
select count(*) as menu_item_count from public.menu_items;
select count(*) as driver_count from public.driver_profiles where status = 'approved';
