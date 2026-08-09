-- Policy tests — storage buckets (PF-DOC-12 §3.4, PF-DOC-19 §3.3)
-- Run via `supabase test db` against the local emulator (role matrix).
-- Harness (seed.sql): business (user 2) owns restaurant ...0002;
-- admin (user 3) owns restaurant ...0099.
-- Path conventions (SUP-R05): product-images <restaurant_id>/...,
-- merchant-docs <user_id>/..., avatars <user_id>/...
begin;
select plan(10);

-- business: may write own-restaurant product images, own docs, own avatar
set local role business;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000002","role":"business"}';
select lives_ok(
  'insert into storage.objects (bucket_id, name) values (''product-images'', ''00000000-0000-0000-0000-000000000002/products/p1.jpg'')',
  'business uploads product image for own restaurant'
);
select throws_ok(
  'insert into storage.objects (bucket_id, name) values (''product-images'', ''00000000-0000-0000-0000-000000000099/products/p2.jpg'')',
  null,
  'business cannot upload product image for another restaurant'
);
select lives_ok(
  'insert into storage.objects (bucket_id, name) values (''merchant-docs'', ''00000000-0000-0000-0000-000000000002/ktp/k1.pdf'')',
  'business uploads own merchant document'
);
select lives_ok(
  'insert into storage.objects (bucket_id, name) values (''avatars'', ''00000000-0000-0000-0000-000000000002/a1.png'')',
  'business uploads own avatar'
);

-- customer: no restaurant ownership, writes only own avatar path
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select throws_ok(
  'insert into storage.objects (bucket_id, name) values (''product-images'', ''00000000-0000-0000-0000-000000000002/products/p3.jpg'')',
  null,
  'customer cannot upload product images'
);
select throws_ok(
  'insert into storage.objects (bucket_id, name) values (''avatars'', ''00000000-0000-0000-0000-000000000002/a2.png'')',
  null,
  'customer cannot upload into another user avatar path'
);
select is(
  (select count(*)::int from storage.objects where bucket_id = 'product-images'),
  1,
  'customer reads public product images'
);
select is(
  (select count(*)::int from storage.objects where bucket_id = 'merchant-docs'),
  0,
  'customer cannot read merchant documents'
);
select is(
  (select count(*)::int from storage.objects where bucket_id = 'avatars'),
  1,
  'customer reads public avatars'
);

-- admin: reads all buckets including private merchant-docs
set local role admin;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000003","role":"admin"}';
select is(
  (select count(*)::int from storage.objects where bucket_id = 'merchant-docs'),
  1,
  'admin reads merchant documents of any owner'
);

select * from finish();
rollback;
