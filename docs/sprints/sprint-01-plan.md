# Sprint 1 Plan — Authentication, Users, Merchant, Products

| | |
|---|---|
| Artifact ID | PF-SPRINT-01 |
| Title | Sprint 1 — Authentication, Users, Merchant, Products |
| Status | Draft (awaiting review) |
| Date | 2026-08-06 |
| Author | Principal Architect / Delivery |
| Roadmap | Phase 4 sprint order (user-confirmed); supersedes PF-DOC-25 §3.3 sprint numbering for implementation sequence |
| References | PF-DOC-07 (FRs), PF-DOC-10 (monorepo), PF-DOC-11 (Flutter arch), PF-DOC-12 (Supabase), PF-DOC-13 (DB), PF-DOC-14 (API), PF-DOC-18 (BR), PF-DOC-19 (security), PF-DOC-20 (testing), PF-DOC-25 (capacity), PF-DOC-30 (DoD) |

---

## 1. Sprint Goal

Make identity + catalog the foundation for all four apps: users can create an
account (email/password + phone OTP) and a profile, merchants can onboard a
restaurant and manage its menu, and customers can browse approved restaurants
and their products (read-side only). Every piece ships full-stack: migration +
RLS + data-layer repository + feature UI + tests.

Scope decisions (confirmed with PO):
- Discovery ships **read-side only** in Sprint 1 (restaurant list, detail, menu
  read). Search/filters/recommendations/favourites/reorder stay later.
- Every FR is implemented **full-stack per sprint** (DB + API + data + UI).

## 2. Requirements

### 2.1 FRs in scope

| FR | Prio | App | Requirement |
|---|---|---|---|
| FR-AUTH-001 | M | PF/PB/PD | Phone OTP + email/password registration & login (Supabase Auth) |
| FR-AUTH-002 | M | PF/PB/PD | Profile creation: name, phone, avatar, default role assignment |
| FR-AUTH-003 | M | PA | Admin login with role-based access |
| FR-AUTH-004 | M | PF/PB/PD | Secure logout & session revocation |
| FR-AUTH-005 | S | PF/PB/PD | Password reset via email; phone change with re-verification |
| FR-ONB-001 | M | PB | Merchant onboarding wizard: business info, address, KTP/NIB docs |
| FR-ONB-002 | M | PB | Verification status tracking (pending/reviewed/approved/rejected) |
| FR-MENU-001 | M | PB | Menu CRUD: categories, items, price, image, availability |
| FR-MENU-002 | M | PB | Item out-of-stock toggle |
| FR-MENU-003 | S | PB | Bulk menu import (CSV) |
| FR-DISC-001 | M | PF | Location-based restaurant list (read-side) |
| FR-DISC-004 | M | PF | Restaurant detail: menu, prices, images, hours, rating, ETA (read-side) |

### 2.2 Deferred (explicitly NOT this sprint)

- FR-AUTH-006 multi-role / `user_roles` activation (post-MVP, design-locked
  table exists).
- FR-DISC-002/003/005/006/007/008 (search, filters, ETA preview, favourites,
  recommendations, reorder).
- Addresses CRUD UI (table + RLS ship; checkout-time address UI is Sprint 2).
- Ratings (RATE), admin verification UI (ADMIN) — status fields exist, admin
  console is Sprint 4.

### 2.3 BRs engaged

BR-HOURS-001/002 (hours gate), BR-STOCK-001/002 (availability gate on list/detail
read), BR-PRICE-001..005 (price snapshot validation at add-to-cart — cart is S2,
but menu writes must validate price ≥ 0 and availability semantics now).

### 2.4 NFRs engaged

NFR-003 (nearest-first via PostGIS), NFR-004 (search index — table ships, search
UI later), NFR-009 (session persistence), NFR-014 (realtime fallback polling),
NFR-021 (idempotency on mutations), NFR-022..026 (auth/RLS/audit), NFR-037
(coverage gate).

## 3. Architecture

### 3.1 Backend channels (PF-DOC-12/14)

| Channel | Sprint 1 usage |
|---|---|
| Supabase Auth | email/password, phone OTP, session persistence, admin MFA config |
| PostgREST (RLS) | reads: restaurants (active), menu_*, hours, profiles(self); benign writes: profile, addresses, menu owner writes |
| Edge Functions | **None required in Sprint 1** — no money/order-state mutation. Document upload via Storage directly (bucket RLS). |
| Storage | buckets `product-images` (public read / business write), `merchant-docs` (owner+admin), `avatars` (owner) |
| Realtime | `menu_*` + `restaurants` row-level changes for AP-PF list/detail propagation (FR-MENU-001 ≤30s) |
| DB triggers | `updated_at`, `profiles` auto-create on `auth.users` insert (role claim), `search_documents` maintain, restaurants status index |

### 3.2 RLS posture (PF-DOC-19 §3.3)

- `profiles`: read/update self (non-role fields); admin all.
- `addresses`: own CRUD.
- `restaurants`: read active; business owner read/write own; admin all.
- `menu_categories`/`menu_items`/`menu_item_options`: read available; owner
  read/write own; admin all.
- `restaurant_hours`: read; owner read/write own.
- `merchant_documents`: owner; admin all.
- `search_documents`: public read (is_available=true).
- Storage buckets per §3.4 of PF-DOC-12.

### 3.3 Client (PF-DOC-11 FL-R04)

Feature packages define abstract repo contracts + Riverpod providers (already
scaffolded for auth/profile). Sprint 1 adds concrete `data`-layer
implementations backed by Supabase and wires them via composition-root
overrides. New feature packages: `merchant_feature`, `menu_feature` (AP-PB),
`discovery_feature` (AP-PF read-side). Cart/orders/payments/notifications remain
scaffolded contracts.

## 4. Tasks

### Backend (migrations — PF-DOC-13 §3.2, tables in scope)

| # | Task | SP |
|---|---|---|
| B1 | Migration `0001_extensions`: enable `pgcrypto`, `postgis`, `pg_trgm`, `pg_net`, `pg_cron`; `updated_at` trigger function | 2 |
| B2 | Migration `0002_profiles`: `profiles`, `addresses`; RLS policies; signup trigger auto-creating `profiles` from `auth.users` with role claim | 3 |
| B3 | Migration `0003_restaurants`: `restaurants`, `restaurant_hours`; GiST geo index; RLS; status/rating defaults | 3 |
| B4 | Migration `0004_catalog`: `menu_categories`, `menu_items`, `menu_item_options`; GIN name index; RLS; availability CHECK | 3 |
| B5 | Migration `0005_docs_search`: `merchant_documents`, `search_documents`; triggers maintain search rows from restaurants/menu; RLS | 2 |
| B6 | Migration `0006_storage`: storage buckets + policies (product-images, merchant-docs, avatars) | 1 |
| B7 | RLS policy tests per role matrix (PF-DOC-19 §3.3, PF-DOC-20 §3.4) for all Sprint-1 tables | 2 |

### Data layer (packages/data)

| # | Task | SP |
|---|---|---|
| D1 | `AuthRepositorySupabase` implementing `AuthRepository` (signIn/signUp/signOut/watchSession, role claim, reset password) | 3 |
| D2 | `ProfileRepositorySupabase` (read/update own, avatar upload to `avatars`) | 2 |
| D3 | `RestaurantRepositorySupabase` (owner create/update, menu CRUD, hours, doc upload to merchant-docs) | 3 |
| D4 | `DiscoveryRepositorySupabase` (active restaurants nearest-first via PostGIS, restaurant detail + menu) | 2 |

### Features (Flutter)

| # | Task | SP |
|---|---|---|
| F1 | `auth_feature`: complete password reset + phone change (FR-AUTH-005); wire concrete repo provider | 2 |
| F2 | `profile_feature`: profile edit page + avatar; addresses table-backed (read) | 2 |
| F3 | `merchant_feature` (new): onboarding wizard (FR-ONB-001), verification status (FR-ONB-002), restaurant mgmt | 3 |
| F4 | `menu_feature` (new): category/item CRUD + out-of-stock toggle (FR-MENU-001/002), CSV import (FR-MENU-003, S) | 3 |
| F5 | `discovery_feature` (new): restaurant list (nearest-first, FL-R07 states) + restaurant detail | 3 |

### Testing (PF-DOC-20)

| # | Task | SP |
|---|---|---|
| T1 | Unit: data repositories (mocktail/http_mock_adapter), BR-mirror tests for hours/stock gates | 2 |
| T2 | Widget: all four states per FL-R07 for new pages; Riverpod overrides | 2 |
| T3 | Backend: Deno-local/SQL policy tests; migration up/down dry-run; RLS present on every table | 2 |
| T4 | Golden: design-system touchpoints for new widgets; coverage gate (features ≥75%, data ≥80%) | 1 |

**Total ≈ 36 SP** (vs 26 SP/sprint capacity). Mitigation: F5 discovery read
could split; F4 CSV import (FR-MENU-003, S) droppable to a follow-up. Trim list
agreed with PO during planning: B6 merges into B5; T4 shrinks.

## 5. Folder Changes

```
backend/supabase/migrations/0001_..0006_*.sql   (new)
backend/supabase/functions/                     (created; empty — no EF this sprint)
backend/seeds/                                  (dev seeds: restaurants, menu)
packages/data/lib/src/repositories/             (new concrete repos)
packages/features/merchant_feature/             (new package)
packages/features/menu_feature/                 (new package)
packages/features/discovery_feature/            (new package)
docs/sprints/sprint-01-plan.md                  (this doc)
```

No new top-level directories (MO-R01). All three new packages follow the
feature scaffold convention (pubspec `resolution: workspace`, layered `src/`,
`test/`, analysis options `../../../analysis_options.yaml`).

## 6. Database Changes

Tables (PF-DOC-13 §3.2, per conventions: uuid PK `gen_random_uuid()`, money
`bigint`, `timestamptz`, `deleted_at` where noted, text status + CHECK):

- `profiles`, `addresses`
- `restaurants`, `restaurant_hours`
- `menu_categories`, `menu_items`, `menu_item_options`
- `merchant_documents`, `search_documents`

Indexes: `idx_restaurants_geo` (GiST), `idx_menu_search` (GIN trgm),
`idx_restaurants_status`, `idx_menu_items_rest_avail`. Triggers: `set_updated_at`
(shared), `profiles` creation on auth signup, `search_documents` sync,
availability cascades. RLS enabled on every table (SUP-R01/DB-R06).

## 7. API Changes

- **PostgREST read surface** (PF-DOC-14 §3.2): restaurants (status=active),
  restaurant_hours (by restaurant_id), menu_categories/menu_items
  (is_available=true), menu_item_options, profiles (self), addresses (self),
  search_documents (public).
- **PostgREST writes (RLS-benign)**: profile update (self, non-role), address
  CRUD (self), restaurant + menu + hours owner writes (business), merchant docs.
- **No new Edge Functions** (nothing changes money/order state in Sprint 1).
  Signup/role handled by DB trigger; admin ops deferred to Sprint 4.
- Error model: reuse PF-DOC-14 §3.4 codes via data-layer exception mapper.

## 8. Flutter Changes

- Concretise `auth_feature` + `profile_feature` providers against Supabase
  repos (composition-root overrides; tests override via `overrideWith` FL-R04).
- New `merchant_feature`: onboarding wizard steps (business info → address →
  KTP/NIB upload → submit), status page (FR-ONB-002).
- New `menu_feature`: category + item editors, out-of-stock toggle, CSV import.
- New `discovery_feature`: `RestaurantListPage` (nearest-first, FL-R07 states),
  `RestaurantDetailPage` (menu/hours/rating/ETA from read surface).
- All screens handle loading/error/empty/data (FL-R07); async through providers
  (FL-R01); no `BuildContext` across gaps (FL-R02).

## 9. Testing

- Unit: repo contracts with mocktail + http_mock_adapter; BR hours/stock
  mirrors; money formats.
- Widget: states + interactions with ProviderScope overrides.
- Backend: SQL policy tests per role matrix (customer/business/driver/admin);
  migration dry-run; RLS-on-every-table assert.
- Coverage gates: data ≥80%, features ≥75%, critical paths ≥90% (PF-DOC-20
  §3.8, NFR-037). Golden images updated (TS-R05).
- `melos run check` green (format/analyze/deps-check/tests) as the gate.

## 10. Checklist

Status as of 2026-08-09. `[x]` = verified by the automated gates on this
machine. `[ ]` = not yet verified here. DB-level items (migrations up/down,
RLS policy execution, Realtime/PostGIS behaviour) need the local
Supabase/Docker stack (`melos run db-test`); Docker is intentionally not
installed on this machine (memory constraint), so those are **static SQL
review only** until run on a Docker-equipped machine.

Client-side (verified):
- [x] Auth signup/login/logout/session — data-source + widget tests green (live-backend E2E deferred)
- [x] Merchant onboarding wizard + verification status — `merchant_feature` widget tests green
- [x] Menu CRUD + out-of-stock toggle — `menu_feature` widget tests green
- [x] Discovery list + detail — `discovery_feature` widget tests green
- [x] All four UI states (FL-R07) covered by widget tests on every new screen
- [x] Coverage gates met (core 100, data 98.7, util 94.6, design 87.0, features ≥96) and `melos run check` exit 0
- [x] No `supabase_flutter`/`dio` import in any feature/app (MO-R02) — deps-check green

Backend (written + statically reviewed; execution deferred, needs Docker):
- [ ] Migrations 0001–0006 apply cleanly up/down on dev + CI dry-run
- [ ] RLS policy tests pass for all Sprint-1 tables (`backend/supabase/tests/database/`)
- [ ] Menu writes propagate to read-side via Realtime (≤30s)
- [ ] Discovery ordering nearest-first against live PostGIS

Outstanding:
- [ ] Goldens authored/reviewed for new design-system touchpoints (TS-R05)
- [ ] Changelog fragment drafted (PF-DOC-26)

## 11. Definition of Done (PF-DOC-30 + Sprint 1)

- Every in-scope FR (2.1) has ≥1 test mapped to its acceptance criteria (TS-R01).
- BRs engaged (2.3) verified by server-side + Dart mirror tests (TS-R02).
- All four states + accessibility for changed screens (DoD 3.2, NFR-029).
- `melos run check` exit 0; coverage gates pass; goldens reviewed (TS-R05).
- Migrations reviewed for RLS/security (SEC-R01 gate for privileged code).
- No open SEV-1/2 issues; usability round done for changed flows
  (PF-DOC-25 §3.6).
- Ready for PO review; Sprint 2 (Cart, Checkout, Orders) starts only after sign-off.
