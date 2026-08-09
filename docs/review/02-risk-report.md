# Review 02 — Risk Report

| | |
|---|---|
| Review ID | PF-REV-02 |
| Title | Consolidated Risk Report — PareFood Platform |
| Date | 2026-08-06 |
| Predecessors | Review 01 (findings), per-document risk registers (PF-DOC-01..30) |
| Successors | Review 04 (checklist), Review 05 (approval) |

---

## 1. Purpose

Consolidate the highest-severity risks from every document's risk register with the new
risks surfaced by the architecture review. Every top risk has an owner and a mitigation
that is already encoded in the documentation set (so it is actionable, not advisory).

## 2. Risk Register (Top 12, ranked)

Ranking: Likelihood × Impact. Owners: Arch = Platform Architect, Fin = Finance,
Sec = Security, Ops = Operations, PD = Product/PO.

| # | Risk | L | I | Exposure | Mitigation (documented) | Owner |
|---|---|---|---|---|---|---|
| R01 | Dispatch race: two drivers accept the same job | M | H | Double assignment / double fare | BR-DISPATCH-003 "first accept wins"; `accept-job` runs atomically in a DB transaction + optimistic concurrency (API §3.5); `deliveries` RLS insert denied → single write path | Arch |
| R02 | Financial integrity bug (double settle / double payout) | M | H | Cash loss, trust damage | Append-only `wallet_transactions`, idempotency keys (NFR-021), transactions in Edge Functions (API-R02), two-person settlement approval (FR-FIN-004), quarterly money audit (BR-R04) | Fin |
| R03 | COD cash reconciliation gap (new) | M | H | Missing cash → driver/merchant disputes | BR-COD-001..004 remittance + `reconcile` COD ledger; fraud caps (BR-FRAUD-001) | Fin |
| R04 | RLS regression on new tables (device_tokens, driver_documents, promo_redemptions, search_documents, user_roles) (new) | M | H | Data exposure / privilege escalation | DB-R06 (no RLS fails CI), policy tests in CI (PF-DOC-19 §3.3), storage policies reviewed | Sec |
| R05 | Driver impersonation / self-assignment (new) | M | H | Order theft, fake earnings | `accept-job` verifies offer + JWT; no direct `deliveries` insert policy; ephemeral signed Realtime channels | Sec |
| R06 | Fraud exploits (COD abuse, voucher farming) | H | H | Revenue loss | BR-FRAUD-001..005, BR-PROMO-005/006 (budget cap + per-user cap), refund velocity checks | Sec/Fin |
| R07 | State-machine drift after the `assigned` fix (new) | M | M | Orders stuck in `ready` | `orders`/`deliveries` sub-state contract (BR-ORDER); order_status_history append-only; 20-min dispatch timeout cancels | Arch |
| R08 | Search index freshness (new) | M | M | Stale menu results | `search_documents` maintained by trigger on menu/restaurant writes; reconciled by cron | Arch |
| R09 | Realtime hot-write on `driver_locations` | H | M | DB load, latency | 5 s throttle, batched writes, TTL + polling fallback (NFR-014) | Arch/Ops |
| R10 | Push delivery failure (device tokens) (new) | M | M | Missed job offers | `device_tokens` upsert, in-app notification centre fallback, FCM data-message for background | Arch |
| R11 | Multi-role scope creep (new) | M | M | Auth complexity | FR-AUTH-006 is SHOULD (post-MVP); `user_roles` design locked now, implementation deferred | Arch/PD |
| R12 | ETA/fee promises vs reality (marketing) | M | M | Trust damage | BR-ETA-001..002, transparency rule (UX-R03), marketing-truth rule (CA-02) | PD |

## 3. Inherited Register Highlights (from documents)

| Source | Key risk | Mitigation |
|---|---|---|
| PF-DOC-01 | Vision drift across 4 products | Principles + governance (PF-DOC-07/18) |
| PF-DOC-03 | Commission economics (15/20%) | Unit economics model, config in PF-DOC-18 |
| PF-DOC-09 | Stack coupling (Supabase single project) | Extensions pinned; Supabase CLI diff in CI |
| PF-DOC-11 | Rules mirrored in Dart + Deno (TS-R02) | Shared fixtures; drift fails CI |
| PF-DOC-13 | Schema churn post-launch | Migration discipline (DB-R01) + backward-compat rule |
| PF-DOC-19 | Secret exposure / key rotation | SEC-004 scan + rotation cadence |
| PF-DOC-20 | Dual-implementation drift | Contract tests (TS-R02) |
| PF-DOC-25 | Sprint overflow | 10–25% risk buffers; scope change control |
| PF-DOC-27 | SLO breach unnoticed | Dashboards + alerts, watch window |

## 4. Accepted Residual Risks

| Risk | Reason | Watch |
|---|---|---|
| Single Supabase region (PF-DOC-22 §3.1) | MVP simplicity; nearest region chosen | Revisit for multi-region in PF-DOC-29 |
| Realtime max ~10k sockets (NFR-014) | Pilot scale far below | Monitor at beta |
| Dual rule implementation (Dart + Deno) | Requires offline rule checks | Shared fixture discipline (TS-R02) |

## 5. Verdict

No risk is in the **unacceptable** band. R01–R05 have High exposure and are treated as
release-blocking criteria in PF-DOC-30 §3.8. Owners are assigned; every mitigation is
already specified in the documentation suite (post-fix).
