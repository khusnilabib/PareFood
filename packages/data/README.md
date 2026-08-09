# pare_data

PareFood data and infrastructure layer (PF-DOC-11 §3.5): environment config,
Supabase bootstrap, Dio networking and error mapping.

## Owns

- `AppConfig` + `PareEnvironment` — immutable runtime config injected at the
  composition root (DEP-R06), never hard-coded in widgets.
- `SupabaseBootstrap` — idempotent `Supabase.initialize` using the anon key
  only (SUP-R02); `reset()` test seam.
- `buildDio` — Dio with 15s timeouts, bearer token injection, dev-only request
  logging via an injected callback (no `print`), and bounded retry of
  idempotent GET/HEAD failures.
- `mapDioException` — maps `DioException` to the typed `pare_core` exception
  hierarchy (`PareAuthException`, `PareServerException`, ...).

## Boundaries

- No widgets, no business decisions.
- Depends on `pare_core` and `pare_util`; knows nothing about feature packages
  or apps.

## Tests

`flutter test` — exception mapping matrix, config/env behaviour, Dio defaults
and bearer token injection.
