# Architecture Decision Records (ADR)

This folder records architecturally significant decisions for the PareFood
platform (PF-DOC-23 §3.10, PF-DOC-30). Each ADR is immutable once accepted;
supersession happens by writing a new ADR that references the old one.

## Index

| # | Title | Status | Date |
|---|---|---|---|
| [0001](0001-edge-functions-for-money-state-mutations.md) | Edge Functions own all money/state mutations | Accepted | 2026-08-15 |
| [0002](0002-pg-net-dispatch-trigger.md) | Dispatch is fired by a pg_net DB trigger, not the edge function | Accepted | 2026-08-15 |
| [0003](0003-dry-run-test-mode-for-edge-functions.md) | Edge Functions support a hermetic dry-run mode for unit tests | Accepted | 2026-08-15 |

## Format

Each ADR follows:

- **Context** — the problem and forces
- **Decision** — what we chose
- **Consequences** — trade-offs, positive and negative
- **Alternatives considered** — what we rejected and why
- **Compliance** — doc references (PF-DOC-XX) and rule IDs (XX-RR)
