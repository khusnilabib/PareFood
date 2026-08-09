-- Policy tests — orders, deliveries, driver_locations, wallets (RLS)
begin;
select plan(16);

-- Roles: customer (user1), business (user2), admin (user3), driver (user4)

-- Seeded roles present in seed.sql; add a driver user fixture
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, phone, raw_user_meta_data, created_at, updated_at)
select '00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'driver@parefood.local', crypt('password123', gen_salt('bf')), '+6281200000004', '{"role":"driver","full_name":"Dono Driver","phone":"+6281200000004"}', now(), now()
where not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-000000000004');

-- Create a simple order as admin (bypass RLS via admin role in seed harness)
set local role admin;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000003","role":"admin"}';

insert into public.orders (id, order_no, customer_id, restaurant_id, subtotal, total, payment_method, payment_status)
values ('00000000-0000-0000-0000-000000000101', 'PF-20260809-0001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 25000, 28000, 'ewallet', 'pending')
on conflict (id) do nothing;

-- Customer reads own order
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is((select count(*) from public.orders where id = '00000000-0000-0000-0000-000000000101' and customer_id = auth.uid()), 1, 'customer reads own order');

-- Customer cannot read others' orders
select is((select count(*) from public.orders where customer_id = '00000000-0000-0000-0000-000000000002'), 0, 'customer cannot read other customer orders');

-- Business (restaurant owner) reads order for own restaurant
set local role business;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000002","role":"business"}';
select is((select count(*) from public.orders where id = '00000000-0000-0000-0000-000000000101' and restaurant_id in (select id from public.restaurants where owner_id = auth.uid())), 1, 'business reads own restaurant order');

-- Driver cannot read order unless assigned
set local role driver;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000004","role":"driver"}';
select is((select count(*) from public.orders where id = '00000000-0000-0000-0000-000000000101' and driver_id = auth.uid()), 0, 'unassigned driver cannot read order');

-- Admin reads all orders
set local role admin;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000003","role":"admin"}';
select is((select count(*) from public.orders where id = '00000000-0000-0000-0000-000000000101'), 1, 'admin reads order');

-- Driver location insert: driver writes own location
set local role driver;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000004","role":"driver"}';
select lives_ok('insert into public.driver_locations (driver_id, geo, online) values (''00000000-0000-0000-0000-000000000004'', ST_SetSRID(ST_Point(106.9, -6.2), 4326), true)', 'driver inserts own location');

-- Customer cannot insert driver location
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select throws_ok('insert into public.driver_locations (driver_id, geo, online) values (''00000000-0000-0000-0000-000000000004'', ST_SetSRID(ST_Point(106.9, -6.2), 4326), true)', null, 'customer cannot insert driver location');

-- Wallets: admin may inspect, customer sees own wallet (create via admin first)
set local role admin;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000003","role":"admin"}';
insert into public.wallets (user_id, balance, currency) values ('00000000-0000-0000-0000-000000000001', 0, 'IDR') on conflict (user_id) do nothing;

set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is((select count(*) from public.wallets where user_id = auth.uid()), 1, 'customer sees own wallet');

-- Wallet transaction insert must fail for customer (server-only insert)
select throws_ok('insert into public.wallet_transactions (wallet_id, tx_type, reason, amount) values ((select id from public.wallets where user_id = ''00000000-0000-0000-0000-000000000001''), ''credit'', ''test'', 10000)', null, 'customer cannot insert wallet transaction');

select * from finish();
rollback;
