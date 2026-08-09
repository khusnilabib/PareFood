# Contributing to PareFood

This guide operationalises PF-DOC-24 (Git Workflow) and PF-DOC-23 §3.10 (Code Review).
Everyone contributing code agrees to the Definition of Done in PF-DOC-30.

## Branching (trunk-based, PF-DOC-24 §3.1)

- `main` is protected: PR required, ≥ 1 approval (2 for money/privileged code, CI-R07),
  all `pr-validation` checks green, squash-merge only.
- Work on short-lived branches:
  - `feat/<pf-XXX>-<slug>` — feature work (≤ 3 days)
  - `fix/<slug>` — bug fixes
  - `chore/<slug>` — tooling, docs, deps
  - `hotfix/<slug>` — emergency fixes from `main`
- Rebase onto latest `main` before merging. Delete branches after merge.

## Commits (Conventional Commits, GW-R02)

Format: `<type>(<scope>): <subject>`

| Type | Use |
|---|---|
| `feat` | New FR/feature |
| `fix` | Bug fix |
| `chore` | Tooling/deps |
| `refactor` | No behaviour change |
| `docs` | Docs only |
| `test` | Tests only |
| `ci` | Pipeline changes |
| `perf` | Performance |

Scope = package/app/area. The body explains **why** and references issue/FR/BR IDs.
Breaking changes are marked `BREAKING CHANGE:` in the footer.

## Pull requests

1. Create a PR against `main` using the [template](.github/pull_request_template.md).
2. Self-review: run `melos run check` locally (format, analyze, deps-check, test) and
   `melos run codegen` to confirm generated code is current (FL-R06).
3. CI runs the full `pr-validation` pipeline (PF-DOC-21 §3.2).
4. Review checklist (PF-DOC-23 §3.10): security, BR/FR traceability, tests, UI states
   (loading/error/empty/data), i18n, no hard-coded tokens/strings/colours.
5. Keep PRs ≤ 400 changed lines; split larger work.
6. Squash-merge; the PR description becomes the commit body.

## Coding standards (PF-DOC-23)

- `dart format` is the only formatter; `dart analyze` must be clean (0 errors, 0 new
  warnings) — enforced by `melos run check` and CI (CS-R01).
- Follow the package boundaries in PF-DOC-10 §3.2. `melos run deps-check` fails on
  violations (CS-R02, MO-R02).
- Generated code (Freezed) is committed and CI-verified identical (FL-R06, CS-R03).
- No `print`, no naked `TODO`, no emojis in comments (CS-R05). Public API needs doc
  comments; business logic references BR/FR IDs (CS-R06).
- Every screen handles all four states (loading / error / empty / data) — FL-R07.

## Secrets (GW-R06)

Secrets never enter the repository. Use GitHub Secrets for CI, Supabase project secrets for
Edge Functions, and `--dart-define`/runtime config for apps. If you suspect a secret was
committed, rotate it and contact the DevOps team immediately.

## Reviewing

- Approve only when the DoD checklist is satisfied (PF-DOC-30 §3.2).
- Money/privileged paths require a second approval and a security review (CI-R07).
- Stale reviews are dismissed on rebase; re-review after changes.

## Getting help

- Open an issue with the appropriate template (bug / feature / tech-debt).
- Ask in the platform `#engineering` channel before large refactors or stack changes —
  new technologies require an ADR signed by the Principal Architect (TS-R01).
