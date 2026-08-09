# app_pareadmin

PareAdmin web console — thin composition root (MO-R06, PF-DOC-06).

Sprint 1 scope: role-guarded login (`admin` only) and a placeholder
dashboard; the admin tooling itself (merchant moderation, support, reports)
ships in Sprint 4. No business logic lives here; screens come from
`packages/features/*`, data access goes through `pare_data` (DEP-R06) and
theming through `pare_design`.

## Run

```sh
flutter run -d chrome
```

Configuration is injected with `--dart-define` (dev defaults apply when a
value is omitted, so a bare `flutter run -d chrome` works):

```sh
flutter run -d chrome \
  --dart-define=PARE_ENV=dev \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key> \
  --dart-define=API_BASE_URL=https://<project>.supabase.co/rest/v1
```

## Layout

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Bootstrap: defines → `AppConfig` → Supabase → `ProviderScope`. |
| `lib/src/config/env.dart` | Pure `--dart-define` → `AppConfig` mapping. |
| `lib/src/router/app_router.dart` | GoRouter + auth/admin-role guards (PF-DOC-17). |
| `lib/src/presentation/` | Placeholder dashboard + access-denied screens. |
| `lib/src/app.dart` | `MaterialApp.router` + `AppTheme`. |

## Tests

```sh
flutter test
```

Guard-redirect and dashboard smoke tests run hermetically against fake
repositories (TS-R06 — no network, no Supabase).
