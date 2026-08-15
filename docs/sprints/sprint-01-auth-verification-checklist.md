# Sprint 01 — Supabase Auth & JWT Claims Verification Checklist

| | |
|---|---|
| Status | Checklist — staged verification runbook for S2 |
| Date | 2026-08-15 |
| Owner | Backend / Platform |
| References | PF-DOC-12 §3.1/§3.2 (bootstrap, role claim), PF-DOC-19 §3.2 (auth), sprint-01-todos task 8, ADR 0001 |

## 1. Purpose

Close sprint-01-todos task 8 ("Verify Supabase Auth settings, JWT claims mapping
to `profiles`, phone/email flows and session persistence"). The auth_feature
package exists with unit tests, but the **end-to-end path through a real Supabase
project** has not been verified. This file is the runbook for that verification,
to be executed once a staging project is provisioned (target: start of S2).

## 2. What must be true (the contract)

Per PF-DOC-12 §3.2 and migration 0001, the role claim flows as:

```
profiles.role  ──[sync_role_claim() trigger]──▶  auth.users.raw_app_meta_data['role']
                                                        │
                                                        ▼
                                              JWT app_metadata.role
                                                        │
                                                        ▼
                            Edge Function resolveCaller() / app guard requireRole()
```

- `profiles.role` is the source of truth (CHECK in customer/business/driver/admin).
- The `sync_role_claim()` trigger (0001) mirrors it into `raw_app_meta_data` on
  profile insert/update. The trigger is attached in migration 0002.
- Supabase issues the JWT with `app_metadata` included, so
  `auth.getUser(jwt).data.user.app_metadata.role` returns the effective role.
- Edge Functions use this via `_shared/auth.ts → resolveCaller()` (ADR 0001).

## 3. Staged verification steps

Execute against a **local** Supabase first (`supabase start`), then repeat on
**staging**. Each step must pass before proceeding.

### 3.1 Bootstrap & migrations
- [ ] `cd backend/supabase && supabase start` succeeds; `supabase db reset` applies
      migrations 0001–0009 cleanly (including the new dispatch trigger).
- [ ] `supabase test db` (pgTAP) is green, including `01_profiles_test.sql`.
- [ ] Confirm the `sync_role_claim()` trigger exists on `profiles`:
      `\d+ public.profiles` in psql shows the `after insert or update` trigger.

### 3.2 Signup → role assignment
- [ ] Create a customer via the Supabase Auth admin API (email + password).
      Verify a `profiles` row is auto-created with `role='customer'`.
- [ ] Manually insert a `business` profile (or use the seed) and confirm
      `auth.users.raw_app_meta_data->>'role'` equals `'business'` after the
      trigger fires.
- [ ] Update a profile's role to `admin`; confirm the JWT `app_metadata.role`
      reflects `admin` on the next token issuance (re-login required — JWTs are
      immutable until refreshed).

### 3.3 Session persistence
- [ ] AP-PF / AP-PB / AP-PD `main.dart` bootstrap reads `SUPABASE_URL` +
      `SUPABASE_ANON_KEY` via `--dart-define` (PF-DOC-12 §3.1) and calls
      `SupabaseBootstrap.initialize`.
- [ ] After login, kill and relaunch the app; the session is restored from the
      persistent store (Supabase SDK persists the refresh token).
- [ ] Logout invalidates the token; a protected route redirects to `/login`
      (requireAuth guard) — verified by the app router widget tests.

### 3.4 Edge Function role guard
- [ ] With a `business` JWT, call `POST /functions/v1/accept-order` (dry-run, no
      DB) → expect `200` with `dry_run: true` (auth passes, no service client).
      This proves `resolveCaller` + `requireRole` accept a valid business JWT.
- [ ] With a `customer` JWT, call the same endpoint → expect `403 FORBIDDEN`
      (`requireRole` rejects non-business/admin).
- [ ] With no/empty Authorization header and a service client present → expect
      `401 UNAUTHENTICATED`.
- [ ] With an `admin` JWT → expect `200` (admin bypasses ownership, per ADR 0001).

### 3.5 Phone OTP (FR-AUTH-001)
- [ ] Enable phone auth in the Supabase dashboard (staging).
- [ ] Send an OTP to a test number; confirm delivery and verify code.
- [ ] Confirm the resulting JWT carries `app_metadata.role` (the profile is
      created via trigger with default `customer`).

## 4. Exit criteria

All checkboxes green on **staging**. The auth_feature unit tests remain green
locally. The `accept-order` / `ready-order` dry-run tests remain green. This
checklist is then referenced from `sprint-02-plan.md` as the auth-readiness gate.

## 5. Known follow-ups (not blocking S1 closure)

- iOS platform folders not yet scaffolded (PF-DOC-25 §3.3 follow-up).
- Deep links deferred (NV-R01).
- `user_roles` multi-role table is post-MVP (FR-AUTH-006); current single-role
  `profiles.role` is sufficient for MVP.
