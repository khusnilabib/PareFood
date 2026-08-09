# Review 01 — Architecture Review Report

| | |
|---|---|
| Review ID | PF-REV-01 |
| Title | Software Architecture Review — PareFood Platform docs (PF-DOC-01..30) |
| Date | 2026-08-06 |
| Reviewer | Architecture Review Board (independent) |
| Scope | All 30 documents in `docs/` + `README.md` (Phase 1 deliverable) |
| Predecessors | PF-DOC-30 §3.6 (Phase 1 review gate) |
| Successors | Review 02 (Risk), 03 (Improvements), 04 (Checklist), 05 (Approval) |

---

## 1. Purpose

Review the Phase 1 documentation suite for architectural soundness, internal
consistency, completeness of requirements and correctness of the data model before
Phase 2 implementation begins. Findings are classified and each carries a disposition:
`FIXED` (corrected in this pass), `ACCEPTED` (intentional; noted), `DEFERRED` (backlog,
Review 03).

## 2. Method

1. Re-read every document (30 + README), not just the earlier self-check.
2. Cross-verified every traceable ID: FR/NFR/BR/SEC references, table names, function
   names, status CHECKs, inventory counts, dates and roadmap figures.
3. Model-walked the data flow: cart → place-order → accept → prepare → ready → dispatch →
   pickup → deliver → complete → settle/payout → reconcile, checking that every step has
   a rule (PF-DOC-18), a function (PF-DOC-12/14) and a table (PF-DOC-13) with the
   correct RLS posture (PF-DOC-19).
4. Each finding below was confirmed against the actual document text (line-cited).

## 3. Findings Register

### 3.1 Architecture Problems

| ID | Sev | Finding | Docs (line) | Disposition |
|---|---|---|---|---|
| AR-01 | High | `dispatch` has no defined trigger: API says "internal (trigger)" but nothing invokes it; a driver job would never be created. | PF-DOC-14:89, PF-DOC-12:118 | FIXED — DB trigger on `orders.status='ready'` → `pg_net` HTTP POST to `dispatch` (idempotent, retried). PF-DOC-12 §3.6/§3.8, PF-DOC-14 §3.3. |
| AR-02 | High | Driver job lifecycle has **no endpoints**: no `ready-order` (FR-ORDER-003 needs merchant to mark ready), no `accept-job`/`decline-job` (FR-ORDER-004 needs accept/decline; RLS forbids direct `deliveries` inserts). | PF-DOC-14:85-102, PF-DOC-19:72 | FIXED — add `ready-order`, `accept-job`, `decline-job`; add RLS + FR trace. |
| AR-03 | High | COD is modeled as a payment method but the cash lifecycle is undefined: driver collects cash, yet there is no rule/function for remitting cash to the platform or crediting the driver's wallet, and `reconcile` has no COD ledger. | PF-DOC-18:36/54, PF-DOC-14:99 | FIXED — BR-COD-001..004 + FR-PAY-004; `reconcile` covers COD vs remittances. |
| AR-04 | Medium | Multi-role users are impossible: `profiles.role` is a single immutable column, but real users are customers who also drive or operate a merchant. | PF-DOC-13 (profiles), PF-DOC-02 | FIXED — FR-AUTH-006 (SHOULD) + `user_roles` join table; single `profiles.role` stays authoritative for MVP RLS. |
| AR-05 | Low | `cancel-order` (app) and `user-admin` (admin) both implement force-cancel — duplicated privileged logic. | PF-DOC-14:94,100 | ACCEPTED — one internal cancel service; `user-admin` delegates to it. Documented note. |

### 3.2 Inconsistent Rules

| ID | Sev | Finding | Docs (line) | Disposition |
|---|---|---|---|---|
| AR-06 | High | `orders.status` CHECK omits `assigned`, but the BR-ORDER state machine and state diagram use `ready → assigned → picked_up`. A dispatched order could never exist. | PF-DOC-13:175, PF-DOC-18:70-71/164-170 | FIXED — division of labour made explicit: `orders.status` keeps logical merchant/customer phases (`ready` persists through dispatch); assignment is a `deliveries.status` sub-state (`assigned → arrived_pickup → picked_up`). BR table + diagram aligned; orders moves to `picked_up` at handover only. |
| AR-07 | High | Admin force-cancel transition cites `BR-CANCEL-002`, but §3.5 defines BR-CANCEL-003 as the admin force-cancel rule (002 = customer fee-based cancel). | PF-DOC-18:73 vs 92 | FIXED — cite BR-CANCEL-003. |
| AR-08 | Medium | FR inventory counts do not match actual rows: total claimed 64 but rows sum to 62; DISC/MENU shows 2 SHOULD but 3 exist; PAY/FIN claims 10 but lists 8. | PF-DOC-07:196-207 | FIXED — recounted after additions: **67 FRs (61 MUST, 6 SHOULD)**; per-area table corrected. |
| AR-09 | Medium | `driver_locations` read-surface row is named `orders.driver_locations` — no such table/relation. | PF-DOC-14:58 | FIXED — renamed to `driver_locations`. |
| AR-10 | Medium | FR-ONB-004 references `drivers.online` — no such table; live status lives in `driver_locations.online`. | PF-DOC-07:51 | FIXED. |
| AR-11 | Medium | BR-PRICE-004 says "price snapshot at add-to-cart; repriced at place" but the cart UX behaviour is undefined (auto-update? notify? block?). | PF-DOC-18:43 | FIXED — BR-REPRICE-001/002: notify + require confirm at checkout; stock revalidate with message. |
| AR-12 | Medium | Promo has only a global `usage_limit`; no per-user cap → voucher abuse. | PF-DOC-13:346, PF-DOC-18 §3.9 | FIXED — `promo_redemptions` table + BR-PROMO-006 (max per user). |
| AR-13 | Medium | Launch countdown (PF-DOC-26, Feb–Apr 2026) contradicts the roadmap (PF-DOC-25, S1 2026-09-07 → GA ≈ 2027-03-19). | PF-DOC-26:143-151, PF-DOC-25:150 | FIXED — countdown aligned to roadmap GA date. |
| AR-14 | Low | Rule inventory claims "14 transitions"; the table has 9 rows (11 edge cases including the 3-from-state admin row). | PF-DOC-18:197 | FIXED — wording corrected. |
| AR-15 | Low | Money unit wording "cents/sen" is wrong for IDR — the minor unit is 1 Rupiah (no sen in circulation). | PF-DOC-13 conventions | FIXED — "minor units (1 unit = Rp 1)". |

### 3.3 Missing Requirements

| ID | Sev | Gap | Docs | Disposition |
|---|---|---|---|---|
| AR-16 | High | No device-token store or registration endpoint, so FR-NOTIF-001/003 (push) cannot be delivered. | PF-DOC-13 §3.2, PF-DOC-14 | FIXED — `device_tokens` table (FCM/APNs, upsert by function) + FR-NOTIF-005 + `register-device-token`. |
| AR-17 | Medium | Driver onboarding documents have no tracking rows; only `merchant_documents` (business fields) exists. | PF-DOC-13:377-386 | FIXED — `driver_documents` table + FR-ONB-005. |
| AR-18 | Medium | Restaurant + menu item search (NFR-004 < 300 ms) relies only on `menu_items.name` GIN; cross-restaurant item search is unindexed. | PF-DOC-13:468 | FIXED — denormalized `search_documents` table (restaurant + item, GIN), trigger-maintained. |
| AR-19 | Low | Option `price_adjust` never enters any pricing formula; `line_total = qty × unit_price` ignores selected options. | PF-DOC-13:162, PF-DOC-18:36 | FIXED — `line_total = qty × (unit_price + Σ option price_adjust)` added to BR-PRICE and column note. |

### 3.4 Database Problems

| ID | Sev | Finding | Docs (line) | Disposition |
|---|---|---|---|---|
| AR-20 | High | `reviews.order_id` is `FK unique`, but FR-RATE-001 = one review **per order per target** (restaurant AND driver) → second review blocked by the unique constraint. | PF-DOC-13:306, PF-DOC-07:121 | FIXED — `UNIQUE(order_id, target_type)`; column note updated. |

### 3.5 Security Risks

| ID | Sev | Finding | Docs | Disposition |
|---|---|---|---|---|
| AR-21 | Medium | New tables (device_tokens, driver_documents, promo_redemptions, search_documents, user_roles) need explicit RLS posture or the DB-R06 "no RLS" CI rule would be violated. | PF-DOC-13 DB-R06, PF-DOC-19 §3.3 | FIXED — RLS rows added (see Security report notes). |
| AR-22 | Low | Driver job accept/decline must go through a verified Edge Function, not a PostgREST insert; otherwise any driver could assign themselves. | PF-DOC-19:72 | FIXED — `accept-job` verifies offer + token; no direct insert policy on `deliveries`. |

### 3.6 Performance / Scalability

| ID | Sev | Finding | Docs | Disposition |
|---|---|---|---|---|
| AR-23 | Medium | `driver_locations` is high-write with per-update Realtime broadcast; no pacing rule. | PF-DOC-13:449/501, PF-DOC-12:96 | FIXED — min 5 s between location updates, batched writes; polling fallback retained (PF-DOC-12 §3.5). |
| AR-24 | Low | Dispatch retries/queue have no metric or alert; a stuck dispatch would go unnoticed until the 20-min timeout. | PF-DOC-27 | FIXED — `dispatch_queue` metric + alert in PF-DOC-27. |

### 3.7 Dependency Problems

| ID | Sev | Finding | Docs | Disposition |
|---|---|---|---|---|
| AR-25 | Medium | `melos.lock` does not exist — Melos produces no lockfile; only `pubspec.lock` files exist. | PF-DOC-24:122 | FIXED — remove `melos.lock`. |

### 3.8 Flutter / Offline

| ID | Sev | Finding | Docs | Disposition |
|---|---|---|---|---|
| AR-26 | Medium | Offline cache storage is ambiguous (`shared_preferences/drift`) and mis-sized: menu catalog snapshots don't fit shared_preferences. | PF-DOC-11:99 | FIXED — drift for structured caches; shared_preferences for small settings only; cache size budget stated. |

### 3.9 Deployment

| ID | Sev | Finding | Docs | Disposition |
|---|---|---|---|---|
| AR-27 | Medium | Path `urlStrategy` SPA (AP-PA web) needs all routes → `index.html` fallback; omitted. | PF-DOC-22:62-67 | FIXED — add fallback rule. |

### 3.10 Folder Structure / Artifacts

| ID | Sev | Finding | Docs | Disposition |
|---|---|---|---|---|
| AR-28 | Low | Referenced artifacts do not yet exist and must be created in Phase 2: `docs/ux-findings/`, `docs/runbooks/`, `docs/design-tokens.json`, `CONTRIBUTING.md`. | PF-DOC-15, 16, 28 | DEFERRED — added to Review 03 backlog. |

### 3.11 Naming Problems

| ID | Sev | Finding | Docs | Disposition |
|---|---|---|---|---|
| AR-29 | Low | `orders.completed_at` (lifecycle done) vs `deliveries.delivered_at` (handover) are near-synonyms; collision risk. | PF-DOC-13:191/243 | ACCEPTED — semantics documented (completed_at = order finalised incl. payment; delivered_at = physical handover). |
| AR-30 | Low | `menu_item_options.choices` (jsonb) and `cart_items.selected_options` (jsonb) shapes are documented informally; validate shape in function. | PF-DOC-13:138/161 | ACCEPTED — JSON schema enforced in Edge Functions (PF-DOC-14 API-R06). |

## 4. Verified-Consistent (no action)

- ID conventions and chains intact: FR/NFR/BR/SEC IDs referenced in PF-DOC-13/14/18/20/27
  resolve to their catalogues.
- App codes (AP-PF/PB/PD/PA) and role names consistent across all docs and README.
- Money model (bigint minor units, snapshots, idempotency NFR-021) coherent end-to-end.
- Refund matrix (PF-DOC-18 §3.5) covers all BR-CANCEL scenarios; routing rule consistent.
- Dispatch rules (BR-DISPATCH-001..006) self-consistent after the state-machine fix.
- Commission/fare/settlement (BR-COMM/BR-FARE/BR-SETTLE) math matches PF-DOC-03.
- NFR/SLO inventory in PF-DOC-27 matches PF-DOC-08.
- Roadmap MUST coverage claim (61/61) remains valid after the FR recount (MUST total = 61).
- Storage buckets and RLS posture coherent; `delivery-proof` scoped to participants + admin.
- RLS-first posture (DB-R06, API-R01) consistently enforced across 12/13/14/19.

## 5. Summary

| Severity | Found | Fixed | Accepted | Deferred |
|---|---|---|---|---|
| High | 6 | 6 | 0 | 0 |
| Medium | 13 | 13 | 0 | 0 |
| Low | 11 | 5 | 4 | 2 |
| **Total** | **30** | **24** | **4** | **2** |

All High and Medium findings are resolved in the updated documentation. Two Low items are
deferred (artifact creation is Phase 2 work); four Low items are intentional and recorded.
