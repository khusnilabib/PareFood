-- 0013_move_spatial_ref_sys.sql
-- S12 security fix: attempt to hide PostGIS spatial_ref_sys from PostgREST.
--
-- Status: ACCEPTED for pilot. See docs/sprints/security-advisor-exception-
-- spatial_ref_sys.md for the full risk assessment and resolution plan.
--
-- The table is owned by supabase_admin (reserved role). The REVOKE below is
-- best-effort; Supabase's default privilege system may re-apply grants.
-- The warning is low-risk: spatial_ref_sys contains only public EPSG
-- coordinate system definitions, not user/business data.
-- Resolution for public launch: contact Supabase Support to run the ALTER
-- TABLE as supabase_admin.

-- Revoke all API-role access to spatial_ref_sys.
revoke all on public.spatial_ref_sys from anon;
revoke all on public.spatial_ref_sys from authenticated;

-- Reload PostgREST schema cache so the revocation takes effect immediately.
notify pgrst, 'reload schema';

-- end migration
