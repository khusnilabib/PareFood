// _shared/supabase.ts
// Lazy Supabase client creation for Edge Functions (PF-DOC-12, PF-DOC-14 §3.5).
//
// Two clients:
//  - createServiceClient(): bypasses RLS using the service-role key. Used by
//    money/state mutations (API-R01) where the function owns the write authority.
//  - createUserClient(jwt): scoped to the caller's RLS / JWT. Used to verify the
//    caller's identity and role via auth.getUser() (PF-DOC-19 §3.2).
//
// Env:
//   SUPABASE_URL              — project API base url
//   SUPABASE_SERVICE_ROLE_KEY — service role key (server only, never shipped to client)
//   SUPABASE_ANON_KEY         — anon key (used as fallback for user client)
//
// When env vars are absent (e.g. unit tests without a backing project) the
// factory returns null; callers must treat that as "dry-run" mode and skip DB
// side-effects. This keeps `deno test` hermetic (TS-R06, no network).

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export function serviceClient(): SupabaseClient | null {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return null;
  return createClient(url, key, { auth: { persistSession: false } });
}

export function userClient(jwt: string | null): SupabaseClient | null {
  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !anon || !jwt) return null;
  return createClient(url, anon, {
    auth: { persistSession: false },
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
}

export function getBearer(req: Request): string | null {
  const h = req.headers.get("authorization") ?? req.headers.get("Authorization");
  if (!h) return null;
  const m = h.match(/^Bearer\s+(.+)$/i);
  return m ? m[1] : null;
}
