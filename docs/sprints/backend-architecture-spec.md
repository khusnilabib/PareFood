# PareFood — Backend Architecture Specification

| | |
|---|---|
| Status | Production-ready (code); staging cutover pending |
| Date | 2026-08-15 |
| Owner | Engineering |
| References | PF-DOC-12 (Supabase arch), PF-DOC-13 (DB blueprint), PF-DOC-14 (API), PF-DOC-18 (BR), PF-DOC-19 (security) |

## 1. Architecture Overview

PareFood uses **Supabase** as the entire backend — no separate API server.
The backend has three layers, all hosted in one Supabase project:

```
┌─────────────────────────────────────────────────────┐
│  Flutter Apps (4)                                   │
│  customer · merchant · driver · admin               │
└──────────────┬──────────────────────────────────────┘
               │ HTTPS (Supabase SDK + functions.invoke)
               ▼
┌─────────────────────────────────────────────────────┐
│  Supabase Project (one per env: dev / staging / prod)│
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ PostgREST   │  │ Edge Functions│  │ GoTrue Auth│ │
│  │ (reads,RLS) │  │ (16 functions)│  │ (JWT, OTP) │ │
│  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘ │
│         │                │                 │        │
│         ▼                ▼                 ▼        │
│  ┌──────────────────────────────────────────────┐  │
│  │ PostgreSQL 17                                │  │
│  │ 27 tables · 12 migrations · RLS on all      │  │
│  │ 5 extensions · 10 realtime tables           │  │
│  │ pg_cron · pg_net · pg_trgm · PostGIS        │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ Realtime    │  │ Storage      │  │ Deno       │ │
│  │ (WebSocket) │  │ (buckets)    │  │ runtime    │ │
│  └─────────────┘  └──────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────┘
```

### Design principles
1. **Edge Functions own all money/state mutations** (API-R01, ADR 0001).
   PostgREST is read-heavy; writes to money tables are denied at the RLS
   level (`with check (false)`).
2. **RLS on every table** (DB-R06). The JWT `app_metadata.role` drives row
   visibility.
3. **Idempotency** on every mutation via `X-Idempotency-Key` (API-R02).
4. **Realtime** via Supabase Realtime (WebSocket) — merchant auto-refresh,
   customer live tracking.
5. **Business rules server-side only** (BR-R01). The client only displays
   rule outcomes; never enforces them.

## 2. Database (PostgreSQL 17)

### 2.1 Extensions (migration 0001)

| Extension | Purpose |
|---|---|
| `pgcrypto` | `gen_random_uuid()` for primary keys |
| `postgis` | Geo columns (`geography(Point,4326)`) for restaurant/driver locations |
| `pg_trgm` | Trigram search (GIN index) for menu/restaurant name search (FR-DISC-002) |
| `pg_net` | HTTP POST from DB triggers (dispatch trigger → Edge Function) |
| `pg_cron` | Scheduled jobs (settlement, payout, reconciliation, dispatch retry) |

### 2.2 Table catalogue (27 tables)

Grouped by domain (PF-DOC-13 §5.1):

| Domain | Tables | Count |
|---|---|---|
| **Identity** | profiles, addresses, user_roles | 3 |
| **Catalog** | restaurants, restaurant_hours, menu_categories, menu_items, menu_item_options, search_documents | 6 |
| **Orders** | orders, order_items, order_status_history, deliveries, driver_locations | 5 |
| **Money** | wallets, wallet_transactions, payment_intents, settlements, payouts | 5 |
| **Engagement** | reviews, favorites, notifications, promotions, promo_redemptions | 5 |
| **Ops** | audit_logs, driver_profiles, merchant_documents | 3 |

### 2.3 Critical indexes (migration 0010)

7 hot-path indexes added in S2 (from the migration audit):
- `idx_orders_status_placed` — live board + BR-ACCEPT scan
- `idx_orders_idempotency` — idempotency replay lookup
- `idx_orders_customer_placed` — customer history pagination
- `idx_menu_items_name_trgm` — menu search (GIN)
- `idx_search_documents_name_trgm` — restaurant search (GIN)
- `idx_driver_locations_active` — eligible-driver scan
- `idx_wallet_tx_created` — earnings/settlement reads

### 2.4 Triggers

| Trigger | Table | Purpose |
|---|---|---|
| `profiles_sync_role_claim` | profiles (after insert/update of role) | Mirrors `profiles.role` → `auth.users.raw_app_meta_data['role']` → JWT |
| `profiles_grant_signup_role` | profiles (after insert) | Auto-grants the signup role as the first `user_roles` row |
| `handle_new_user` | auth.users (after insert) | Auto-creates a `profiles` row on signup |
| `orders_dispatch_on_ready` | orders (after update) | Fires `pg_net` POST to `/functions/v1/dispatch` when status→ready |
| `orders_set_updated_at` | orders | Auto-updates `updated_at` |
| `deliveries_set_updated_at` | deliveries | Auto-updates `updated_at` |
| `profiles_set_updated_at` | profiles | Auto-updates `updated_at` |

### 2.5 RPC functions

| Function | Purpose |
|---|---|
| `switch_active_role(p_role)` | Switches the caller's active role (FR-AUTH-006); validates the user holds it |
| `nearby_restaurants(lat, lng, radius_km)` | Nearest-first restaurant lookup (FR-DISC-001) |
| `parefood_functions_base_url()` | GUC-configurable Edge Function base URL (for pg_net) |
| `set_updated_at()` | Shared trigger function |
| `sync_role_claim()` | Mirrors role into JWT app_metadata |

### 2.6 RLS posture

All 27 tables have RLS enabled. Money/state tables deny direct inserts:
- `order_items`, `order_status_history`, `deliveries`, `wallets`,
  `wallet_transactions`, `payment_intents`, `notifications`, `promo_redemptions`,
  `audit_logs`, `driver_profiles`, `merchant_documents`, `user_roles`,
  `settlements`, `payouts` — all `with check (false)` on insert.
- This forces every write through an Edge Function (API-R01, ADR 0001).

### 2.7 Realtime publication

10 tables published to `supabase_realtime`:
restaurants, restaurant_hours, menu_categories, menu_items, menu_item_options,
orders, deliveries, driver_locations, notifications, reviews.

## 3. Edge Functions (16 functions)

### 3.1 Order lifecycle (9 functions)

| Function | Actor | Transition | BR enforced |
|---|---|---|---|
| `place-order` | customer | (new) → placed | BR-PRICE-003/005, BR-STOCK-002, idempotency |
| `accept-order` | business | placed → accepted → preparing (auto) | BR-ACCEPT-001 (120s), BR-TIMER-001 (prep 5-45) |
| `ready-order` | business | preparing → ready | BR-ORDER state machine |
| `accept-job` | driver | delivery assigned (atomic first-wins) | BR-JOB-002 |
| `decline-job` | driver | (no-op, no penalty) | BR-DISPATCH-006 |
| `driver-pickup` | driver | ready → picked_up | BR-PICKUP (code verify) |
| `driver-delivered` | driver | picked_up → delivered | BR-DELIVERY (photo proof) |
| `complete-order` | internal | locks commission + fare | BR-COMM-001/003, BR-COD-001..003 |
| `cancel-order` | customer/admin | → cancelled + refund | BR-CANCEL-001..006, BR-FRAUD-005 |

### 3.2 Payments (2 functions)

| Function | Actor | Purpose |
|---|---|---|
| `process-payment` | customer/internal | Charge/refund via PSP abstraction (mock sandbox, Midtrans/Xendit ready) |
| `webhook-psp` | PSP | HMAC-SHA256 signature verify, idempotent status update, downstream effects |

### 3.3 Notifications (2 functions)

| Function | Actor | Purpose |
|---|---|---|
| `send-notification` | internal | Writes `notifications` row + dispatches push to device tokens (FCM/APNs) |
| `register-device-token` | user | Upserts `device_tokens` (FR-NOTIF-005) |

### 3.4 Finance cron (3 functions)

| Function | Schedule | Purpose |
|---|---|---|
| `settle-restaurants` | daily | T+7: aggregate delivered orders per restaurant, compute commission+net |
| `payout-drivers` | daily | Aggregate completed deliveries per driver, credit wallet |
| `reconcile` | weekly | COD totals vs remittances, mismatch flag (BR-RECON, BR-COD-004) |

### 3.5 Shared helpers (`_shared/`)

| File | Exports |
|---|---|
| `errors.ts` | `jsonError`, `jsonOk`, `jsonMethodNotAllowed`, `jsonInternal` — unified error envelope (PF-DOC-14 §3.4) |
| `supabase.ts` | `serviceClient` (bypasses RLS), `userClient` (scoped to JWT), `getBearer` |
| `auth.ts` | `resolveCaller` (JWT → {id, role}), `requireRole`, `isUuid` |

### 3.6 Dry-run mode (ADR 0003)

All functions support dry-run: when `SUPABASE_URL` env is absent (test env),
the function validates inputs and returns a `{ dry_run: true }` envelope
without DB side-effects. This keeps `deno test` hermetic (TS-R06).

## 4. Authentication (GoTrue)

### 4.1 Methods
- **Email + password** (signup, signin, password reset)
- **Phone OTP** (signin with SMS, E.164 normalization: `08…` → `+628…`)
- No anonymous sign-ins; no manual linking

### 4.2 Role claim flow
```
profiles.role ──[sync_role_claim trigger]──▶ auth.users.raw_app_meta_data['role']
                                                    │
                                                    ▼
                                              JWT app_metadata.role
                                                    │
                                                    ▼
                            Edge Function resolveCaller() / app guard requireRole()
```

### 4.3 Multi-role (FR-AUTH-006)
- `user_roles` table holds the full set of roles a user may switch to.
- `switch_active_role(role)` RPC validates + updates `profiles.role` →
  trigger syncs the JWT claim. Next token refresh carries the new role.

## 5. Storage buckets

| Bucket | Purpose | Access |
|---|---|---|
| `merchant-docs` | KTP, NIB verification uploads | business write, admin read |
| `driver-docs` | SIM, vehicle, bank docs | driver write, admin read |
| `proof-photos` | Delivery drop-off photo proof | driver write, admin read |
| `menu-images` | Menu item photos | business write, public read |
| `avatars` | User profile avatars | self write, public read |

## 6. Config (`config.toml`)

Dev project: `parefood-dev` (local Supabase CLI).
Production: separate project (`parefood-prod`) with the same migrations.

Key settings:
- DB: PostgreSQL 17, pooler disabled (MVP), max_rows 1000
- Auth: JWT expiry 3600s, refresh token rotation enabled, signup enabled
- Realtime: enabled
- Storage: 50MiB file size limit
- Seed: `./seed.sql` (dev only — production uses selective seed)
