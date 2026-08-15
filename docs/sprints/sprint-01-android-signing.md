# Sprint 01 — Android Signing & Release Prep

| | |
|---|---|
| Status | Checklist + CI workflow added — secrets to be provisioned by DevOps |
| Date | 2026-08-15 |
| Owner | DevOps (0.5 FTE, PF-DOC-25 §3.1) |
| References | PF-DOC-21 (CI/CD), PF-DOC-22 (deployment), PF-DOC-19 (secrets), PF-DOC-30 (DoD release), sprint-01-todos task 12 |

## 1. Purpose

Close sprint-01-todos task 12 ("Document keystore process. Configure CI to build
signed AAB using secrets — do NOT commit keystores"). The CI workflow
`.github/workflows/android-build.yml` is added; this file documents the one-time
secret provisioning and the per-release checklist.

## 2. CI workflow

`android-build.yml` builds a signed release AAB for the mobile apps
(`parefood`, `parebisnis`, `paredriver`). It:

- runs on push to `main` (default: build `parefood`) and on manual dispatch
  (choose one app or `all`);
- sets up Java 17 + Flutter via FVM (matches `.fvmrc`, CI-R06) + Melos;
- runs `format` + `analyze` (lightweight pre-build gate — the full `melos run
  check` is in `pr-validation`, to be added as a separate workflow);
- decodes the keystore from the `ANDROID_KEYSTORE_BASE64` secret;
- builds `flutter build aab --release` with `--dart-define` staging env vars;
- uploads the AAB as a 14-day-retention artifact.

If the keystore secret is absent, it falls back to a debug AAB with a warning,
so the workflow is usable before secrets are provisioned.

## 3. Required repository secrets (provision once)

Add these under **Settings → Secrets and variables → Actions**:

| Secret | Purpose | Rotation |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | The `.keystore` (or `.jks`), base64-encoded | On compromise or annual |
| `ANDROID_STORE_PASSWORD` | Keystore password | With keystore |
| `ANDROID_KEY_PASSWORD` | Key entry password | With keystore |
| `ANDROID_KEY_ALIAS` | Key alias name | With keystore |
| `STAGING_SUPABASE_URL` | Staging project URL (dart-define) | On env change |
| `STAGING_SUPABASE_ANON_KEY` | Staging anon key (dart-define) | On key rotation |

> **Never** commit keystores, `key.properties`, or any secret to the repo
> (PF-DOC-19). The `.gitignore` already excludes `*.keystore`, `*.jks`,
> `key.properties` (verify before first release).

## 4. One-time keystore creation (DevOps runbook)

```sh
# 1. Generate a production keystore (4096-bit RSA, 25-year validity)
keytool -genkey -v -keystore parefood-release.keystore \
  -alias parefood -keyalg RSA -keysize 4096 -validity 9125 \
  -dname "CN=PareFood, O=PareFood Inc, C=ID"

# 2. Base64-encode it for the GitHub secret
base64 -w 0 parefood-release.keystore > keystore.b64
# Paste keystore.b64 into the ANDROID_KEYSTORE_BASE64 secret.

# 3. Securely back up the original .keystore OFFLINE (password manager / KMS).
#    Loss of this keystore means Play Store signing key rotation is required
#    (PF-DOC-22 §release). NEVER delete it.
```

## 5. Play Store upload key (production hardening — S14)

For store submission (S14, PF-DOC-26), use Play App Signing: opt in to
Google-managed app signing keys and use the upload key (the keystore above) only
for signing uploads. This is configured in the Play Console, not in CI. Defer
to S14 launch prep.

## 6. Per-release checklist (PF-DOC-30 release gate)

- [ ] `main` is green: `pr-validation` + `db-tests` + `android-build` all pass.
- [ ] Version bumped in root `pubspec.yaml` (`melos run version` post-hook runs
      `tool/scripts/sync_version.dart`).
- [ ] Changelog fragment drafted (PF-DOC-26).
- [ ] Manual smoke: install the AAB on a physical device, run auth + place-order
      flow against staging.
- [ ] Tag the release: `git tag v0.x.y && git push --tags`.

## 7. Follow-ups (not blocking S1 closure)

- Add the full `pr-validation` workflow (format + analyze + deps-check + test +
  codegen diff + coverage) — currently only `db-tests` and `android-build`
  exist. This is the largest remaining CI gap; target early S2.
- Add affected-package detection (sprint-01-todos task 10) to keep CI fast once
  the package count grows.
