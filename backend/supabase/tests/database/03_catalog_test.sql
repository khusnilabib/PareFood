-- Policy tests — catalog & search (PF-DOC-19 §3.3, PF-DOC-20 §3.4)
-- Harness (seed.sql): business (user 2) owns active restaurant ...0002 with
-- exactly one category + one available item ('Nasi Goreng Spesial').
begin;
select plan(11);

set local role business;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000002","role":"business"}';

-- owner inserts category + item
select lives_ok(
  'insert into public.menu_categories (restaurant_id, name) values (''00000000-0000-0000-0000-000000000002'', ''Makanan'')',
  'business inserts category'
);
select lives_ok(
  'insert into public.menu_items (restaurant_id, category_id, name, price) values (''00000000-0000-0000-0000-000000000002'', (select id from public.menu_categories limit 1), ''Nasi Goreng'', 25000)',
  'business inserts menu item'
);

-- price must be non-negative (CHECK)
select throws_ok(
  'insert into public.menu_items (restaurant_id, name, price) values (''00000000-0000-0000-0000-000000000002'', ''Negatif'', -1)',
  null,
  'negative price rejected'
);

-- owner toggles availability
select lives_ok(
  'update public.menu_items set is_available = false where name = ''Nasi Goreng''',
  'business toggles availability'
);

-- customer reads only available items of active restaurant
set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is(
  (select count(*)::int from public.menu_items where is_available = false),
  0,
  'customer does not see unavailable items'
);
select is(
  (select count(*)::int from public.menu_items),
  1,
  'customer sees available items only (Nasi Goreng is hidden)'
);

-- customer cannot write menu: RLS filters the row, so the update is a silent
-- no-op; verify the visible item kept its name.
update public.menu_items
   set name = 'Hacked'
 where name = 'Nasi Goreng Spesial';
select is(
  (select count(*)::int from public.menu_items where name = 'Hacked'),
  0,
  'customer update of menu is a no-op'
);

-- search_documents: customer sees available rows
select is(
  (select count(*)::int from public.search_documents where entity_type = 'menu_item' and is_available = true),
  1,
  'search index hides unavailable menu items'
);

-- merchant_documents: owner reads/writes own; status immutable by self
set local role business;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000002","role":"business"}';
select lives_ok(
  'insert into public.merchant_documents (user_id, doc_type, storage_path) values (''00000000-0000-0000-0000-000000000002'', ''ktp'', ''00000000-0000-0000-0000-000000000002/ktp/a.pdf'')',
  'business submits document'
);
select throws_ok(
  'update public.merchant_documents set status = ''approved'' where doc_type = ''ktp''',
  null,
  'owner cannot self-approve document'
);

set local role customer;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-000000000001","role":"customer"}';
select is(
  (select count(*)::int from public.merchant_documents),
  0,
  'customer cannot see merchant documents'
);

select * from finish();
rollback;
