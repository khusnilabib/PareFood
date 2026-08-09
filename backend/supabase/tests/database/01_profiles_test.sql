-- Policy tests — profiles & addresses (PF-DOC-19 §3.3, PF-DOC-20 §3.4)
-- Run via `supabase test db` against the local emulator (role matrix).
begin;
select plan(10);

-- Roles used by this suite: customer (user 1), business (user 2), admin (user 3)
-- seeded by the test harness.

-- profiles: customer reads self
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is(
  (select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-000000000001'),
  1,
  'customer reads own profile'
);
select is(
  (select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-000000000002'),
  0,
  'customer cannot read another profile'
);

-- customer cannot change own role
select throws_ok(
  'update public.profiles set role = ''business'' where id = ''00000000-0000-0000-0000-000000000001''',
  null,
  'customer cannot change own role'
);

-- customer updates own name
select lives_ok(
  'update public.profiles set full_name = ''Rina'' where id = ''00000000-0000-0000-0000-000000000001''',
  'customer updates own full_name'
);

-- addresses: owner CRUD
select lives_ok(
  'insert into public.addresses (user_id, label, address_line, geo) values (''00000000-0000-0000-0000-000000000001'', ''Rumah'', ''Jl. Mawar 1'', ST_SetSRID(ST_Point(106.8456, -6.2088), 4326))',
  'customer inserts own address'
);
select is(
  (select count(*)::int from public.addresses where user_id = '00000000-0000-0000-0000-000000000001'),
  1,
  'customer sees own address'
);
select is(
  (select count(*)::int from public.addresses where user_id = '00000000-0000-0000-0000-000000000002'),
  0,
  'customer cannot see another address'
);
select throws_ok(
  'update public.addresses set user_id = ''00000000-0000-0000-0000-000000000002'' where label = ''Rumah''',
  null,
  'customer cannot reassign address ownership'
);

-- admin reads all profiles
set local role admin;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000003","role":"admin"}';
select is(
  (select count(*)::int from public.profiles),
  3,
  'admin reads all profiles'
);
select lives_ok(
  'update public.profiles set status = ''suspended'' where id = ''00000000-0000-0000-0000-000000000001''',
  'admin suspends user'
);

select * from finish();
rollback;
