-- 0004_catalog.sql
-- Sprint 1 (PF-SPRINT-01, task B4)
-- menu_categories + menu_items + menu_item_options with RLS (PF-DOC-13 §3.2 Catalog).

-- ---------------------------------------------------------------------------
-- menu_categories
-- ---------------------------------------------------------------------------
create table if not exists public.menu_categories (
  id              uuid primary key default gen_random_uuid(),
  restaurant_id   uuid not null references public.restaurants (id) on delete cascade,
  name            text not null,
  sort_order      integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_menu_categories_restaurant on public.menu_categories (restaurant_id);

drop trigger if exists menu_categories_set_updated_at on public.menu_categories;
create trigger menu_categories_set_updated_at
before update on public.menu_categories
for each row
execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- menu_items
-- ---------------------------------------------------------------------------
create table if not exists public.menu_items (
  id              uuid primary key default gen_random_uuid(),
  restaurant_id   uuid not null references public.restaurants (id) on delete cascade,
  category_id     uuid references public.menu_categories (id) on delete set null,
  name            text not null,
  description     text,
  price           bigint not null check (price >= 0),
  image_url       text,
  is_available    boolean not null default true,
  is_featured     boolean not null default false,
  sort_order      integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_menu_items_rest_avail on public.menu_items (restaurant_id, is_available);
create index if not exists idx_menu_search on public.menu_items using gin (name gin_trgm_ops);
create index if not exists idx_menu_items_category on public.menu_items (category_id);

drop trigger if exists menu_items_set_updated_at on public.menu_items;
create trigger menu_items_set_updated_at
before update on public.menu_items
for each row
execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- menu_item_options
-- ---------------------------------------------------------------------------
create table if not exists public.menu_item_options (
  id            uuid primary key default gen_random_uuid(),
  menu_item_id  uuid not null references public.menu_items (id) on delete cascade,
  group_name    text not null,
  is_required   boolean not null default false,
  choices       jsonb not null default '[]'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_menu_item_options_item on public.menu_item_options (menu_item_id);

drop trigger if exists menu_item_options_set_updated_at on public.menu_item_options;
create trigger menu_item_options_set_updated_at
before update on public.menu_item_options
for each row
execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.menu_item_options enable row level security;

-- Realtime (FR-MENU-001): catalog changes propagate to customers ≤30s.
alter publication supabase_realtime add table public.menu_categories;
alter publication supabase_realtime add table public.menu_items;
alter publication supabase_realtime add table public.menu_item_options;

-- Helper used by catalog policies: does the current user own the restaurant?
create or replace function public.is_restaurant_owner(target_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.restaurants r
    where r.id = target_restaurant_id
      and r.owner_id = auth.uid()
  );
$$;

-- menu_categories: public read (active restaurant only); owner write; admin all.
create policy menu_categories_select on public.menu_categories
  for select using (
    exists (select 1 from public.restaurants r
            where r.id = restaurant_id and r.status = 'active')
    or public.is_restaurant_owner(restaurant_id)
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy menu_categories_insert_owner on public.menu_categories
  for insert with check (public.is_restaurant_owner(restaurant_id));

create policy menu_categories_update_owner on public.menu_categories
  for update using (public.is_restaurant_owner(restaurant_id));

create policy menu_categories_delete_owner on public.menu_categories
  for delete using (public.is_restaurant_owner(restaurant_id));

create policy menu_categories_admin_all on public.menu_categories
  for all using (auth.jwt() ->> 'role' = 'admin');

-- menu_items: public read available (active restaurant); owner write; admin all.
create policy menu_items_select on public.menu_items
  for select using (
    (exists (select 1 from public.restaurants r
             where r.id = restaurant_id and r.status = 'active') and is_available = true)
    or public.is_restaurant_owner(restaurant_id)
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy menu_items_insert_owner on public.menu_items
  for insert with check (public.is_restaurant_owner(restaurant_id));

create policy menu_items_update_owner on public.menu_items
  for update using (public.is_restaurant_owner(restaurant_id));

create policy menu_items_delete_owner on public.menu_items
  for delete using (public.is_restaurant_owner(restaurant_id));

create policy menu_items_admin_all on public.menu_items
  for all using (auth.jwt() ->> 'role' = 'admin');

-- menu_item_options: public read (via item availability); owner write; admin all.
create policy menu_item_options_select on public.menu_item_options
  for select using (
    exists (select 1 from public.menu_items i
            join public.restaurants r on r.id = i.restaurant_id
            where i.id = menu_item_id
              and i.is_available = true
              and r.status = 'active')
    or public.is_restaurant_owner(
         (select restaurant_id from public.menu_items where id = menu_item_id)
       )
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy menu_item_options_insert_owner on public.menu_item_options
  for insert with check (public.is_restaurant_owner(
    (select restaurant_id from public.menu_items where id = menu_item_id)
  ));

create policy menu_item_options_update_owner on public.menu_item_options
  for update using (public.is_restaurant_owner(
    (select restaurant_id from public.menu_items where id = menu_item_id)
  ));

create policy menu_item_options_delete_owner on public.menu_item_options
  for delete using (public.is_restaurant_owner(
    (select restaurant_id from public.menu_items where id = menu_item_id)
  ));

create policy menu_item_options_admin_all on public.menu_item_options
  for all using (auth.jwt() ->> 'role' = 'admin');
