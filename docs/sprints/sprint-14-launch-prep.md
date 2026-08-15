# S14 — Launch Preparation: Release Runbook + Play Store + Ops

| | |
|---|---|
| Status | Code-complete; staging cutover + store submission pending |
| Date | 2026-08-15 |
| Owner | DevOps / Product |
| References | PF-DOC-22 (deployment), PF-DOC-26 (release), PF-DOC-28 (maintenance), PF-DOC-30 (DoD) |

## 1. Release versioning

- **Version**: `0.1.0` (pilot alpha) → `0.9.0` (closed beta) → `1.0.0` (public launch).
- **Version source**: root `pubspec.yaml` → `melos run version` post-hook syncs all packages.
- **Tagging**: `git tag v0.x.y && git push --tags` triggers the release CI.

## 2. Play Store assets (per app)

### 2.1 app_parefood (customer)

| Asset | Status |
|---|---|
| App name | PareFood — Pesan Makanan |
| Short description | Pesan makanan favorit dari restoran lokal di Pare |
| Full description | [see `docs/release/play-store-parefood.md`] |
| App icon (512×512) | ⏳ Generate from `public/logo.svg` |
| Feature graphic (1024×500) | ⏳ Design |
| Phone screenshots (min 2) | ⏳ Capture from device |
| Category | Food & Drink |
| Target audience | Teen + |
| Privacy policy URL | ⏳ Host at `parefood.co/privacy` |
| Terms of service URL | ⏳ Host at `parefood.co/tos` |

### 2.2 app_parebisnis (merchant)

| Asset | Status |
|---|---|
| App name | PareBisnis — Kelola Restoran |
| Short description | Terima pesanan, kelola menu, pantau pendapatan |
| Category | Business |

### 2.3 app_paredriver (driver)

| Asset | Status |
|---|---|
| App name | PareDriver — Antar Pesanan |
| Short description | Terima tugas antar, earning harian |
| Category | Maps & Navigation |

### 2.4 app_pareadmin (admin web)

Not on Play Store — deployed as a web app at `admin.parefood.co`.

## 3. Signing & build

### 3.1 Keystore (already documented in sprint-01-android-signing.md)

- CI workflow `android-build.yml` builds a signed AAB when `ANDROID_KEYSTORE_BASE64` secret is set.
- For pilot, use debug-signed APK (installable for testing).
- For store release: release mode + signed AAB via CI.

### 3.2 Build commands

```sh
# Debug APK (testing)
flutter build apk --debug

# Release AAB (store)
flutter build appbundle --release \
  --dart-define=PARE_ENV=prod \
  --dart-define=SUPABASE_URL=$PROD_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$PROD_SUPABASE_ANON_KEY \
  --dart-define=SENTRY_DSN=$SENTRY_DSN
```

## 4. Production environment checklist

- [ ] Create production Supabase project (separate from dev).
- [ ] Run all migrations 0001–0012 on production DB.
- [ ] Set production GUCs: `app.parefood_functions_base_url`, `app.supabase_service_role_key`.
- [ ] Deploy all 16 Edge Functions to production.
- [ ] Configure PSP (Midtrans/Xendit) with production keys.
- [ ] Set CI secrets: `PROD_SUPABASE_URL`, `PROD_SUPABASE_ANON_KEY`, `SENTRY_DSN`, `PSP_WEBHOOK_SECRET`, `ANDROID_KEYSTORE_BASE64` + passwords.
- [ ] Enable pg_cron jobs: `retry-dispatch`, `settle-restaurants` (daily), `payout-drivers` (daily), `reconcile` (weekly).
- [ ] Configure Supabase Auth: enable email + phone OTP, set template to Bahasa.
- [ ] Configure Storage buckets: `merchant-docs`, `driver-docs`, `proof-photos`, `menu-images`.

## 5. Ops runbook

### 5.1 Daily checks

- [ ] Dashboard KPIs load (orders today, GMV).
- [ ] No SEV-1 errors in Sentry.
- [ ] pg_cron jobs ran (settle, payout, reconcile).
- [ ] COD remittance queue is current (no > 24h outstanding).

### 5.2 Incident response

| Severity | Response time | Action |
|---|---|---|
| SEV-1 (app down, payment failure) | 15 min | Page on-call; hotfix from `main` |
| SEV-2 (feature broken) | 2 h | Create hotfix branch; PR + review |
| SEV-3 (cosmetic) | Next sprint | Add to backlog |

### 5.3 Rollback procedure

1. Revert the merge commit on `main`: `git revert <sha>`.
2. Push → CI rebuilds + deploys the previous version.
3. For DB migrations: write a forward-fix migration (never rollback a migration — it loses data).

### 5.4 On-call rotation

- Pilot phase: single on-call (founder).
- Post-launch: 2-person rotation, weekly.

## 6. Pilot launch plan (M2 — 50 merchants)

### 6.1 Selection criteria

- Restaurants in Pare region (within 5 km delivery radius).
- Mix of cuisine types (nasi, bakso, minuman).
- Willing to provide feedback weekly.

### 6.2 Onboarding sequence

1. Provision merchant accounts (business role) server-side.
2. Onboard each restaurant via PareBisnis app (FR-ONB-001).
3. Admin activates restaurants (status: pending → active).
4. Seed menu items.
5. Enable a subset of customers (50–100) to place orders.
6. Monitor for 2 weeks; collect feedback; iterate.

### 6.3 Success metrics (M2 exit gate)

- ≥ 40 merchants active daily.
- ≥ 200 orders/day.
- Crash-free rate ≥ 99.5%.
- Average delivery time ≤ 35 min.
- Merchant NPS ≥ 40.

## 7. Privacy policy + ToS

- Privacy policy and ToS must be hosted at a public URL before Play Store submission.
- Template: `docs/release/privacy-policy-template.md` (to be reviewed by legal).
- Must cover: data collected (phone, email, location, payment), retention, third-party processors (Supabase, PSP, Sentry).

## 8. Final launch checklist (M3 — public)

- [ ] All M2 success metrics met.
- [ ] Production Supabase stable for 7 days (no SEV-1).
- [ ] All 4 apps pass CI (format + analyze + test) on `main`.
- [ ] Signed release AAB produced via CI.
- [ ] Play Store listing complete (description, screenshots, icons).
- [ ] Privacy policy + ToS published.
- [ ] Support email + phone configured.
- [ ] Crash reporting (Sentry) confirmed receiving events.
- [ ] pg_cron jobs verified on production.
- [ ] PSP production cutover complete (sandbox → prod keys).
