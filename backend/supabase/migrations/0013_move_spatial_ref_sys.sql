-- 0013_move_spatial_ref_sys.sql
-- S12 security fix: hide PostGIS spatial_ref_sys from PostgREST.
--
-- NOTE: The ideal fix is `ALTER TABLE public.spatial_ref_sys SET SCHEMA
-- extensions`, but the table is owned by `supabase_admin` (Supabase's
-- internal reserved role) and the `postgres` role used by migrations is
-- neither the owner nor a superuser. This migration uses the alternative
-- approach: REVOKE all grants from API roles + reload PostgREST so the
-- table is no longer accessible via the REST API.
--
-- If the REVOKE does not take effect (grants may be re-applied by Supabase's
-- default privileges), contact Supabase support to run the ALTER TABLE as
-- supabase_admin, or accept the Security Advisor warning (the table only
-- contains coordinate system definitions, not sensitive data).

-- Revoke all API-role access to spatial_ref_sys.
revoke all on public.spatial_ref_sys from anon;
revoke all on public.spatial_ref_sys from authenticated;

-- Reload PostgREST schema cache so the revocation takes effect immediately.
notify pgrst, 'reload schema';

-- end migration
