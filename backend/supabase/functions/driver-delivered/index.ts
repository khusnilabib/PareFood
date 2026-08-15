// driver-delivered Edge Function
// PF-DOC-14 §3.3, PF-DOC-18 §3.3 (BR-DELIVERY — photo proof, FR-ORDER-006)
//
// Driver confirms drop-off with a photo proof. Transitions the delivery to
// `delivered` and kicks off `complete-order` (commission + fare lock).
//
//   POST /functions/v1/driver-delivered
//   Headers: Authorization: Bearer <JWT> (driver), X-Idempotency-Key
//   Body:    { "delivery_id": "<uuid>", "proof_photo_url": "<url>" }
//   200 → { data: { delivery_id, order_id, status: "delivered" } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return jsonError("VALIDATION_ERROR", "Invalid JSON body"); }
  const { delivery_id, proof_photo_url } = body as { delivery_id?: unknown; proof_photo_url?: unknown };
  if (!isUuid(delivery_id)) return jsonError("VALIDATION_ERROR", "delivery_id must be a uuid", { field: "delivery_id" });
  if (typeof proof_photo_url !== "string" || !proof_photo_url.startsWith("http")) {
    return jsonError("VALIDATION_ERROR", "proof_photo_url must be a valid URL", { field: "proof_photo_url" });
  }

  // --- Dry-run (no backing Supabase in test env) ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({ delivery_id, status: "delivered", idempotency_key: idempotency, dry_run: true });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const guard = requireRole(await resolveCaller(userClient(jwt), jwt), "driver");
  if (!guard.ok) return guard.response;
  const caller = guard.caller;

  try {
    const { data: delivery, error: de } = await svc
      .from("deliveries")
      .select("id, order_id, driver_id, status")
      .eq("id", delivery_id as string)
      .maybeSingle();
    if (de || !delivery) return jsonError("NOT_FOUND", "Delivery not found");
    if (delivery.driver_id !== caller.id) return jsonError("FORBIDDEN", "Not your delivery");
    if (delivery.status !== "picked_up") {
      return jsonError("CONFLICT", "Delivery not picked up yet", { state: delivery.status });
    }

    // BR-DELIVERY: attach photo proof, mark delivered.
    const { error: ue } = await svc
      .from("deliveries")
      .update({ status: "delivered", delivered_at: new Date().toISOString(), proof_photo_url })
      .eq("id", delivery_id as string);
    if (ue) return jsonInternal();

    // Order: picked_up → delivered
    const { error: oe } = await svc
      .from("orders")
      .update({ status: "delivered", completed_at: new Date().toISOString() })
      .eq("id", delivery.order_id)
      .eq("status", "picked_up");
    if (oe) return jsonInternal();

    await svc.from("order_status_history").insert({
      order_id: delivery.order_id,
      from_status: "picked_up",
      to_status: "delivered",
      changed_by: caller.id,
    });

    // complete-order (commission/fare lock, BR-COMM-002) is fired by a DB
    // trigger or cron; here we return the delivered status.
    return jsonOk({ delivery_id, order_id: delivery.order_id, status: "delivered" });
  } catch (err) {
    console.error("driver-delivered failure", err);
    return jsonInternal();
  }
}
export default { handler };
