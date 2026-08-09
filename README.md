# PareFood Platform

Monorepo for the PareFood food-delivery ecosystem — four Flutter apps sharing one
Supabase backend (PF-DOC-01..30 in [`docs/`](docs/README.md)).

| App | Code | Path | Notes |
|---|---|---|---|
| PareFood (customer) | AP-PF | `apps/parefood` | Android/iOS |
| PareBisnis (merchant) | AP-PB | `apps/parebisnis` | Android/iOS |
| PareDriver (driver) | AP-PD | `apps/paredriver` | Android/iOS |
| PareAdmin (admin) | AP-PA | `apps/pareadmin` | Flutter Web |

## Repository layout (PF-DOC-10 §3.1)

```
apps/                  # 4 composition-root apps (thin)
packages/              # Shared packages
  core/                #   pure domain: exceptions, value objects (pare_core)
  data/                #   repositories, Supabase/Dio sources (pare_data)
  design/              #   tokens, theme, Pf* widgets (pare_design)
  util/                #   pure helpers, validators (pare_util)
  features/            #   feature modules (auth, cart, orders, payments, notifications, profile)
backend/supabase/      # migrations, edge functions, config.toml
infra/                 # ci/, deploy/, monitor/
tool/                  # custom dev scripts + dependency-boundary checker
docs/                  # architecture documentation suite (PF-DOC-01..30)
```

## Prerequisites

- Flutter Stable **3.41.6** — use [FVM](https://fvm.app) (`.fvmrc` pins the version)
- Dart SDK 3.11.4+ (ships with Flutter)
- Melos: `dart pub global activate melos`
- Optional: [Supabase CLI](https://supabase.com/docs/guides/local-development/cli) for
  local backend work

## Getting started

```sh
# 1. Install tooling once
dart pub global activate melos

# 2. Bootstrap the workspace (wires path deps, installs all packages)
melos bootstrap

# 3. Generate code (Freezed). Generated files are committed (FL-R06).
melos run codegen

# 4. Quality gates (mirror of CI pr-validation, PF-DOC-21 §3.2)
melos run check
```

> Use `fvm flutter ...` / `fvm dart ...` for every SDK call so your local toolchain matches
> CI exactly (CI-R06).

## Melos commands

| Command | Purpose |
|---|---|
| `melos bootstrap` | Wire path dependencies, install everything |
| `melos run codegen` | Run build_runner (Freezed) across packages |
| `melos run analyze` | Strict `dart analyze` in every package (0 errors, 0 new warnings) |
| `melos run test` | `flutter test` in every package |
| `melos run format` | Check `dart format` (fail on diff) |
| `melos run format:fix` | Apply `dart format` |
| `melos run deps-check` | Enforce package boundaries (MO-R02) |
| `melos run check` | format → analyze → deps-check → test (pre-push gate) |

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) — trunk-based development, Conventional Commits,
PR lifecycle, and review rules (PF-DOC-24, PF-DOC-23 §3.10).

## Documentation

All 30 design documents live in [`docs/`](docs/README.md); architecture decisions in
[`docs/adr/`](docs/adr/). The Definition of Done (PF-DOC-30) applies to every work unit.
