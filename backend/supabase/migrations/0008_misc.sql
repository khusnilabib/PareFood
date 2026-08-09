-- 0008_misc.sql
-- Sprint 1+ (additional tables): promotions, promo_redemptions, favorites, reviews, notifications, promo_redemptions, settlements, audit_logs, driver_profiles

-- Promotions
create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  type text not null check (type in ('fixed','percent','free_delivery')),
  value bigint not null,
  min_subtotal bigint,
  max_discount bigint,
  usage_limit integer,
  used_count integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  status text not null check (status in ('active','disabled','expired')) default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_promotions_code on public.promotions (code);

drop trigger if exists promotions_set_updated_at on public.promotions;
create trigger promotions_set_updated_at before update on public.promotions for each row execute function public.set_updated_at();

-- Promo redemptions
create table if not exists public.promo_redemptions (
  id uuid primary key default gen_random_uuid(),
  promo_id uuid not null references public.promotions (id) on delete cascade,
  user_id uuid not null references public.profiles (id),
  order_id uuid,
  created_at timestamptz not null default now(),
  unique (promo_id, user_id, order_id)
);
create index if not exists idx_promo_redemptions_user on public.promo_redemptions (promo_id, user_id);

-- Favorites
create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  restaurant_id uuid not null references public.restaurants (id),
  created_at timestamptz not null default now(),
  unique (user_id, restaurant_id)
);
create index if not exists idx_favorites_user on public.favorites (user_id);

-- Reviews
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  target_type text not null check (target_type in ('restaurant','driver')),
  target_id uuid not null,
  author_id uuid not null references public.profiles (id),
  rating smallint not null check (rating between 1 and 5),
  comment text,
  moderated boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_reviews_target on public.reviews (target_type, target_id);

-- Notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  type text not null check (type in ('order','job','payment','promo','system')),
  title text,
  body text,
  data jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user on public.notifications (user_id, read_at);

drop trigger if exists notifications_set_updated_at on public.notifications;
create trigger notifications_set_updated_at before update on public.notifications for each row execute function public.set_updated_at();

-- Settlements (restaurant payouts)
create table if not exists public.settlements (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id),
  period_start date not null,
  period_end date not null,
  gross_amount bigint not null,
  commission_amount bigint not null,
  net_amount bigint not null,
  status text not null check (status in ('calculated','approved','paid','failed')) default 'calculated',
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_settlements_restaurant on public.settlements (restaurant_id);

-- Audit logs
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id),
  action text not null,
  entity_type text,
  entity_id uuid,
  payload jsonb,
  ip inet,
  created_at timestamptz not null default now()
);
create index if not exists idx_audit_actor on public.audit_logs (actor_id);

-- Driver profiles
create table if not exists public.driver_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) unique,
  vehicle_type text check (vehicle_type in ('motorcycle','car','other')),
  license_no text,
  bank_account_ref text,
  status text not null check (status in ('pending','approved','suspended')) default 'pending',
  rating_avg numeric(3,2) default 0,
  review_count integer default 0,
  accepted_jobs integer default 0,
  total_jobs integer default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_driver_profiles_user on public.driver_profiles (user_id);

drop trigger if exists driver_profiles_set_updated_at on public.driver_profiles;
create trigger driver_profiles_set_updated_at before update on public.driver_profiles for each row execute function public.set_updated_at();

-- Enable RLS
alter table public.promotions enable row level security;
alter table public.promo_redemptions enable row level security;
alter table public.favorites enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.settlements enable row level security;
alter table public.audit_logs enable row level security;
alter table public.driver_profiles enable row level security;

-- Policies (examples): promotions public read when active; redemptions server-only insert
create policy promotions_select_active on public.promotions for select using (status = 'active');
create policy promotions_insert_none on public.promotions for insert with check (false);

create policy promo_redemptions_select_user on public.promo_redemptions for select using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');
create policy promo_redemptions_insert_none on public.promo_redemptions for insert with check (false);

create policy favorites_select on public.favorites for select using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');
create policy favorites_insert_own on public.favorites for insert with check (user_id = auth.uid());
create policy favorites_delete_own on public.favorites for delete using (user_id = auth.uid());

create policy reviews_select on public.reviews for select using (true);
create policy reviews_insert_own on public.reviews for insert with check (author_id = auth.uid());
create policy reviews_update_admin on public.reviews for update using (auth.jwt() ->> 'role' = 'admin');

create policy notifications_select_user on public.notifications for select using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');
create policy notifications_insert_own on public.notifications for insert with check (user_id = auth.uid());
create policy notifications_update_own on public.notifications for update using (user_id = auth.uid());

create policy settlements_select_admin on public.settlements for select using (auth.jwt() ->> 'role' = 'admin');
create policy settlements_insert_none on public.settlements for insert with check (false);

create policy audit_logs_select_admin on public.audit_logs for select using (auth.jwt() ->> 'role' = 'admin');
create policy audit_logs_insert_none on public.audit_logs for insert with check (false);

create policy driver_profiles_select on public.driver_profiles for select using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');
create policy driver_profiles_insert_none on public.driver_profiles for insert with check (false);
create policy driver_profiles_update_owner on public.driver_profiles for update using (user_id = auth.uid() or auth.jwt() ->> 'role' = 'admin');

-- Realtime publications
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.reviews;

-- end migration
