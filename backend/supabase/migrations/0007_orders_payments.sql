-- 0007_orders_payments.sql
-- Sprint 1+ (core orders, deliveries, wallets, payment intents) — add essential tables + RLS
-- Implements core tables referenced by PF-DOC-13: orders, order_items, order_status_history,
-- deliveries, driver_locations, wallets, wallet_transactions, payment_intents

-- Orders
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_no text not null unique,
  customer_id uuid not null references public.profiles (id) on delete cascade,
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  driver_id uuid references public.profiles (id),
  status text not null check (status in ('placed','accepted','preparing','ready','picked_up','delivered','cancelled','refunded')) default 'placed',
  subtotal bigint not null,
  delivery_fee bigint not null default 0,
  service_fee bigint not null default 0,
  discount bigint not null default 0,
  total bigint not null,
  payment_method text not null check (payment_method in ('cod','ewallet','card')),
  payment_status text not null check (payment_status in ('pending','paid','refunded','failed')) default 'pending',
  payment_intent_id uuid,
  idempotency_key uuid,
  delivery_address text,
  delivery_geo geography(Point,4326),
  estimated_minutes integer,
  placed_at timestamptz default now(),
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_orders_customer on public.orders (customer_id);
create index if not exists idx_orders_restaurant on public.orders (restaurant_id);
create index if not exists idx_orders_driver on public.orders (driver_id);

-- Order items snapshot
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  menu_item_id uuid,
  item_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price bigint not null,
  selected_options jsonb,
  line_total bigint not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_order_items_order on public.order_items (order_id);

-- Order status history (append-only)
create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  from_status text,
  to_status text not null,
  changed_by uuid,
  reason text,
  created_at timestamptz not null default now()
);
create index if not exists idx_order_status_order on public.order_status_history (order_id);

-- Deliveries (dispatch jobs)
create table if not exists public.deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) unique,
  driver_id uuid references public.profiles (id),
  status text not null check (status in ('assigned','arrived_pickup','picked_up','delivered','failed')) default 'assigned',
  pickup_code text,
  accepted_at timestamptz,
  arrived_at timestamptz,
  picked_up_at timestamptz,
  delivered_at timestamptz,
  proof_photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_deliveries_driver on public.deliveries (driver_id);

-- Driver locations (live positions)
create table if not exists public.driver_locations (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.profiles (id) unique,
  geo geography(Point,4326) not null,
  heading numeric,
  speed numeric,
  online boolean not null default false,
  updated_at timestamptz not null default now()
);
create index if not exists idx_driver_locations_driver on public.driver_locations (driver_id);
create index if not exists idx_driver_locations_geo on public.driver_locations using gist (geo);

-- Wallets & transactions
create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) unique,
  balance bigint not null default 0,
  currency text not null default 'IDR',
  updated_at timestamptz not null default now()
);
create index if not exists idx_wallets_user on public.wallets (user_id);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets (id) on delete cascade,
  tx_type text not null check (tx_type in ('credit','debit')),
  reason text not null,
  amount bigint not null,
  reference_id uuid,
  status text not null check (status in ('pending','completed','failed','reversed')) default 'pending',
  external_tx_id text,
  created_at timestamptz not null default now()
);
create index if not exists idx_wallet_tx_wallet on public.wallet_transactions (wallet_id);

-- Payment intents (PSP tracking)
create table if not exists public.payment_intents (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders (id),
  intent_type text not null check (intent_type in ('charge','refund','payout')),
  amount bigint not null,
  psp text,
  psp_status text,
  status text not null check (status in ('created','processing','succeeded','failed','refunded')) default 'created',
  webhook_received_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_payment_intents_order on public.payment_intents (order_id);

-- Triggers: updated_at
-- Reuse set_updated_at() from 0001

-- Orders updated_at trigger
create or replace function public.orders_set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at := now(); return new; end; $$;
drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at before update on public.orders for each row execute function public.orders_set_updated_at();

create or replace function public.deliveries_set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at := now(); return new; end; $$;
drop trigger if exists deliveries_set_updated_at on public.deliveries;
create trigger deliveries_set_updated_at before update on public.deliveries for each row execute function public.deliveries_set_updated_at();

-- Enable RLS on new tables
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.deliveries enable row level security;
alter table public.driver_locations enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.payment_intents enable row level security;

-- Policies
-- orders: customer sees own; restaurant sees own; driver sees assigned; admin all
create policy orders_select_customer on public.orders
  for select using (
    customer_id = auth.uid()
    or restaurant_id in (select id from public.restaurants where owner_id = auth.uid())
    or driver_id = auth.uid()
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy orders_insert_customer on public.orders
  for insert with check (customer_id = auth.uid());

create policy orders_update_owner on public.orders
  for update using (
    (customer_id = auth.uid() and auth.jwt() ->> 'role' = 'customer')
    or (restaurant_id in (select id from public.restaurants where owner_id = auth.uid()) and auth.jwt() ->> 'role' = 'business')
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy orders_admin_all on public.orders
  for all using (auth.jwt() ->> 'role' = 'admin');

-- order_items: read with order owner; insert only via server (Edge functions)
create policy order_items_select on public.order_items
 for select using (exists (select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.restaurant_id in (select id from public.restaurants where owner_id = auth.uid()) or auth.jwt() ->> 'role' = 'admin')));

create policy order_items_insert_none on public.order_items
 for insert with check (false);

-- order_status_history: read own orders; inserts only via server internal (admin)
create policy order_status_select on public.order_status_history
 for select using (exists (select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.restaurant_id in (select id from public.restaurants where owner_id = auth.uid()) or auth.jwt() ->> 'role' = 'admin')));
create policy order_status_insert_none on public.order_status_history for insert with check (false);

-- deliveries: driver sees own; restaurant/admin see related; insert only internal
create policy deliveries_select on public.deliveries
 for select using (driver_id = auth.uid() or exists (select 1 from public.orders o where o.id = order_id and (o.restaurant_id in (select id from public.restaurants where owner_id = auth.uid()) or o.customer_id = auth.uid())) or auth.jwt() ->> 'role' = 'admin');
create policy deliveries_insert_none on public.deliveries for insert with check (false);
create policy deliveries_update_driver on public.deliveries for update using (driver_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');

-- driver_locations: driver writes own location; assigned-order reads scoped in application (RLS: driver_id = auth.uid() or admin)
create policy driver_locations_select on public.driver_locations for select using (driver_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');
create policy driver_locations_insert_own on public.driver_locations for insert with check (driver_id = auth.uid());
create policy driver_locations_update_own on public.driver_locations for update using (driver_id = auth.uid());

-- wallets: self-read; writes via Edge Functions only
create policy wallets_select on public.wallets for select using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');
create policy wallets_insert_none on public.wallets for insert with check (false);
create policy wallets_update_admin on public.wallets for update using (auth.jwt() ->> 'role' = 'admin');

-- wallet_transactions: self read; insert via server
create policy wallet_tx_select on public.wallet_transactions for select using (exists (select 1 from public.wallets w where w.id = wallet_id and (w.user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin')));
create policy wallet_tx_insert_none on public.wallet_transactions for insert with check (false);

-- payment_intents: admin/owner read; insert via server
create policy payment_intents_select on public.payment_intents for select using (exists (select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.restaurant_id in (select id from public.restaurants where owner_id = auth.uid()) or auth.jwt() ->> 'role' = 'admin')));
create policy payment_intents_insert_none on public.payment_intents for insert with check (false);

-- publish to realtime where appropriate
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.deliveries;
alter publication supabase_realtime add table public.driver_locations;

-- end migration
