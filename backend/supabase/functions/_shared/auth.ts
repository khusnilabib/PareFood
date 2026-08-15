// _shared/auth.ts
// Caller identity + role verification (PF-DOC-19 §3.2, PF-DOC-14 §3.3).
//
// The role claim is mirrored into the JWT app_metadata by the
// `sync_role_claim()` DB trigger (migration 0001, PF-DOC-12 §3.2), so
// `auth.getUser(jwt).data.user.app_metadata.role` is the source of truth for
// the effective role used by app guards (requireRole).

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { jsonError } from "./errors.ts";

export type Role = "customer" | "business" | "driver" | "admin";

export interface Caller {
  id: string;
  role: Role;
}

/**
 * Resolve the caller from their JWT. Returns null when the user client is
 * unavailable (dry-run/test env) so the function can fall back to validation-only.
 */
export async function resolveCaller(
  client: SupabaseClient | null,
  jwt: string | null,
): Promise<Caller | null> {
  if (!client || !jwt) return null;
  const { data, error } = await client.auth.getUser(jwt);
  if (error || !data?.user) return null;
  const role = (data.user.app_metadata?.role ?? data.user.user_metadata?.role ?? "") as Role;
  if (!role) return null;
  return { id: data.user.id, role };
}

/** Reject if the caller is missing, unauthenticated, or lacks one of `roles`. */
export function requireRole(
  caller: Caller | null,
  ...roles: Role[]
): { ok: true; caller: Caller } | { ok: false; response: Response } {
  if (!caller) {
    return {
      ok: false,
      response: jsonError("UNAUTHENTICATED", "Authentication required"),
    };
  }
  if (!roles.includes(caller.role)) {
    return {
      ok: false,
      response: jsonError("FORBIDDEN", "Role not permitted for this operation"),
    };
  }
  return { ok: true, caller };
}

/** Validate UUID v4 shape without importing a uuid lib (NFR-013). */
export function isUuid(v: unknown): v is string {
  return typeof v === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(v);
}
