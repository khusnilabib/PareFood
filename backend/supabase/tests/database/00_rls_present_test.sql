-- RLS presence check (T3 / PF-DOC-13): every Sprint 1 public table must have
-- row level security enabled. Fails the suite if any table below is unprotected.
begin;

select plan(18);

select has_table('public', 'profiles');
select has_table('public', 'addresses');
select has_table('public', 'restaurants');
select has_table('public', 'restaurant_hours');
select has_table('public', 'menu_categories');
select has_table('public', 'menu_items');
select has_table('public', 'menu_item_options');
select has_table('public', 'merchant_documents');
select has_table('public', 'search_documents');

-- RLS enabled on every table (PF-DOC-13: "RLS on every table").
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'profiles'),
  'RLS enabled on profiles'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'addresses'),
  'RLS enabled on addresses'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'restaurants'),
  'RLS enabled on restaurants'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'restaurant_hours'),
  'RLS enabled on restaurant_hours'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'menu_categories'),
  'RLS enabled on menu_categories'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'menu_items'),
  'RLS enabled on menu_items'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'menu_item_options'),
  'RLS enabled on menu_item_options'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'merchant_documents'),
  'RLS enabled on merchant_documents'
);
select ok(
  (select relrowsecurity
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'search_documents'),
  'RLS enabled on search_documents'
);

select * from finish();
rollback;
