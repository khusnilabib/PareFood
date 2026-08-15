// register-device-token Edge Function
// PF-DOC-14 §3.3, FR-NOTIF-005 (device token registration)
//
// Upserts a push-notification device token for the signed-in user. Never
// done via PostgREST (API-R01) so the token is validated server-side and
// the caller is authenticated.
//
//   POST /functions/v1/register-device-token
//   Headers: Authorization: Bearer <JWT>
//            X-Idempotency-Key: <uuid>
//   Body:    { "token": "<fcm/apns token>", "platform": "fcm"|"apns" }
//
//   200 → { data: { registered: true, token_id } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole } from "../_shared/auth.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) {
    return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });
  }

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch {
    return jsonError("VALIDATION_ERROR", "Invalid JSON body");
  }

  const { token, platform } = body as { token?: unknown; platform?: unknown };

  if (typeof token !== "string" || token.trim().length === 0) {
    return jsonError("VALIDATION_ERROR", "token is required", { field: "token" });
  }
  if (platform !== "fcm" && platform !== "apns") {
    return jsonError("VALIDATION_ERROR", "platform must be fcm|apns", { field: "platform" });
  }

  // --- Dry-run (no backing Supabase in test env) ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({
      registered: true,
      token_id: crypto.randomUUID(),
      idempotency_key: idempotency,
      dry_run: true,
    });
  }

  // --- Caller identity (any authenticated user) ---
  const jwt = getBearer(req);
  const guard = requireRole(
    await resolveCaller(userClient(jwt), jwt),
    "customer", "business", "driver", "admin",
  );
  if (!guard.ok) return guard.response;
  const caller = guard.caller;

  try {
    // Upsert: if the token already exists (for any user), update the user_id;
    // otherwise insert. A token is unique per device (PF-DOC-13).
    const { data, error } = await svc
      .from("device_tokens")
      .upsert({
        user_id: caller.id,
        token: token as string,
        platform: platform as string,
        updated_at: new Date().toISOString(),
      }, { onConflict: "token" })
      .select("id")
      .single();
    if (error) return jsonInternal();

    return jsonOk({ registered: true, token_id: data.id });
  } catch (err) {
    console.error("register-device-token failure", err);
    return jsonInternal();
  }
}

export default { handler };
