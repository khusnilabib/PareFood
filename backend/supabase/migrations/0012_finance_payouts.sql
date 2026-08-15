-- 0012_finance_payouts.sql
-- Sprint 11 (PF-DOC-13 §5.1 payouts, BR-PAYOUT-001).
--
-- Driver payouts table — daily aggregated earnings credited to the driver
-- wallet. Created by the payout-drivers Edge Function (cron) from completed
-- deliveries. The `wallet_transactions` table (migration 0007) holds the
-- individual credit rows; this table is the finance-level aggregation for
-- reporting and reconciliation.

create table if not exists public.payouts (
  id              uuid primary key default gen_random_uuid(),
  driver_id       uuid not null references public.profiles (id) on delete cascade,
  period_date     date not null,
  amount          bigint not null,
  delivery_count  integer not null default 0,
  status          text not null check (status in ('pending','completed','failed')) default 'pending',
  bank_account_ref text,
  wallet_tx_id    uuid references public.wallet_transactions (id),
  created_at      timestamptz not null default now(),
  unique (driver_id, period_date)
);

create index if not exists idx_payouts_driver on public.payouts (driver_id);
create index if not exists idx_payouts_period on public.payouts (period_date desc);
create index if not exists idx_payouts_status on public.payouts (status);

-- RLS: driver sees own payouts; admin all.
alter table public.payouts enable row level security;

create policy payouts_select_self on public.payouts
  for select using (
    driver_id = auth.uid()
    or auth.jwt() ->> 'role' = 'admin'
  );

create policy payouts_insert_none on public.payouts
  for insert with check (false);

create policy payouts_update_none on public.payouts
  for update with check (false);

-- end migration
