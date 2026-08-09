# pare_util

Pure helpers for PareFood (PF-DOC-10 §3.2). **No Flutter, no network, no domain
knowledge.**

## Owns

- Formatters — IDR currency (`Rp 85.000`), Indonesian dates (`06 Agu 2026`),
  24-hour time, ETA (`±25 mnt`), relative time (PF-DOC-16 §3.3/§3.10).
- Validators — required, email, Indonesian phone, min-length.
- Extensions — string normalisation, digit extraction, rounding, clamping.

## Boundaries

- Must NOT depend on `pare_core` (formatters work on primitives so util stays
  domain-free).
- Must NOT import `package:flutter/*`.

## Tests

`dart test` — pure VM tests, no mocks required.
