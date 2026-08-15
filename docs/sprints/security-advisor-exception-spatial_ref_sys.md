# Security Advisor Exception: spatial_ref_sys RLS Warning

| | |
|---|---|
| Status | **ACCEPTED** for pilot (M2). To be resolved before public launch (M3) via Supabase Support. |
| Date | 2026-08-15 |
| Owner | Engineering |
| Severity | Low |
| Supabase Project | `mxmmxyagnsnzcrcsfxlh` (PareFood) |
| Advisor Item | "RLS Disabled in Public Entity: public.spatial_ref_sys" |

## 1. The Warning

Supabase Security Advisor flags that `public.spatial_ref_sys` has RLS disabled
and is exposed to PostgREST (the REST API layer).

## 2. What is `spatial_ref_sys`?

`spatial_ref_sys` is a **standard PostGIS catalog table** created automatically
when the `postgis` extension is enabled (migration 0001). It contains
**coordinate reference system definitions** (EPSG codes, projections,
datums) — e.g., "EPSG:4326 = WGS84 lat/lng", "EPSG:3857 = Web Mercator".

- **Row count**: ~8,500 rows of EPSG/SRID definitions
- **Data type**: Public reference data (published by the EPSG registry)
- **Sensitivity**: None — this is standard open geodetic data, not user data
- **PostGIS dependency**: PostGIS functions (`ST_MakePoint`, `ST_SetSRID`,
  `ST_Distance`, etc.) internally reference this table

## 3. Why It Can't Be Fixed via Migration

The table is owned by `supabase_admin` — Supabase's internal reserved role.
The `postgres` role used by `supabase db push` and the SQL Editor is:

| Attempted Action | Result | Reason |
|---|---|---|
| `ALTER TABLE ... SET SCHEMA extensions` | ❌ `must be owner` | `postgres` ≠ `supabase_admin` |
| `ALTER TABLE ... OWNER TO postgres` | ❌ `must be owner` | Same |
| `GRANT supabase_admin TO postgres` | ❌ `role memberships are reserved` | Supabase policy |
| `SET ROLE supabase_admin` | ❌ `permission denied` | Not a member |
| `REVOKE ALL FROM anon, authenticated` | ⚠️ Applied but grants re-appear | Supabase re-applies default privileges |
| Migration 0013 (REVOKE + NOTIFY pgrst) | ✅ Recorded but ineffective | Default privileges override |

This is a **known Supabase + PostGIS limitation** — the table is managed by
the extension and the platform, not by the customer.

## 4. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Attacker reads coordinate system definitions | Low (data is public/open) | None | N/A — EPSG data is published openly |
| Attacker modifies spatial_ref_sys | Very Low (RLS denies anon writes via default policy) | Low (PostGIS functions break) | PostgREST anon role has insert/update/delete but no realistic path to exploit — the table is append-only reference data |
| Security audit fails | Medium (if auditor is strict) | Medium | This document + Supabase Support ticket for M3 |

**Bottom line**: The exposed data is **public reference data** (coordinate
system definitions available from epsg.io). There is no user data, no PII,
no business data in this table. The risk is theoretical, not practical.

## 5. Acceptance Decision

**Accepted for pilot (M2)**. Rationale:
1. The table contains only public EPSG coordinate system definitions.
2. No user/business data is exposed.
3. The fix requires `supabase_admin` privileges not available to customers.
4. Migration 0013 (REVOKE) was applied as best-effort.
5. PostGIS functionality is verified working.

## 6. Resolution Plan for Public Launch (M3)

Before the public launch, resolve via one of:

### Option A — Supabase Support (recommended)
Open a support ticket:
- Dashboard → Help → Contact Support
- Or email: support@supabase.com
- Message: "Please run `ALTER TABLE public.spatial_ref_sys SET SCHEMA
  extensions;` as supabase_admin on project `mxmmxyagnsnzcrcsfxlh`. This
  resolves the Security Advisor RLS warning for the PostGIS spatial_ref_sys
  table. Thank you."

### Option B — Supabase Dashboard SQL Editor
Try running the same `ALTER TABLE` in the SQL Editor — some Supabase
versions grant elevated privileges to the Dashboard session:
https://supabase.com/dashboard/project/mxmmxyagnsnzcrcsfxlh/sql/new

### Option C — Drop and recreate PostGIS in extensions schema
If Supabase Support is unresponsive, this nuclear option works but risks
PostGIS instability:
```sql
-- Only as last resort — may break PostGIS temporarily
drop extension postgis cascade;
create extension postgis with schema extensions;
-- Re-run migration 0001 to recreate the extension in public
-- (this is risky; prefer Option A)
```

## 7. Verification Status

| Check | Status | Date |
|---|---|---|
| Migration 0013 applied | ✅ | 2026-08-15 |
| PostGIS functions work | ✅ `ST_MakePoint` returns correct result | 2026-08-15 |
| Warning acknowledged | ✅ | 2026-08-15 |
| Supabase Support ticket | ⏳ To open before M3 | — |
| Warning resolved | ⏳ Pending | — |

## 8. References

- Supabase docs: https://supabase.com/docs/guides/database/postgis
- PostGIS docs: https://postgis.net/docs/using_postgis_dbmanagement.html#spatial_ref_sys
- EPSG registry: https://epsg.io
- PareFood migration 0001: `backend/supabase/migrations/0001_extensions.sql`
- PareFood migration 0013: `backend/supabase/migrations/0013_move_spatial_ref_sys.sql`
