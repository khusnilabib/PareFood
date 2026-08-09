# pare_core

Pure domain foundation for PareFood (PF-DOC-10 §3.2). **No Flutter, no network, no
Supabase SDK.**

## Owns

- `PareException` hierarchy — typed errors (network/auth/not-found/forbidden/
  business-rule/server…) mapped to UI messages (PF-DOC-11 §3.5).
- `Money` — immutable whole-rupiah value object using `BigInt` (web-safe), with
  arithmetic and JSON `bigint` wire format (PF-DOC-13 DB-R02).
- `PareResult<T>` — Freezed sealed success/failure envelope returned by repositories.

## Boundaries

- Must NOT import `package:flutter/*`.
- Must NOT perform I/O or depend on `pare_data`/`pare_design`.
- Contains no business decisions or pricing logic (PF-DOC-18).

## Codegen

Freezed models are generated with `melos run codegen` and committed (FL-R06). Do not
hand-edit `*.freezed.dart`.
