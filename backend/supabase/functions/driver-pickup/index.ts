// driver-pickup Edge Function
// PF-DOC-14 §3.3, PF-DOC-18 §3.3 (BR-PICKUP)
//
// Driver confirms pickup with the 4-digit code (FR-ORDER-005). Verifies the
// code server-side (never trusts the client). Transitions the order
// ready → picked_up and the delivery assigned → picked_up.
//
//   POST /functions/v1/driver-pickup
//   Headers: Authorization: Bearer <JWT> (driver), X-Idempotency-Key
//   Body:    { "delivery_id": "<uuid>", "pickup_code": "1234" }
//   200 → { data: { delivery_id, order_id, status: "picked_up" } }
//   400 → BUSINESS_RULE_VIOLATION (wrong code) | VALIDATION_ERROR
//   409 → CONFLICT (already picked up)

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return jsonError("VALIDATION_ERROR", "Invalid JSON body"); }
  const { delivery_id, pickup_code } = body as { delivery_id?: unknown; pickup_code?: unknown };
  if (!isUuid(delivery_id)) return jsonError("VALIDATION_ERROR", "delivery_id must be a uuid", { field: "delivery_id" });
  if (typeof pickup_code !== "string" || !/^\d{4}$/.test(pickup_code)) {
    return jsonError("VALIDATION_ERROR", "pickup_code must be 4 digits", { field: "pickup_code" });
  }

  // --- Dry-run (no backing Supabase in test env) ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({ delivery_id, status: "picked_up", idempotency_key: idempotency, dry_run: true });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const guard = requireRole(await resolveCaller(userClient(jwt), jwt), "driver");
  if (!guard.ok) return guard.response;
  const caller = guard.caller;

  try {
    const { data: delivery, error: de } = await svc
      .from("deliveries")
      .select("id, order_id, driver_id, pickup_code, status")
      .eq("id", delivery_id as string)
      .maybeSingle();
    if (de || !delivery) return jsonError("NOT_FOUND", "Delivery not found");
    if (delivery.driver_id !== caller.id) return jsonError("FORBIDDEN", "Not your delivery");
    if (delivery.status !== "assigned" && delivery.status !== "arrived_pickup") {
      return jsonError("CONFLICT", "Delivery not in a pickup-able state", { state: delivery.status });
    }
    // BR-PICKUP: verify code server-side.
    if (delivery.pickup_code !== pickup_code) {
      return jsonError("BUSINESS_RULE_VIOLATION", "Pickup code salah", { rule: "BR-PICKUP" });
    }

    const { error: ue } = await svc
      .from("deliveries")
      .update({ status: "picked_up", picked_up_at: new Date().toISOString() })
      .eq("id", delivery_id as string);
    if (ue) return jsonInternal();

    // Order: ready → picked_up
    const { error: oe } = await svc
      .from("orders")
      .update({ status: "picked_up" })
      .eq("id", delivery.order_id)
      .in("status", ["ready"]);
    if (oe) return jsonInternal();

    await svc.from("order_status_history").insert({
      order_id: delivery.order_id,
      from_status: "ready",
      to_status: "picked_up",
      changed_by: caller.id,
    });

    return jsonOk({ delivery_id, order_id: delivery.order_id, status: "picked_up" });
  } catch (err) {
    console.error("driver-pickup failure", err);
    return jsonInternal();
  }
}
export default { handler };
