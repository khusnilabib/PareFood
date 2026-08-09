-- Tests for promotions, favorites, reviews, notifications, settlements, audit_logs, driver_profiles
begin;
select plan(14);

-- promotions visible when active
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select lives_ok('insert into public.promotions (code, type, value, status) values (''PROMO10'', ''percent'', 1000, ''active'') on conflict (code) do nothing', 'insert promo (admin would normally create)');
select is((select count(*) from public.promotions where status = 'active'), 1, 'active promo visible');

-- favorites: user inserts own
select lives_ok('insert into public.favorites (user_id, restaurant_id) values (''00000000-0000-0000-0000-000000000001'', ''00000000-0000-0000-0000-000000000002'')', 'customer favorites a restaurant');
select is((select count(*) from public.favorites where user_id = auth.uid()), 1, 'customer sees own favorite');

-- reviews: customer posts review
select lives_ok('insert into public.reviews (order_id, target_type, target_id, author_id, rating) values (''00000000-0000-0000-0000-000000000101'',''restaurant'',''00000000-0000-0000-0000-000000000002'',''00000000-0000-0000-0000-000000000001'',5)', 'customer posts review');
select is((select count(*) from public.reviews where author_id = auth.uid()), 1, 'customer review inserted');

-- notifications: user can read/insert own notifications
select lives_ok('insert into public.notifications (user_id, type, title, body) values (''00000000-0000-0000-0000-000000000001'',''order'',''Test'',''Body'')', 'customer inserts own notification');
select is((select count(*) from public.notifications where user_id = auth.uid()), 1, 'customer sees own notification');

-- driver_profiles: driver cannot insert via client
set local role driver;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000004","role":"driver"}';
select throws_ok('insert into public.driver_profiles (user_id, vehicle_type) values (''00000000-0000-0000-0000-000000000004'',''motorcycle'')', null, 'driver cannot insert driver_profile via RLS (server-only)');

-- settlements: customer cannot read settlements
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is((select count(*) from public.settlements), 0, 'customer cannot read settlements');

select * from finish();
rollback;
