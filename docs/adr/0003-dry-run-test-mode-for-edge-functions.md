# ADR 0003 — Edge Functions support a hermetic dry-run mode for unit tests

| | |
|---|---|
| Status | Accepted |
| Date | 2026-08-15 |
| Deciders | Principal Architect, QA |
| References | PF-DOC-20 (TS-R06 hermetic tests), PF-DOC-23 |

## Context

Edge Functions need unit tests that run in CI without a live Supabase stack
(the pgTAP suite covers DB integration; the `deno test` suite covers the
function contract). The existing Sprint-1 skeletons (`place-order`, `dispatch`)
side-step this by never touching a DB — they echo the payload. That is too weak
for the richer `accept-order` / `ready-order` functions, which must enforce the
order state machine, BR-ACCEPT-001 timer, BR-TIMER-001 bounds, role guards and
ownership — none of which can be exercised when the function has no client.

Forcing every test to mock the full Supabase client surface is verbose and
brittle; running a real Supabase per `deno test` is slow and non-hermetic
(violates TS-R06).

## Decision

**Each Edge Function creates its Supabase clients lazily from environment
variables (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`).
When the env is absent — as in the `deno test` suite — the service client is
`null` and the function runs in "dry-run" mode: it performs all input
validation and business-rule boundary checks, then returns a `{ dry_run: true }`
envelope describing the operation it *would* perform, with no DB side-effects.**

`handler(req, deps?)` accepts an optional `deps` object (`{ service, user, now }`)
for dependency injection, so integration-style tests can supply a stub client
without touching env or network.

This means:
- **Contract & validation tests** (dry-run): method, idempotency header, JSON
  parse, field types, BR bounds (BR-TIMER-001 5–45, BR-ACCEPT-001). These run
  in CI hermetically.
- **State/ownership/auth tests**: require either an injected stub client or the
  pgTAP + local-Supabase integration suite (PF-DOC-20 §3.4).

## Consequences

**Positive**
- `deno test` is fast, hermetic, no Docker required (TS-R06).
- Validation regressions are caught before the heavier pgTAP suite.
- The same source file runs unchanged in production (env present → full logic).

**Negative**
- Dry-run mode does NOT exercise auth, ownership, state guards, or the
  BR-ACCEPT-001 timer. These are explicitly delegated to the integration suite;
  the test files state this so coverage is not over-claimed.
- Reviewers must understand that a green `deno test` does not mean the function
  is behaviourally complete — the pgTAP suite is the gating one for state.

## Alternatives considered

- *Always mock the client.* Rejected: high boilerplate, fragile to SDK changes.
- *Run Supabase in `deno test`.* Rejected: slow, non-hermetic, CI-flaky.

## Compliance

- TS-R06 (hermetic tests, no network).
- PF-DOC-20 §3.4 — dry-run unit tests + pgTAP integration tests are a layered
  pair; coverage targets (apps ≥60%, features ≥75%) apply to the combined set.
