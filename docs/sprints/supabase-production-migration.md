# PareFood — Supabase Production Migration Guide

| | |
|---|---|
| Status | Step-by-step runbook — ready to execute |
| Date | 2026-08-15 |
| Owner | DevOps |
| References | PF-DOC-22 (deployment), sprint-14-launch-prep.md, backend-architecture-spec.md |

This is the **exact sequence** to migrate the PareFood backend from local dev
to a production Supabase project. Follow each step in order; do not skip.

## Prerequisites

- [ ] Supabase CLI installed: `npm install -g supabase` (v2.x)
- [ ] Supabase account + a new **production project** created (region:
      Singapore `ap-southeast-1` — closest to Indonesia)
- [ ] Project ref + database password saved
- [ ] Supabase Access Token (Dashboard → Account → Access Tokens)
- [ ] PSP account (Midtrans/Xendit) with production keys
- [ ] Domain configured: `api.parefood.co` → Supabase project (optional,
      can use the default `xxx.supabase.co` URL for pilot)

## Phase 1 — Link & push schema

### 1.1 Link the production project

```sh
cd backend/supabase

# Login (one-time)
supabase login

# Link to the production project (enter the project ref when prompted)
supabase link --project-ref <PROD_PROJECT_REF>
```

### 1.2 Push all 12 migrations

```sh
# Dry-run first (shows what will be applied)
supabase db push --dry-run

# Push for real
supabase db push
```

This applies migrations 0001–0012 in order:
- Extensions (pgcrypto, postgis, pg_trgm, pg_net, pg_cron)
- 27 tables with RLS + policies
- 7 hot indexes
- Triggers (role sync, dispatch, auto-profile)
- RPC functions (switch_active_role, nearby_restaurants)

### 1.3 Verify schema

```sh
# Open the SQL editor on the production project and run:
select count(*) from information_schema.tables where table_schema = 'public';
-- Expected: 27

select tablename, rowsecurity from pg_tables where schemaname = 'public';
-- Every table should have rowsecurity = true
```

## Phase 2 — Configure Auth

### 2.1 Dashboard → Authentication → Providers

- **Email**: enabled, confirmations ON (double opt-in for pilot)
- **Phone**: enabled, OTP via SMS (configure Twilio or Supabase built-in)
- **Anonymous**: disabled

### 2.2 Dashboard → Authentication → URL Configuration

- **Site URL**: `https://parefood.co` (or your app deep link)
- **Redirect URLs**: 
  - `https://parefood.co/auth/callback`
  - `parefood://auth/callback` (mobile deep link)

### 2.3 Auth templates (Bahasa Indonesia)

Dashboard → Authentication → Email Templates → customize all to Indonesian:
- Confirm signup
- Reset password
- Magic link
- Change email
- OTP (SMS)

## Phase 3 — Deploy Edge Functions

### 3.1 Set secrets

```sh
# Database GUCs (for the dispatch trigger's pg_net calls)
supabase db execute --sql "
  alter database postgres set app.parefood_functions_base_url to 'https://<PROD_PROJECT_REF>.supabase.co';
"

# Edge Function env secrets
supabase secrets set SUPABASE_URL=https://<PROD_PROJECT_REF>.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
supabase secrets set SUPABASE_ANON_KEY=<anon_key>
supabase secrets set PSP_PROVIDER=midtrans  # or xendit
supabase secrets set PSP_WEBHOOK_SECRET=<psp_webhook_secret>
supabase secrets set SENTRY_DSN=<sentry_dsn>  # optional
```

### 3.2 Deploy all 16 functions

```sh
# Deploy each function (or use the deploy-all script below)
for fn in place-order accept-order ready-order accept-job decline-job \
          driver-pickup driver-delivered complete-order cancel-order \
          process-payment webhook-psp send-notification register-device-token \
          settle-restaurants payout-drivers reconcile dispatch; do
  echo "Deploying $fn..."
  supabase functions deploy "$fn" --no-verify-jwt
done
```

Or use the deploy script:
```sh
chmod +x backend/supabase/scripts/deploy-production.sh
./backend/supabase/scripts/deploy-production.sh
```

### 3.3 Verify deployment

```sh
# List deployed functions
supabase functions list

# Test one (dry-run — should return 200 with dry_run: true)
curl -X POST https://<PROD_PROJECT_REF>.supabase.co/functions/v1/place-order \
  -H "Content-Type: application/json" \
  -H "x-idempotency-key: test-123" \
  -d '{"restaurant_id":"00000000-0000-0000-0000-000000000002","delivery_address":"test","payment_method":"cod","items":[{"name":"Test","unit_price":20000,"quantity":1}]}'
```

## Phase 4 — Configure pg_cron jobs

Run these in the Supabase SQL editor (production project):

```sql
-- Enable the pg_cron extension (if not already)
create extension if not exists pg_cron with schema extensions;

-- Daily settlement (2:00 AM Asia/Jakarta = 19:00 UTC previous day)
select cron.schedule(
  'settle-restaurants-daily',
  '0 19 * * *',
  $$
    select net.http_post(
      url := public.parefood_functions_base_url() || '/functions/v1/settle-restaurants',
      headers := jsonb_build_object('Content-Type','application/json','X-Idempotency-Key','settle-' || now()::date),
      body := jsonb_build_object('period_days', 7)
    );
  $$
);

-- Daily driver payout (3:00 AM Asia/Jakarta = 20:00 UTC previous day)
select cron.schedule(
  'payout-drivers-daily',
  '0 20 * * *',
  $$
    select net.http_post(
      url := public.parefood_functions_base_url() || '/functions/v1/payout-drivers',
      headers := jsonb_build_object('Content-Type','application/json','X-Idempotency-Key','payout-' || now()::date),
      body := jsonb_build_object()
    );
  $$
);

-- Weekly reconciliation (Monday 4:00 AM Asia/Jakarta = Sunday 21:00 UTC)
select cron.schedule(
  'reconcile-weekly',
  '0 21 * * 0',
  $$
    select net.http_post(
      url := public.parefood_functions_base_url() || '/functions/v1/reconcile',
      headers := jsonb_build_object('Content-Type','application/json','X-Idempotency-Key','reconcile-' || now()::date),
      body := jsonb_build_object()
    );
  $$
);

-- Dispatch retry (every 2 min, re-fire for orders stuck in 'ready' with no delivery)
select cron.schedule(
  'retry-dispatch',
  '*/2 * * * *',
  $$
    select net.http_post(
      url := public.parefood_functions_base_url() || '/functions/v1/dispatch',
      headers := jsonb_build_object('Content-Type','application/json'),
      body := (select jsonb_agg(jsonb_build_object('order_id', o.id))
               from public.orders o
               where o.status = 'ready'
                 and not exists (select 1 from public.deliveries d where d.order_id = o.id)
               limit 50)
    );
  $$
);
```

## Phase 5 — Storage buckets

Run in the Supabase SQL editor:

```sql
-- Create buckets (if not created by migration 0006)
insert into storage.buckets (id, name, public) values
  ('merchant-docs', 'merchant-docs', false),
  ('driver-docs', 'driver-docs', false),
  ('proof-photos', 'proof-photos', false),
  ('menu-images', 'menu-images', true),
  ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- RLS policies for each bucket
create policy "merchant-docs business upload" on storage.objects
  for insert with check (bucket_id = 'merchant-docs' and auth.jwt() ->> 'role' = 'business');
create policy "merchant-docs admin read" on storage.objects
  for select using (bucket_id = 'merchant-docs' and auth.jwt() ->> 'role' = 'admin');

create policy "driver-docs driver upload" on storage.objects
  for insert with check (bucket_id = 'driver-docs' and auth.jwt() ->> 'role' = 'driver');
create policy "driver-docs admin read" on storage.objects
  for select using (bucket_id = 'driver-docs' and auth.jwt() ->> 'role' = 'admin');

create policy "proof-photos driver upload" on storage.objects
  for insert with check (bucket_id = 'proof-photos' and auth.jwt() ->> 'role' = 'driver');
create policy "proof-photos admin read" on storage.objects
  for select using (bucket_id = 'proof-photos' and auth.jwt() ->> 'role' = 'admin');

create policy "menu-images business upload" on storage.objects
  for insert with check (bucket_id = 'menu-images' and auth.jwt() ->> 'role' = 'business');
create policy "menu-images public read" on storage.objects
  for select using (bucket_id = 'menu-images');

create policy "avatars self upload" on storage.objects
  for insert with check (bucket_id = 'avatars' and auth.uid() = (storage.foldername(name))[1]::uuid);
create policy "avatars public read" on storage.objects
  for select using (bucket_id = 'avatars');
```

## Phase 6 — Seed pilot data

Run `backend/supabase/scripts/seed-pilot.sql` in the SQL editor to create
the first admin account + a few test merchants (see script).

## Phase 7 — Update app config

Set these as GitHub Actions secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `PROD_SUPABASE_URL` | `https://<PROD_PROJECT_REF>.supabase.co` |
| `PROD_SUPABASE_ANON_KEY` | `<anon_key>` |
| `SUPABASE_ACCESS_TOKEN` | `<supabase_access_token>` (for CI db push) |
| `SENTRY_DSN` | `<sentry_dsn>` |
| `PSP_WEBHOOK_SECRET` | `<psp_webhook_secret>` |
| `ANDROID_KEYSTORE_BASE64` | `<base64_keystore>` |
| `ANDROID_STORE_PASSWORD` | `<keystore_password>` |
| `ANDROID_KEY_PASSWORD` | `<key_password>` |
| `ANDROID_KEY_ALIAS` | `<key_alias>` |

Update `apps/*/lib/src/config/env.dart` to read these via `--dart-define` in
the CI build.

## Phase 8 — PSP webhook configuration

### 8.1 Midtrans
- Dashboard → Settings → Configuration → Payment Notification URL:
  `https://<PROD_PROJECT_REF>.supabase.co/functions/v1/webhook-psp`
- Set `PSP_WEBHOOK_SECRET` to the Midtrans server key (used for signature).

### 8.2 Xendit (alternative)
- Dashboard → Settings → Callbacks → Add URL:
  `https://<PROD_PROJECT_REF>.supabase.co/functions/v1/webhook-psp`
- Set `PSP_WEBHOOK_SECRET` to the Xendit webhook verification token.

## Phase 9 — Final verification

```sh
# 1. All 16 Edge Functions deployed
supabase functions list

# 2. All cron jobs scheduled
select jobname, schedule, active from cron.job;

# 3. All tables have RLS
select count(*) from pg_tables where schemaname = 'public' and rowsecurity = true;
-- Expected: 27

# 4. Dispatch trigger exists
select tgname from pg_trigger where tgname = 'orders_dispatch_on_ready';

# 5. Test auth flow (signup → login → JWT has role)
# Do this via the app or curl.

# 6. Test a full order lifecycle (place → accept → ready → pickup → deliver)
# Use the PareFood customer app against production.
```

## Rollback

**Never rollback a migration** — it loses data. Instead:
1. Write a forward-fix migration (e.g., `0013_fix_…sql`) that corrects the issue.
2. `supabase db push` applies it.
3. If an Edge Function is broken, `supabase functions deploy <fn>` with the
   previous version (git revert + redeploy).
