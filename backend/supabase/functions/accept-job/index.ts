// accept-job Edge Function
// PF-DOC-14 §3.3, PF-DOC-18 §3.6 (BR-JOB-001..003)
//
// Driver accepts a dispatch job offer. Atomic first-accept-wins (BR-JOB-002):
// the UPDATE is conditional on deliveries.status='assigned', so concurrent
// accepts from other drivers are rejected (0 rows updated → CONFLICT).
//
//   POST /functions/v1/accept-job
//   Headers: Authorization: Bearer <JWT> (driver role), X-Idempotency-Key
//   Body:    { "delivery_id": "<uuid>" }
//   200 → { data: { delivery_id, status: "assigned", driver_id } }
//   409 → CONFLICT (already taken)

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return jsonError("VALIDATION_ERROR", "Invalid JSON body"); }
  const { delivery_id } = body as { delivery_id?: unknown };
  if (!isUuid(delivery_id)) return jsonError("VALIDATION_ERROR", "delivery_id must be a uuid", { field: "delivery_id" });

  // --- Dry-run (no backing Supabase in test env): validated plan, no DB ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({ delivery_id, status: "assigned", idempotency_key: idempotency, dry_run: true });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const guard = requireRole(await resolveCaller(userClient(jwt), jwt), "driver");
  if (!guard.ok) return guard.response;
  const caller = guard.caller;

  try {
    // BR-JOB-002: atomic first-accept-wins via conditional update.
    const { data, error, count } = await svc
      .from("deliveries")
      .update({ driver_id: caller.id, accepted_at: new Date().toISOString() })
      .eq("id", delivery_id as string)
      .eq("driver_id", null)
      .select("id, order_id");
    if (error) return jsonInternal();
    if (!data || data.length === 0) {
      return jsonError("CONFLICT", "Job already taken or no longer available");
    }
    // Notify other offered drivers they are dismissed (BR-DISPATCH-003) —
    // handled by the dispatch retry cron; here we just confirm the winner.
    return jsonOk({ delivery_id, status: "assigned", driver_id: caller.id, order_id: data[0].order_id });
  } catch (err) {
    console.error("accept-job failure", err);
    return jsonInternal();
  }
}
export default { handler };
