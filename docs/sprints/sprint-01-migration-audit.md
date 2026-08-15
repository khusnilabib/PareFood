# Sprint 01 — Migration Audit vs PF-DOC-13

| | |
|---|---|
| Status | Audit complete — gaps recorded for Sprint 2 |
| Date | 2026-08-15 |
| Auditor | Engineering |
| References | PF-DOC-13 §3.2 (table catalogue), §5.1 (inventory, "31 tables"), §5.2 (critical indexes), DB-R06 (RLS on every table); sprint-01-todos task 5 |

## 1. Purpose

Close sprint-01-todos task 5 ("Finalize DB migrations — review for completeness vs
PF-DOC-13") by recording exactly which tables, indexes and RLS postures are present
and which are still missing, so Sprint 2 (S2 — Schema + Auth) has a precise backlog.

## 2. Method

Grepped all `create table` statements across `backend/supabase/migrations/0001..0008`
and diffed against the PF-DOC-13 §5.1 table inventory (30 distinct tables; the doc's
"31" counts `carts` and `cart_items` as a single inventory row). Critical indexes
were diffed against PF-DOC-13 §5.2. RLS posture was checked per table (DB-R06).

## 3. Table coverage

### Present (25 tables)

profiles, addresses, restaurants, restaurant_hours, menu_categories, menu_items,
menu_item_options, orders, order_items, order_status_history, deliveries,
driver_locations, wallets, wallet_transactions, settlements, payment_intents,
reviews, favorites, notifications, promotions, promo_redemptions, audit_logs,
driver_profiles, merchant_documents, search_documents.

### Missing (5 tables) — backlog for S2/S4

| Table | PF-DOC-13 purpose | Owning sprint | Notes |
|---|---|---|---|
| `carts` | active customer cart | S4 (Discovery+Cart) | FR-CART-001 depends on it; `place-order` reads from it |
| `cart_items` | cart line items + option groups | S4 | with `cart_id` FK |
| `device_tokens` | push registration | S6 (Tracking/Notif) | FR-NOTIF-005; `register-device-token` function writes here |
| `driver_documents` | driver onboarding docs (SIM, vehicle, bank) | S8 (Driver) | FR-ONB-003/005; per-document status |
| `user_roles` | multi-role accounts | post-MVP (PF-DOC-13 marks it) | FR-AUTH-006; not blocking MVP |

> `carts`/`cart_items` are the only MVP-blocking gap, and they are intentionally
> deferred to S4 per the sprint roadmap (PF-DOC-25 §3.3). No action needed in S1.

## 4. Critical index coverage (PF-DOC-13 §5.2)

| Index | Status | Migration |
|---|---|---|
| `idx_restaurants_geo` | ✅ present | 0003 |
| `idx_orders_status_placed` (status, placed_at) | ❌ **missing** | — live order board + BR-ACCEPT scan |
| `idx_orders_idempotency` (idempotency_key) | ❌ **missing** | — API-R02 idempotency lookup |
| `idx_orders_customer_placed` (customer_id, placed_at) | ❌ **missing** | — order history pagination |
| `idx_menu_search` (name GIN pg_trgm) | ❌ **missing** | — FR-DISC-002 sub-second search (NFR-004) |
| `idx_search_name` | ❌ **missing** | — search_documents |
| `idx_driver_loc_active` | ❌ **missing** | — BR-DISPATCH-002 eligible-driver scan |
| `idx_wallet_tx_created` (wallet_id, created_at) | ❌ **missing** | — earnings/settlement reads |

The basic single-column indexes (`idx_orders_customer`, `idx_orders_restaurant`,
`idx_orders_driver`) exist (0007) but the composite hot-path indexes above do not.
**Action:** add a migration `0010_hot_indexes.sql` in S2 before any load test
(NFR-003/004). The missing `idx_orders_status_placed` directly affects the
BR-ACCEPT-001 120s scan that `accept-order` relies on at scale.

## 5. RLS posture (DB-R06)

All 25 created tables have `enable row level security` and at least one policy.
✅ Compliant with DB-R06. The `order_status_history`, `order_items`,
`deliveries`, `wallets`, `wallet_transactions`, `payment_intents` tables correctly
deny direct inserts (`with check (false)`), forcing writes through Edge Functions
(API-R01, ADR 0001).

## 6. Dispatch trigger (new in this audit cycle)

Migration `0009_dispatch_trigger.sql` (added with `accept-order`/`ready-order`)
introduces the `orders_dispatch_on_ready` trigger required by PF-DOC-14 §3.3.
This closes a previously-undocumented gap (the dispatch trigger was specified in
the API doc but not implemented). See ADR 0002.

## 7. Recommendations for S2

1. Add `0010_hot_indexes.sql` with the 7 missing critical indexes (§4).
2. Confirm `pg_net` + `pg_cron` are enabled on the staging project (they are in
   0001 locally; staging may differ).
3. Set the `app.parefood_functions_base_url` and `app.supabase_service_role_key`
   GUCs on staging so the dispatch trigger can call the function (ADR 0002).
4. Defer `carts`/`cart_items`/`device_tokens`/`driver_documents` to their owning
   sprints (S4/S6/S8) — no S1 action.
