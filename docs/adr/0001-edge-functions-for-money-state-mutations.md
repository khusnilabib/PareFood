# ADR 0001 — Edge Functions own all money/state mutations

| | |
|---|---|
| Status | Accepted |
| Date | 2026-08-15 |
| Deciders | Principal Architect |
| References | PF-DOC-14 (API-R01, API-R06), PF-DOC-18 (BR-R01), PF-DOC-19, PF-DOC-12 |

## Context

The platform has two write surfaces (PF-DOC-14 §3.1): PostgREST (RLS-scoped
row writes) and Edge Functions. Money moves (wallets, payment intents,
settlements) and order state transitions are safety-critical: they must be
atomic, idempotent, audited, and validated server-side regardless of what the
client sends. RLS alone cannot express multi-table transactional invariants
(e.g. "cancel order → refund → reverse wallet → write history") and must not be
trusted as the only guard for money (API-R06).

## Decision

**All money and order-state mutations are implemented exclusively as Edge
Functions using the service-role client (bypassing RLS).** PostgREST writes are
restricted to benign, single-row, user-owned data (profile, addresses,
favorites, cart, review read-state). RLS policies explicitly deny inserts on
money/state tables (`with check (false)`), forcing writes through functions.

This is already encoded as rule **API-R01** (PF-DOC-14 §6). This ADR records
that the rule is binding for `accept-order`, `ready-order`, `place-order`,
`cancel-order`, `process-payment`, `complete-order`, `dispatch`, and all future
money/state functions, and that the shared `_shared/` helpers
(`serviceClient`, `userClient`, `resolveCaller`, `requireRole`) are the
canonical way to obtain clients and verify the caller.

## Consequences

**Positive**
- Single, audited implementation path for money (BR-R01).
- Functions can run multi-table transactions and insert into
  `order_status_history` / `wallet_transactions` (which deny direct inserts).
- Caller identity + role is verified per request via JWT app_metadata.role
  (mirrored by the `sync_role_claim()` trigger, PF-DOC-12 §3.2).

**Negative**
- More code surface to test than "RLS does it all".
- Requires the service-role key in the function runtime (secured by Supabase
  secrets, never shipped to clients — PF-DOC-19).

## Alternatives considered

- *PostgREST + RLS for everything.* Rejected: cannot express atomic
  multi-table money moves or the order state machine safely.
- *RPC (PostgREST `rpc/`).* Rejected for money: no idempotency header support,
  harder to call PSPs, no secret access.

## Compliance

- API-R01, API-R02 (idempotency), API-R06 (validate inputs, never trust RLS).
- BR-R01 (rules live server-side).
- The `orders_update_owner` RLS policy still permits business-role updates, but
  functions use the service client + optimistic `.eq("status", ...)` guards so
  the state machine is enforced regardless of RLS.
