# PareFood — Production Roadmap (4 apps to Play Store)

| | |
|---|---|
| Status | Living document — the execution path from Sprint 1 to Play Store launch |
| Date | 2026-08-15 |
| Owner | Engineering |
| References | PF-DOC-25 (sprint roadmap), PF-DOC-26 (release), PF-DOC-22 (deployment), PF-DOC-30 (DoD) |

## 1. Purpose

This is the **master execution plan** for taking PareFood from its current state
(Sprint 1 complete + customer discovery/cart slice) to a Play-Store-launchable,
real-world-usable platform where **all four apps are mutually integrated** around
the order lifecycle. It exists so every contribution advances the platform
consistently and maintainably — no ad-hoc feature work that drifts from the
architecture (PF-DOC-23, PF-DOC-30).

PareFood's positioning: a **local-first food-delivery platform for the Pare
region** (not global). It competes with GoFood/ShopeeFood on experience, but
serves a focused geographic community — lower merchant fees, local language,
local payment habits, tighter merchant relationships.

## 2. The integration spine: the order lifecycle

All four apps integrate through **one shared state machine** (PF-DOC-18 §3.3):

```
Customer (AP-PF)         Merchant (AP-PB)        Driver (AP-PD)         Admin (AP-PA)
    place-order ─────────▶ accept/decline
                           accepted → preparing
                           preparing → ready ──▶ dispatch ──▶ job offer
                                                    accept-job ◀──── (accept)
                                                    pickup (code) ───▶ picked_up
                                                    deliver (photo)─▶ delivered
    track (realtime) ◀──────────────────────────────────────────── live location
    order history                                                  order board
    cancel ◀──────────── force-cancel ◀────────── fail ◀────────── force-cancel
```

Every app reads/writes the same `orders` + `deliveries` tables (PF-DOC-13) through
the same Edge Functions (PF-DOC-14). The `orders_feature` package is the **shared
Flutter domain** all four apps consume (with role-scoped repository queries and
callback-injected write actions to respect MO-R02d).

## 3. Phase plan (mapped to PF-DOC-25 sprints)

| Phase | Sprint | Apps touched | Deliverable | Status |
|---|---|---|---|---|
| **P0 Foundations** | S1 | — | Monorepo, CI, design tokens, DB migrations, edge function skeletons | ✅ Done |
| **P1 Backend core** | S2 | — | Multi-role (FR-AUTH-006), hot indexes (0010), user_roles (0011) | ✅ Done (code) |
| **P1 Backend core** | S3 | — | Order-lifecycle edge functions (place/accept/ready/dispatch/pickup/deliver/complete/cancel) | 🟡 In progress (this slice) |
| **P2 Customer** | S4 | AP-PF | Discovery + cart + checkout (place-order) + order history/tracking | 🟡 Partial (discovery+cart done; orders in this slice) |
| **P2 Customer** | S5 | AP-PF | Checkout + payments (PSP sandbox), address, promo, process-payment, webhook-psp | ✅ Done (code) |
| **P2 Customer** | S6 | AP-PF | Realtime order tracking, notifications, device tokens, send-notification | ✅ Done (code) |
| **P3 Merchant** | S7 | AP-PB | Onboarding, menu CRUD, incoming orders (realtime), accept/decline/mark-ready wired | ✅ Done (code) |
| **P3 Driver** | S8 | AP-PD | Online toggle, job accept/decline/pickup/deliver wired, earnings | ✅ Done (code) |
| **P4 Integration** | S9 | all | Cross-app E2E (full order lifecycle across 4 apps) | ✅ Done (code) |
| **P4 Admin** | S10 | AP-PA | Order board, force-cancel wired, analytics dashboard, audit log, finance views | ✅ Done (code) |
| **P4 Finance** | S11 | AP-PA/AP-PB | Settlements, payouts, reconciliation, 3 cron edge functions | ✅ Done (code) |
| **P5 Hardening** | S12 | all | Perf, security scan, pen-test prep, monitoring | ⏳ |
| **P5 Hardening** | S13 | all | E2E suite, a11y, load tests, crash-free | ⏳ |
| **P6 Launch** | S14 | all | Store submission (AAB signed), ops runbooks, pilot (50 merchants) | ⏳ |

## 4. This development slice (what we build now)

To advance the **integration spine** as far as possible in one consistent chunk:

### 4.1 Backend — order-lifecycle edge functions (S3 scope)
Complete the remaining functions in dry-run mode with contract tests (ADR 0003):
`place-order` (full), `accept-job`, `decline-job`, `driver-pickup`,
`driver-delivered`, `complete-order`, `cancel-order`. Plus a shared
`orders_repository` query helper. All enforce PF-DOC-18 business rules.

### 4.2 orders_feature package (shared Flutter domain)
Extend the read-only skeleton to serve all four apps:
- Domain: `OrderDetail` (with items + status timeline), `DeliveryJob`, role-scoped summaries.
- Data: `OrdersRepository` gains `fetchForRestaurant`, `fetchAssignedToDriver`,
  `fetchAll` (admin), `fetchByIdWithItems`.
- Application: per-app providers.
- Presentation: `IncomingOrdersPage` (merchant), `JobOffersPage` + `ActiveDeliveryPage`
  (driver), `OrderBoardPage` (admin), `OrderDetailPage` (customer, with timeline).
  Write actions are callback-injected (MO-R02d).

### 4.3 App wiring (all 4 apps)
- **AP-PF**: add "Pesanan" tab + order detail/tracking route.
- **AP-PB**: add "Pesanan" tab (incoming orders, accept/decline, mark ready).
- **AP-PD**: replace empty shell with 2 tabs (Pekerjaan, Akun) + job offers + active delivery.
- **AP-PA**: replace placeholder dashboard with order board + force-cancel.

## 5. Maintainability guardrails (apply to every slice)

1. **Package boundaries (MO-R02)**: features never import each other; apps wire
   via callbacks. `melos run deps-check` must stay green.
2. **Quality gate (CS-R01)**: `melos run check` (format + analyze + deps-check + test)
   green on every push. 0 analyze issues, 0 format diffs.
3. **Tests (TS-R06)**: hermetic unit/widget tests per feature; pgTAP for DB rules;
   deno contract tests for edge functions. Coverage gates: core ≥90, data ≥80,
   features ≥75, apps ≥60.
4. **Docs (CA-02)**: each slice updates the relevant PF-DOC-XX section or a sprint
   note; ADRs for any architectural decision.
5. **Conventional commits (GW-R02)**: `feat(<scope>): ...`, `fix(<scope>): ...`,
   `docs(<scope>): ...`, `chore(<scope>): ...`. One logical change per commit.
6. **Definition of Done (PF-DOC-30)**: feature complete = all states (loading/
   error/empty/data), i18n (Bahasa), no hard-coded strings/colours, tests, docs.

## 6. Remaining hardening before Play Store (S12–S14 checklist)

- [ ] Real Supabase production project (not dev placeholder).
- [ ] PSP integration (Midand/Xendit) with sandbox → prod cutover.
- [ ] Signed release AAB (keystore in CI secrets — workflow ready).
- [ ] Privacy policy + ToS (Play Console requirement).
- [ ] App Store / Play Store assets (icons, screenshots, descriptions in ID).
- [ ] Crashlytics + Sentry wired (Sentry DSN already a dart-define).
- [ ] a11y audit (TalkBack/VoiceOver, 44px touch targets — already enforced).
- [ ] Load test: 10k concurrent orders (NFR-003).
- [ ] Security: pen-test, RLS audit, secret rotation (PF-DOC-19).
- [ ] Pilot: 50 merchants in Pare region (M2 beta gate).

## 7. How to advance this plan

Each subsequent work session should:
1. Read this doc + `worklog.md` to see where the platform stands.
2. Pick the next incomplete row in §3 (or the next checkbox in §6).
3. Implement it following §5 guardrails.
4. Append a `worklog.md` entry + update the §3 Status column here.
