# Build the Four Flutter Apps (Sprint 1 Scope)

## Context
Sprint 1 packages are done and green (13/13 suites, all coverage gates met, committed). You asked to build the apps per docs BEFORE touching Supabase migrations: `apps/parefood` (customer), `apps/parebisnis` (merchant), `apps/paredriver`, `apps/pareadmin`. All four dirs are empty. You confirmed: generate platform folders now (android for the 3 mobile apps, web for PareAdmin) and Sprint 1 features only.

Apps are thin composition roots (MO-R06): wiring features, routing, theming, env config — no business logic, no direct Supabase/Dio deps (they go through `pare_data`).

## Per-app Sprint 1 scope
| App | Shell | Screens mounted (existing feature packages) | Guards |
|---|---|---|---|
| parefood | 2-tab: Beranda, Akun | SignIn, Register, Discovery (+ internal push to Detail), Profile | requireAuth; unauthOnly on /login,/register |
| parebisnis | 3-tab: Restoran(status), Menu, Akun | SignIn, Register, MerchantOnboarding, MerchantStatus, MenuManagement, Profile | requireAuth + requireRole(business); onboarding when no restaurant |
| paredriver | 1-tab: Akun | SignIn, Register, Profile | requireAuth |
| pareadmin | web; login + placeholder dashboard | SignIn, "Konsol admin — Sprint 4" empty state | requireAuth + requireRole(admin) → /access-denied |

Sprint 2+ routes (orders/cart/checkout/search/reports/finance…) are NOT built.

## Shared architecture per app
```
apps/<app>/
  pubspec.yaml            # name: app_<app>; publish_to: none; resolution: workspace
  analysis_options.yaml   # include: ../../analysis_options.yaml
  README.md               # MO-R05
  lib/main.dart           # --dart-define -> AppConfig -> SupabaseBootstrap.initialize -> runApp
  lib/src/config/env.dart # pure fns: env strings -> AppConfig (testable)
  lib/src/router/app_router.dart  # GoRouter provider + guards
  lib/src/app.dart        # MaterialApp.router, AppTheme.light()/dark(), themeMode system
  lib/src/shell/…         # NavigationBar shell / placeholder
  test/…                  # router guard + shell smoke tests w/ ProviderScope overrides
  android/ (mobile) | web/ (pareadmin)
```
- Bootstrap (PF-DOC-12 §3.1, DEP-R06): read `PARE_ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`, `SENTRY_DSN` (dev defaults provided) → `AppConfig` → `await SupabaseBootstrap.initialize` → `runApp(ProviderScope(overrides:))`.
- Composition-root overrides: explicitly override repo providers each app uses with the feature-exported Supabase adapters.
- Routing (PF-DOC-17): one `GoRouter` per app as a Riverpod provider; `redirect` reads `authSessionProvider` (+role), `refreshListenable` re-runs on auth change; `/access-denied` + NotFound. Deep links deferred. Feature pages' existing internal `Navigator.push` keeps working under GoRouter (NV-R01 full refactor = follow-up).
- Theming: `AppTheme.light()/dark()`, `themeMode: ThemeMode.system`. Shell uses Material `NavigationBar` (PfBottomNav doesn't exist yet). UI copy Indonesian.

## Enabling package changes (small, tested)
1. auth_feature — add `role` to `AuthSession` (default `'customer'`), mapped from the DTO (already carries app_metadata.role). Needed for requireRole guards. Update tests; keep ≥75%.
2. pare_data — `parsePareEnvironment(String)` helper + test, shared by all apps.
3. tool/qa/coverage_report.dart — scan `apps/`, add target `apps: 60` (PF-DOC-20 §3.8).
4. tool/dependency_check — fix dead MO-R02e intra-app filter so app↔app deps are flagged.
5. Root pubspec.yaml — add `- apps/*` to workspace globs once first app pubspec exists.

## Execution order
1. Package changes (1–4) + tests; run affected package tests.
2. `flutter create --platforms=android --project-name app_<name> .` (3 mobile), `--platforms=web` (pareadmin); then overwrite generated pubspec/analysis_options/main/test with ours.
3. Add `apps/*` glob; `dart pub get` (adds `go_router`, resolve latest compatible).
4. Implement lib/ per app (env → router → app → shell), then tests.
5. `melos run check` (17 packages) + coverage report → apps ≥60%, other gates intact.
6. Update docs: sprint-01-plan §5/§10 note (apps wired), README Sprint Delivery status.
7. Commit (conventional): `feat(auth): mirror role claim into AuthSession`, `feat(apps): build Sprint 1 composition roots`, `chore(tooling): …`.

## Verification
- `melos run check` exit 0 (format/analyze/deps-check/test over 17 packages).
- Coverage: apps ≥60%; core ≥90, data ≥80, util ≥90, design ≥75, features ≥75 all intact.
- deps-check proves apps import no supabase_flutter/dio and no cross-app deps.
- Hermetic widget tests per app: guard redirects + shell smoke with fake repos (TS-R06, no network).

## Explicit follow-ups (not this step)
Real Supabase config (migrations after apps, per you); ARB/l10n, goldens, deep links, iOS platform folders, Sprint 2+ routes/features, NV-R01 refactor of feature-internal navigation.