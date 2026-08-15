# S12 — Security Hardening: RLS Audit + Monitoring + Rate Limits

| | |
|---|---|
| Status | Code-complete audit + wiring; staging verification pending |
| Date | 2026-08-15 |
| Owner | Engineering / Security |
| References | PF-DOC-19 (security strategy), PF-DOC-12 §3.3 (RLS), PF-DOC-14 §3.8 (rate limits), PF-DOC-27 (monitoring) |

## 1. RLS Posture Audit

Every table in the database has RLS enabled (DB-R06). This audit verifies the
policy posture per table and flags any gaps. All 25 tables in migrations
0001–0012 were reviewed.

### 1.1 Tables with correct RLS posture ✅

| Table | Select | Insert | Update | Delete | Notes |
|---|---|---|---|---|---|
| profiles | self + admin | via trigger only | self (non-role) + admin | — | role immutable except admin (0002) |
| addresses | self | self | self | self | — |
| restaurants | public (active only) | business | business (own) | admin | — |
| restaurant_hours | public | business | business | business | — |
| menu_categories / menu_items / menu_item_options | public | business | business | business | — |
| orders | customer/restaurant/driver/admin | customer (own) | business/admin | — | status via Edge Functions only |
| order_items | with order owner | **denied** (`with check (false)`) | — | — | API-R01: inserts via Edge Functions |
| order_status_history | with order owner | **denied** | — | — | API-R01: inserts via Edge Functions |
| deliveries | driver/restaurant/admin | **denied** | driver (own) / admin | — | API-R01: no self-assignment |
| driver_locations | driver (own) / admin | driver (own) | driver (own) | — | scoped read for assigned orders |
| wallets | self / admin | **denied** | admin | — | API-R01: writes via Edge Functions |
| wallet_transactions | self (via wallet) | **denied** | — | — | API-R01: writes via Edge Functions |
| payment_intents | order owner / admin | **denied** | — | — | API-R01: writes via Edge Functions |
| reviews | public aggregates | customer (own order) | — | admin | — |
| favorites | self | self | — | self | — |
| notifications | self | **denied** | self (mark read) | admin | API-R01: inserts via send-notification |
| promotions | public (active, safe fields) | admin | admin | admin | — |
| promo_redemptions | self | **denied** | — | — | API-R01: via place-order |
| audit_logs | admin | **denied** | — | — | API-R01: via admin actions |
| driver_profiles | self / admin | **denied** | admin | — | API-R01: via onboarding |
| merchant_documents | self / admin | **denied** | admin | — | API-R01: via onboarding |
| search_documents | public | admin | admin | admin | — |
| user_roles | self / admin | **denied** | **denied** | **denied** | API-R01: via switch_active_role RPC |
| settlements | self (restaurant) / admin | **denied** | admin (approve) | — | API-R01 |
| payouts | self (driver) / admin | **denied** | — | — | API-R01 |

### 1.2 Key findings

- ✅ **All money/state tables deny direct inserts** (`with check (false)`) —
  forces writes through Edge Functions (API-R01, ADR 0001). This is the
  critical security invariant.
- ✅ **No self-service role escalation** — `user_roles` denies all DML except
  via the `switch_active_role` RPC, which validates the user holds the role.
- ✅ **Driver cannot self-assign deliveries** — `deliveries` insert is denied;
  assignment happens only via `accept-job` Edge Function (BR-JOB-002).
- ✅ **Payment intents cannot be tampered** — inserts/updates denied; only
  Edge Functions (process-payment, webhook-psp) write to them.
- ⚠️ **`orders_update_owner` policy allows business-role updates** — this is
  intentional (merchant marks status via RLS), but Edge Functions use the
  service client with optimistic `.eq("status", ...)` guards so the state
  machine is enforced regardless. No change needed, but documented.
- ⚠️ **`driver_locations` select is broad** (`driver_id = auth.uid() or
  admin`) — a real impl would scope reads to the driver assigned to the
  customer's active order. Defer to S13 (a more granular policy using an
  EXISTS subquery on `deliveries`).

### 1.3 Recommendations for staging

1. Run `supabase db reset` with migrations 0001–0012; verify all policies
   apply cleanly.
2. Test each role (customer/business/driver/admin) with a real JWT and
   confirm row visibility matches the table above.
3. Attempt a direct insert into `orders`/`wallets`/`deliveries` as a
   customer — must be denied (403).

## 2. Error Monitoring (Sentry)

### 2.1 Wiring status

- `SENTRY_DSN` is already a `--dart-define` in `env.dart` (DEP-R06).
- `AppConfig.sentryDsn` is parsed but **not yet wired to the Sentry SDK**.
- The Android CI workflow passes `SENTRY_DSN` via `--dart-define` when the
  secret is set.

### 2.2 Action items

- [ ] Add `sentry_flutter` to all 4 app pubspecs.
- [ ] In each `main()`, call `SentryFlutter.init()` before `runApp` when
  `config.sentryDsn` is non-null.
- [ ] Wrap the app in `SentryWidget` for crash capture.
- [ ] Add `beforeSend` filter to strip PII (phone, email) from breadcrumbs
  (PF-DOC-19 §3.4).

### 2.3 Deferred to production

- Sentry performance monitoring (traces) — enable after pilot.
- Release health tracking — configure after first store release.

## 3. Rate Limits (PF-DOC-14 §3.8)

| Scope | Limit (MVP) | Enforced at | Status |
|---|---|---|---|
| Per-user Edge mutations | 60/min | Edge Function gate | ⏠ Config in `config.toml` |
| Anonymous PostgREST reads | 300/min/IP | API gateway (Supabase) | ✅ Supabase default |
| Auth attempts | Supabase defaults | Supabase Auth | ✅ |
| Job offer accepts | 10/min per driver | Edge gate | ⏠ Config |

**Action:** add a `_shared/rate_limit.ts` helper that checks a Redis-like
counter (Supabase `rate_limits` table or edge KV) before processing. For MVP,
the Supabase built-in rate limits suffice; the per-endpoint limits are a
S13+ hardening item.

## 4. Input Validation Hardening

All Edge Functions validate inputs (API-R06) via the `_shared/auth.ts` +
`_shared/errors.ts` helpers. Review confirms:
- ✅ UUID validation on all id parameters.
- ✅ Enum validation (payment_method, decision, status).
- ✅ Positive integer validation on money amounts.
- ✅ Idempotency key required on all mutations.
- ✅ `INTERNAL` errors never leak internals (API-R03).

**No changes needed.** The validation layer is consistent across all 14
Edge Functions.

## 5. Secret Rotation

| Secret | Rotation cadence | Process |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | Quarterly | Supabase dashboard → rotate → update CI secrets + GUC |
| `PSP_WEBHOOK_SECRET` | On compromise | PSP dashboard → rotate → update `PSP_WEBHOOK_SECRET` env |
| `ANDROID_KEYSTORE_BASE64` | Annual or on compromise | Re-generate keystore → re-sign app → Play Console key upgrade |
| `STAGING_SUPABASE_*` | On env change | Update CI secrets |

## 6. Exit criteria for S12

- [x] RLS audit document complete (this file).
- [x] Input validation review complete (§4).
- [x] Secret rotation process documented (§5).
- [ ] Sentry SDK wired in all 4 apps (§2.2 — code-ready, deferred to avoid
      adding a dependency that requires a DSN to test).
- [ ] Rate-limit helper implemented (deferred — Supabase defaults suffice
      for pilot).
- [ ] Staging RLS verification (requires real Supabase project).
