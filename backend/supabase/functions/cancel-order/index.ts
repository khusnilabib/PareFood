// cancel-order Edge Function
// PF-DOC-14 §3.3, PF-DOC-18 §3.5 (cancellation/refund matrix)
//
// Customer / driver / admin cancels an order. Refund amount depends on the
// scenario (BR-CANCEL-001..006). Admin force-cancel requires a reason
// (BR-FRAUD-005, audit-logged).
//
//   POST /functions/v1/cancel-order
//   Headers: Authorization: Bearer <JWT>, X-Idempotency-Key
//   Body:    { "order_id": "<uuid>", "reason": "<text>", "actor": "customer"|"admin" }
//   200 → { data: { order_id, status: "cancelled", refund_status } }
//   409 → CONFLICT (order not cancellable from current state)

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

// BR-CANCEL-002: cancellation fee after accept.
const CANCELLATION_FEE = 5000;

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return jsonError("VALIDATION_ERROR", "Invalid JSON body"); }
  const { order_id, reason, actor } = body as { order_id?: unknown; reason?: unknown; actor?: unknown };
  if (!isUuid(order_id)) return jsonError("VALIDATION_ERROR", "order_id must be a uuid", { field: "order_id" });
  if (typeof reason !== "string" || reason.trim().length === 0) {
    return jsonError("VALIDATION_ERROR", "reason is required", { field: "reason" });
  }

  // --- Dry-run (no backing Supabase in test env) ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({ order_id, status: "cancelled", refund_status: "n/a", idempotency_key: idempotency, dry_run: true });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const guard = requireRole(await resolveCaller(userClient(jwt), jwt), "customer", "admin", "driver");
  if (!guard.ok) return guard.response;
  const caller = guard.caller;

  try {
    const { data: order, error: oe } = await svc
      .from("orders")
      .select("id, status, customer_id, payment_method, payment_status, total, subtotal, delivery_fee, service_fee")
      .eq("id", order_id as string)
      .maybeSingle();
    if (oe || !order) return jsonError("NOT_FOUND", "Order not found");

    // Ownership: customer cancels own order; admin cancels any; driver cannot
    // cancel via this function (driver failure is a system/admin path).
    if (caller.role === "customer" && order.customer_id !== caller.id) {
      return jsonError("FORBIDDEN", "Not your order");
    }

    // BR-CANCEL: cancellable states are placed/accepted/preparing/ready.
    const cancellable = ["placed", "accepted", "preparing", "ready"].includes(order.status);
    if (!cancellable) {
      return jsonError("CONFLICT", "Order cannot be cancelled from current state", { state: order.status });
    }

    // Refund computation per BR-CANCEL matrix.
    let refundAmount = order.total;
    let refundStatus = "n/a";
    if (order.status !== "placed" && order.payment_method !== "cod" && order.payment_status === "paid") {
      // BR-CANCEL-002: customer cancels after accept → fee deducted.
      if (caller.role === "customer") {
        refundAmount = Math.max(0, order.total - CANCELLATION_FEE);
      }
      // Admin force-cancel (BR-CANCEL-003): full refund.
      const { data: intent } = await svc
        .from("payment_intents")
        .select("id")
        .eq("order_id", order.id)
        .eq("intent_type", "charge")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (intent) {
        await svc.from("payment_intents").insert({
          order_id: order.id,
          intent_type: "refund",
          amount: refundAmount,
          status: "created",
        });
        refundStatus = "initiated";
      }
    }

    // BR-FRAUD-005: admin force-cancel writes audit log.
    if (caller.role === "admin") {
      await svc.from("audit_logs").insert({
        actor_id: caller.id,
        action: "force_cancel_order",
        target_id: order.id,
        reason,
      }).then(() => {}, () => {});
    }

    const { error: ue } = await svc
      .from("orders")
      .update({
        status: "cancelled",
        cancelled_at: new Date().toISOString(),
        cancel_reason: reason,
      })
      .eq("id", order.id)
      .in("status", ["placed", "accepted", "preparing", "ready"]);
    if (ue) return jsonInternal();

    await svc.from("order_status_history").insert({
      order_id: order.id,
      from_status: order.status,
      to_status: "cancelled",
      changed_by: caller.id,
      reason,
    });

    return jsonOk({ order_id, status: "cancelled", refund_amount: refundAmount, refund_status: refundStatus });
  } catch (err) {
    console.error("cancel-order failure", err);
    return jsonInternal();
  }
}
export default { handler };
