# Sprint 01 — Tasks (Foundations)

Status: Draft — tasks created by automation on 2026-08-09

This file lists the Sprint 1 actionable todos, owners (TBD), and acceptance criteria.

## Overview
Goal: bootstrap monorepo toolchain, CI quality gates, core DB migrations & RLS tests, and Edge Function skeletons so Phase 1 implementation can begin.

## Tasks

1. Bootstrapping toolchain (s1-toolchain-bootstrap)
   - Owner: TBD
   - Description: Install FVM, activate Melos, run `melos bootstrap`, verify `.fvmrc` and `melos.yaml`, ensure developers can run `melos run check` locally.
   - Acceptance: `melos bootstrap` completes, `melos run check` passes on a clean branch (format/analyze minimal).

2. Create PR validation CI workflow (s1-ci-config)
   - Owner: TBD
   - Description: Add GitHub Actions `pr-validation` workflow: setup FVM, install melos, `melos bootstrap`, format/analyze, codegen diff, unit/widget tests, coverage, golden, backend RLS tests, security scans.
   - Acceptance: PR run completes within target time and enforces gates from PF-DOC-21.

3. Codegen CI & baseline (s1-codegen)
   - Owner: TBD
   - Description: Run `melos run codegen`, commit or configure CI diff-check for generated files; fix generator errors.
   - Acceptance: codegen step leaves working tree clean or CI fails clearly with instructions.

4. Enforce format & analyze (s1-format-analyze)
   - Owner: TBD
   - Description: Ensure `melos run format` and `melos run analyze` are part of CI; provide `melos run format:fix` guidance for devs.
   - Acceptance: `melos run format` no-op on formatted repo; `dart analyze` returns 0 errors in CI.

5. Finalize DB migrations (s1-db-migrations)
   - Owner: TBD
   - Description: Review `backend/supabase/migrations/` for completeness vs PF-DOC-13; add missing constraints, indexes, and money conventions.
   - Acceptance: Migrations apply cleanly to staging DB; migration tests pass.

6. Implement RLS & policy tests (s1-rls-tests)
   - Owner: TBD
   - Description: Add SQL tests (pgTAP or SQL scripts) validating RLS for critical tables (profiles, orders, driver_locations, wallets). Integrate into CI.
   - Acceptance: RLS tests run in CI and block merges on failure.

7. Scaffold Edge Functions (s1-edge-functions-skeleton)
   - Owner: TBD
   - Description: Create function skeletons: place-order, accept-order, ready-order, dispatch, process-payment, webhook-psp. Add idempotency helper and basic tests.
   - Acceptance: `deno test` or function unit tests run; functions compile and basic flows executed locally.

8. Supabase Auth & profiles mapping (s1-auth-setup)
   - Owner: TBD
   - Description: Verify Supabase Auth settings, JWT claims mapping to `profiles` table, phone/email flows and session persistence. Add auth-stream provider tests.
   - Acceptance: Auth flows work in dev/staging; `authStateProvider` tests pass.

9. Testing baseline & coverage gates (s1-testing-setup)
   - Owner: TBD
   - Description: Configure coverage collection, set baseline targets, wire coverage reporting into PR checks.
   - Acceptance: Coverage report produced and gate enforced for core packages.

10. Affected-package detection (s1-ci-affected-detection)
    - Owner: TBD
    - Description: Implement changed-files→packages detection so CI runs only affected packages + dependents.
    - Acceptance: CI demonstrates reduced run-set for a sample change.

11. ADRs & sprint docs (s1-docs-adr)
    - Owner: TBD
    - Description: Finalize ADRs for any unresolved design decisions; update sprint plan and DoD references.
    - Acceptance: ADR files created/updated; sprint docs point to these ADRs.

12. Android signing & release prep (s1-release-setup)
    - Owner: TBD (DevOps)
    - Description: Document keystore process. Configure CI to build signed AAB using secrets (do NOT commit keystores to repo). Create release checklist per PF-DOC-30.
    - Acceptance: CI can produce a signed AAB on `ci-main` using repository secrets.

---

Notes:
- Owners should be assigned and PRs created for each task. Keep changes small and reviewable.
- Secrets and keystores MUST NOT be committed. Use GitHub Secrets / secret manager.

