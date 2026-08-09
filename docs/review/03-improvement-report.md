# Review 03 — Improvement Report

| | |
|---|---|
| Review ID | PF-REV-03 |
| Title | Improvement Report — PareFood Platform |
| Date | 2026-08-06 |
| Predecessors | Review 01 (findings), PF-DOC-29 (future expansion) |
| Successors | Review 04, Review 05 |

---

## 1. Purpose

Track deferred improvements, Phase 2 artifact obligations, and process-level
recommendations that are not required for MVP approval but keep the system evolvable.

## 2. Phase 2 Artifact Obligations (must create)

The documentation references artifacts that do not exist yet; Phase 2 must create them
in the same PR that first uses them.

| Artifact | Path (per docs) | Owned by |
|---|---|---|
| UX findings log | `docs/ux-findings/` | Design (PF-DOC-15 §3.9) |
| Runbooks | `docs/runbooks/` | Ops (PF-DOC-28) |
| Design tokens | `docs/design-tokens.json` | Design (PF-DOC-16) |
| Contributing guide | `CONTRIBUTING.md` | Engineering (PF-DOC-23/24) |
| ADR log | `docs/adr/` | Architecture (PF-DOC-30 recommends) |

## 3. Deferred Improvements (backlog, per PF-DOC-29 process)

| ID | Improvement | Value | When | Depends |
|---|---|---|---|---|
| IMP-01 | Rules-as-config with versioned deployment (PF-DOC-18 §9) | Friction-free rule changes | Post-MVP | Config infra |
| IMP-02 | Automated rule impact simulation (fee/margin model) | Finance decisions | Post-MVP | IMP-01 |
| IMP-03 | Dynamic surge pricing | Revenue | Post-MVP | Pricing model review |
| IMP-04 | Multi-role `user_roles` activation (FR-AUTH-006) | Broader onboarding | Post-MVP | Auth refactor |
| IMP-05 | Search ranking (BM25/recency/popularity) on `search_documents` | Conversion | Beta+ | PF-DOC-29 |
| IMP-06 | Realtime throttle tuning + dedicated location service | Scale | Beta+ | Metrics (PF-DOC-27) |
| IMP-07 | Database partitioning: `orders`, `wallet_transactions` (PF-DOC-13 §9) | Scale | Post-MVP | Data volume |
| IMP-08 | Read replica for analytics traffic | Analytics offload | Post-MVP | Budget |
| IMP-09 | API versioning automation (`place-order/v2` naming) | Stability | When 1st breaking change | — |
| IMP-10 | PareHygiene score (`gen-hygiene-score`) | Differentiator | Post-MVP | PF-DOC-29 |

## 4. Process Recommendations

| # | Recommendation | Target |
|---|---|---|
| PR-01 | Add a CI job that asserts cross-doc references resolve (FR/NFR/BR/table/function names) — turns this review's manual checks into a gate. | CI (PF-DOC-21) |
| PR-02 | Enforce the PF-DOC-30 §3.6 cross-doc checklist as a PR template for `docs/` changes. | Git workflow (PF-DOC-24) |
| PR-03 | Adopt `docs/adr/` for the decisions recorded in Review 01 (dispatch trigger, sub-state split, COD ledger) so they survive. | Docs governance |
| PR-04 | Review the performance-sensitive query set (search, live board, wallet pagination) quarterly against PF-DOC-13 indexes. | Ops (PF-DOC-28) |
| PR-05 | Record driver-location battery/perf telemetry in the app to validate the 5 s throttle at beta. | Mobile (PF-DOC-11/27) |

## 5. Improvements Applied in This Pass (not deferred)

1. Dispatch trigger now explicit (pg_net) — removed a class of "stuck order" bugs.
2. COD ledger closed (remittance → wallet → reconciliation) — money flow is now a closed loop.
3. State machine / DB constraint contract unified (orders phases vs deliveries sub-state).
4. Search path made indexable via `search_documents`.
5. Notifications made implementable (device_tokens + registration function).
6. Promo abuse closed (per-user cap + redemptions ledger).
7. Offline storage decision (drift vs prefs) fixed; lockfile error removed; SPA fallback added.
