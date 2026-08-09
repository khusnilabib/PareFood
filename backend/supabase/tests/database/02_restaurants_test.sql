-- Policy tests — restaurants & hours (PF-DOC-19 §3.3, PF-DOC-20 §3.4)
-- Run via `supabase test db` against the local emulator (role matrix).
-- Harness (seed.sql): business (user 2) owns active restaurant ...0002;
-- admin (user 3) owns pending restaurant ...0099.
begin;
select plan(11);

-- public (customer) sees only active restaurants
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is(
  (select count(*)::int from public.restaurants where status = 'active'),
  1,
  'customer sees active restaurants only'
);
select is(
  (select count(*)::int from public.restaurants where status = 'pending'),
  0,
  'customer does not see pending restaurants'
);

-- business owns its restaurant: read + write own
set local role business;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000002","role":"business"}';
select is(
  (select count(*)::int from public.restaurants where id = '00000000-0000-0000-0000-000000000002'),
  1,
  'business reads own restaurant'
);
select lives_ok(
  'update public.restaurants set name = ''Warung Baru'' where id = ''00000000-0000-0000-0000-000000000002''',
  'business updates own restaurant'
);
select throws_ok(
  'update public.restaurants set status = ''active'' where id = ''00000000-0000-0000-0000-000000000002''',
  null,
  'business cannot self-activate (status change reserved for admin)'
);

-- business cannot write another restaurant: RLS filters the row, so the
-- update is a silent no-op; admin verifies nothing changed below.
update public.restaurants
   set name = 'Hacked'
 where id = '00000000-0000-0000-0000-000000000099';

-- hours: business writes own restaurant hours
select lives_ok(
  'insert into public.restaurant_hours (restaurant_id, day_of_week, open_time, close_time) values (''00000000-0000-0000-0000-000000000002'', 0, ''08:00'', ''22:00'')',
  'business inserts hours for own restaurant'
);

-- customer reads hours of active restaurant
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is(
  (select count(*)::int from public.restaurant_hours),
  1,
  'customer reads hours of active restaurant'
);

-- admin manages all
set local role admin;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000003","role":"admin"}';
select lives_ok(
  'update public.restaurants set status = ''active'' where id = ''00000000-0000-0000-0000-000000000002''',
  'admin activates restaurant'
);
select is(
  (select count(*)::int from public.restaurants),
  2,
  'admin reads all restaurants'
);
select is(
  (select count(*)::int from public.restaurants
    where id = '00000000-0000-0000-0000-000000000099' and name = 'Hacked'),
  0,
  'business update of another restaurant was a no-op'
);

select * from finish();
rollback;
