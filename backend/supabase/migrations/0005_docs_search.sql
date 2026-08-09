-- 0005_docs_search.sql
-- Sprint 1 (PF-SPRINT-01, task B5)
-- merchant_documents + search_documents with RLS and sync triggers
-- (PF-DOC-13 §3.2 Admin/Ops + Search, PF-DOC-19 §3.3).

-- ---------------------------------------------------------------------------
-- merchant_documents
-- ---------------------------------------------------------------------------
create table if not exists public.merchant_documents (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  doc_type      text not null check (doc_type in ('ktp', 'nib')),
  storage_path  text not null,
  status        text not null check (status in ('submitted', 'reviewed', 'approved', 'rejected')) default 'submitted',
  reviewed_by   uuid references public.profiles (id),
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_merchant_documents_user on public.merchant_documents (user_id, status);

drop trigger if exists merchant_documents_set_updated_at on public.merchant_documents;
create trigger merchant_documents_set_updated_at
before update on public.merchant_documents
for each row
execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- search_documents
-- ---------------------------------------------------------------------------
create table if not exists public.search_documents (
  id              uuid primary key default gen_random_uuid(),
  entity_type     text not null check (entity_type in ('restaurant', 'menu_item')),
  entity_id       uuid not null,
  restaurant_id   uuid not null references public.restaurants (id) on delete cascade,
  name            text not null,
  tags            text,
  is_available    boolean not null default true,
  geo             geography (Point, 4326),
  updated_at      timestamptz not null default now(),
  unique (entity_type, entity_id)
);

create index if not exists idx_search_name on public.search_documents using gin (name gin_trgm_ops, tags gin_trgm_ops);
create index if not exists idx_search_restaurant on public.search_documents (restaurant_id, entity_type);

-- Sync triggers (PF-DOC-13 §search): maintain rows from restaurants/menu_items.

create or replace function public.upsert_restaurant_search_document()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'active' then
    insert into public.search_documents
      (entity_type, entity_id, restaurant_id, name, tags, is_available, geo)
    values
      ('restaurant', new.id, new.id, new.name, new.slug, true, new.geo)
    on conflict (entity_type, entity_id) do update
      set name = excluded.name, tags = excluded.tags, geo = excluded.geo, updated_at = now();
  else
    delete from public.search_documents
      where entity_type = 'restaurant' and entity_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists restaurants_search_sync on public.restaurants;
create trigger restaurants_search_sync
after insert or update of status, name, slug, geo on public.restaurants
for each row
execute function public.upsert_restaurant_search_document();

create or replace function public.upsert_menu_item_search_document()
returns trigger
language plpgsql
as $$
begin
  insert into public.search_documents
    (entity_type, entity_id, restaurant_id, name, tags, is_available)
  values
    ('menu_item', new.id, new.restaurant_id, new.name, null, new.is_available)
  on conflict (entity_type, entity_id) do update
    set name = excluded.name, is_available = excluded.is_available, updated_at = now();
  return new;
end;
$$;

drop trigger if exists menu_items_search_sync on public.menu_items;
create trigger menu_items_search_sync
after insert or update of name, is_available, restaurant_id on public.menu_items
for each row
execute function public.upsert_menu_item_search_document();

create or replace function public.delete_menu_item_search_document()
returns trigger
language plpgsql
as $$
begin
  delete from public.search_documents
    where entity_type = 'menu_item' and entity_id = old.id;
  return old;
end;
$$;

drop trigger if exists menu_items_search_delete on public.menu_items;
create trigger menu_items_search_delete
after delete on public.menu_items
for each row
execute function public.delete_menu_item_search_document();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.merchant_documents enable row level security;
alter table public.search_documents enable row level security;

-- merchant_documents: owner read/write own; admin all (PF-DOC-19 §3.3).
create policy merchant_documents_select_own on public.merchant_documents
  for select using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');

create policy merchant_documents_insert_own on public.merchant_documents
  for insert with check (user_id = auth.uid());

-- WITH CHECK may reference the existing row via the table name: owners may
-- rewrite their own document row but never change `status` (admin-only field).
create policy merchant_documents_update_own on public.merchant_documents
  for update using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and status = merchant_documents.status
  );

create policy merchant_documents_delete_own on public.merchant_documents
  for delete using (user_id = auth.uid());

create policy merchant_documents_admin_all on public.merchant_documents
  for all using (auth.jwt() ->> 'role' = 'admin');

-- search_documents: public read of available rows (NFR-004).
create policy search_documents_select on public.search_documents
  for select using (is_available = true or auth.jwt() ->> 'role' = 'admin');
