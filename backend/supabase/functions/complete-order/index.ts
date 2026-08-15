// complete-order Edge Function (internal)
// PF-DOC-14 §3.3, PF-DOC-18 §3.2 (BR-COMM-002, BR-FARE-001, BR-COD-001..003)
//
// Locks commission (restaurant) + fare (driver) for a delivered order. Called
// internally by a DB trigger on `orders.status='delivered'` or by cron.
//
//   POST /functions/v1/complete-order
//   Headers: X-Idempotency-Key (internal service call)
//   Body:    { "order_id": "<uuid>" }
//   200 → { data: { order_id, commission, driver_fare, settled: true } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { isUuid } from "../_shared/auth.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return jsonError("VALIDATION_ERROR", "Invalid JSON body"); }
  const { order_id } = body as { order_id?: unknown };
  if (!isUuid(order_id)) return jsonError("VALIDATION_ERROR", "order_id must be a uuid", { field: "order_id" });

  const svc = serviceClient();
  if (!svc) {
    return jsonOk({ order_id, settled: true, idempotency_key: idempotency, dry_run: true });
  }

  try {
    const { data: order, error: oe } = await svc
      .from("orders")
      .select("id, status, subtotal, delivery_fee, restaurant_id, driver_id, payment_method")
      .eq("id", order_id as string)
      .maybeSingle();
    if (oe || !order) return jsonError("NOT_FOUND", "Order not found");
    if (order.status !== "delivered") {
      return jsonError("CONFLICT", "Order not delivered", { state: order.status });
    }

    // BR-COMM-001: commission = subtotal × rate (per restaurant, default 15%).
    const { data: rest } = await svc
      .from("restaurants")
      .select("commission_rate_pct")
      .eq("id", order.restaurant_id)
      .maybeSingle();
    const ratePct = rest?.commission_rate_pct ?? 15;
    const commission = Math.round(order.subtotal * (ratePct / 100));
    // BR-FARE-001 / BR-COMM-003: driver receives 100% of delivery fee.
    const driverFare = order.delivery_fee;

    // Record settlement (restaurant) + payout (driver) as wallet transactions
    // in a real impl. For MVP we insert settlement + payout rows.
    if (order.restaurant_id) {
      await svc.from("settlements").insert({
        restaurant_id: order.restaurant_id,
        order_id: order.id,
        gross: order.subtotal,
        commission,
        net: order.subtotal - commission,
        status: "pending",
      }).then(() => {}, () => {});
    }

    // BR-COD-001..003: COD remittance is a separate flow (driver remits cash
    // ≤ 24h, credited after verification). Non-COD: driver fare credited now.
    if (order.driver_id && order.payment_method !== "cod") {
      const { data: wallet } = await svc
        .from("wallets")
        .select("id")
        .eq("user_id", order.driver_id)
        .maybeSingle();
      if (wallet) {
        await svc.from("wallet_transactions").insert({
          wallet_id: wallet.id,
          tx_type: "credit",
          reason: "delivery_fare",
          amount: driverFare,
          reference_id: order.id,
          status: "completed",
        }).then(() => {}, () => {});
      }
    }

    return jsonOk({ order_id, commission, driver_fare: driverFare, settled: true });
  } catch (err) {
    console.error("complete-order failure", err);
    return jsonInternal();
  }
}
export default { handler };
