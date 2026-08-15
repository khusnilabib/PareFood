// reconcile Edge Function (cron/finance)
// PF-DOC-14 §3.3, PF-DOC-18 §3.4 (BR-RECON, BR-COD-004)
//
// Generates a reconciliation report: COD totals vs driver remittances +
// settlement accuracy. Called weekly by cron or on-demand by finance.
//
//   POST /functions/v1/reconcile
//   Headers: X-Idempotency-Key
//   Body:    { "from"?: "ISO date", "to"?: "ISO date" }  (default: last 7 days)
//   200 → { data: { gross_order_total, commission_collected, driver_fares_paid,
//                   restaurant_settlements, cod_collected, cod_remitted,
//                   cod_outstanding, mismatch_count, is_clean } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) {
    return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });
  }

  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch { /* defaults */ }
  const now = new Date();
  const to = typeof body.to === "string" ? body.to : now.toISOString();
  const from = typeof body.from === "string"
    ? body.from
    : new Date(now.getTime() - 7 * 86400000).toISOString();

  const svc = serviceClient();
  if (!svc) {
    return jsonOk({
      gross_order_total: 0,
      commission_collected: 0,
      driver_fares_paid: 0,
      restaurant_settlements: 0,
      cod_collected: 0,
      cod_remitted: 0,
      cod_outstanding: 0,
      mismatch_count: 0,
      is_clean: true,
      period: { from, to },
      idempotency_key: idempotency,
      dry_run: true,
    });
  }

  try {
    // Aggregate delivered orders.
    const { data: orders } = await svc
      .from("orders")
      .select("total, subtotal, delivery_fee, payment_method")
      .eq("status", "delivered")
      .gte("completed_at", from)
      .lte("completed_at", to);

    let grossOrderTotal = 0;
    let commissionTotal = 0;
    let driverFareTotal = 0;
    let codCollected = 0;

    for (const o of orders ?? []) {
      const total = (o.total as number) ?? 0;
      const subtotal = (o.subtotal as number) ?? 0;
      const deliveryFee = (o.delivery_fee as number) ?? 0;
      grossOrderTotal += total;
      commissionTotal += Math.round(subtotal * 0.15); // simplified 15%
      driverFareTotal += deliveryFee;
      if (o.payment_method === "cod") {
        codCollected += total;
      }
    }

    // COD remitted.
    const { data: remittances } = await svc
      .from("wallet_transactions")
      .select("amount")
      .eq("reason", "cod_remittance")
      .eq("status", "completed")
      .gte("created_at", from)
      .lte("created_at", to);
    let codRemitted = 0;
    for (const r of remittances ?? []) {
      codRemitted += (r.amount as number) ?? 0;
    }

    // Restaurant settlements net.
    const { data: settlements } = await svc
      .from("settlements")
      .select("net_amount")
      .gte("period_end", from)
      .lte("period_start", to);
    let restaurantSettlements = 0;
    for (const s of settlements ?? []) {
      restaurantSettlements += (s.net_amount as number) ?? 0;
    }

    const codOutstanding = codCollected - codRemitted;
    const mismatchCount = codOutstanding > 0 ? 1 : 0;
    const isClean = mismatchCount === 0 && codOutstanding === 0;

    return jsonOk({
      gross_order_total: grossOrderTotal,
      commission_collected: commissionTotal,
      driver_fares_paid: driverFareTotal,
      restaurant_settlements: restaurantSettlements,
      cod_collected: codCollected,
      cod_remitted: codRemitted,
      cod_outstanding: codOutstanding,
      mismatch_count: mismatchCount,
      is_clean: isClean,
      period: { from, to },
    });
  } catch (err) {
    console.error("reconcile failure", err);
    return jsonInternal();
  }
}

export default { handler };
