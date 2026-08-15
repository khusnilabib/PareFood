# ADR 0002 — Dispatch is fired by a pg_net DB trigger, not the edge function

| | |
|---|---|
| Status | Accepted |
| Date | 2026-08-15 |
| Deciders | Principal Architect |
| References | PF-DOC-14 §3.3 (dispatch trigger note), PF-DOC-18 §3.6 (BR-DISPATCH), migration 0009 |

## Context

When an order becomes `ready`, driver dispatch must start (BR-DISPATCH-001).
Two places could initiate it:

1. The `ready-order` Edge Function, by calling `/functions/v1/dispatch`
   directly after the status update.
2. A PostgreSQL trigger on `orders` that uses `pg_net` to POST to `dispatch`.

Option 1 creates a duplicate-dispatch risk: if `ready-order` is retried
(idempotency replay) or a status update lands twice, dispatch could be called
multiple times. Option 2 fires exactly once per row-level state transition,
which is the unit the matching algorithm reasons about (BR-JOB-002: first
accept wins, others dismissed).

## Decision

**`ready-order` only performs the state transition (`preparing → ready`) and
inserts `order_status_history`.** A DB trigger
(`orders_dispatch_on_ready`, migration 0009) detects the transition into
`ready` and POSTs to `/functions/v1/dispatch` via `net.http_post`, idempotently
keyed `dispatch-<order_id>`. The trigger is `security definer` so it can read
the service-role key GUC and call the function.

A commented-out `pg_cron` retry job (BR-DISPATCH-004/005) is sketched in
migration 0009 to re-fire dispatch for orders stuck in `ready` with no
`deliveries` row; it is enabled per-environment after confirming `pg_cron`
availability.

## Consequences

**Positive**
- `ready-order` stays small and side-effect-free; no inter-function HTTP call
  in the happy path (lower latency, fewer failure modes).
- Dispatch fires exactly once per transition, even if `ready-order` is replayed
  (idempotency replay returns the cached result without re-updating status).
- The retry path is cron-driven, decoupled from the request lifecycle.

**Negative**
- Dispatch now depends on a DB trigger + `pg_net` extension (already enabled in
  0001) and on the `app.supabase_service_role_key` GUC being set per
  environment. If the GUC is unset, the POST is unauthenticated and `dispatch`
  (once it enforces internal auth) will reject it. Production MUST set the GUC.
- Trigger-based async makes local debugging slightly harder; the cron retry is
  the safety net.

## Alternatives considered

- *`ready-order` calls `dispatch` directly.* Rejected: duplicate-dispatch race
  on retry; couples request latency to dispatch.
- *Cron-only dispatch (poll `ready` orders).* Rejected: up to 2 min latency
  before first dispatch attempt — too slow for BR-DISPATCH-001.

## Compliance

- PF-DOC-14 §3.3 dispatch trigger note (now implemented, was a documented
  intent).
- BR-JOB-002 (atomic first-accept-wins) — deduplication responsibility stays in
  `accept-job`, but the trigger prevents redundant offer rounds.
- PF-DOC-19 §3.2 — the service-role key is read from a GUC, never committed.
