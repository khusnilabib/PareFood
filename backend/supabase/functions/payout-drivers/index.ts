// payout-drivers Edge Function (cron)
// PF-DOC-14 §3.3, PF-DOC-18 §3.2 (BR-PAYOUT-001: daily payout to wallet)
//
// Aggregates completed deliveries per driver for the previous day and creates
// payout rows + credits the driver wallet. Called daily by pg_cron.
// Idempotent per (driver_id, period_date) via unique constraint.
//
//   POST /functions/v1/payout-drivers
//   Headers: X-Idempotency-Key (internal cron call)
//   Body:    { "date"?: "YYYY-MM-DD" }  (default: yesterday)
//   200 → { data: { payouts_created, total_paid, period_date } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) {
    return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });
  }

  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch { /* empty body is fine for cron */ }
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  const periodDate = typeof body.date === "string" ? body.date : yesterday;

  const svc = serviceClient();
  if (!svc) {
    return jsonOk({
      payouts_created: 0,
      total_paid: 0,
      period_date: periodDate,
      idempotency_key: idempotency,
      dry_run: true,
    });
  }

  try {
    // Fetch completed deliveries for the period, grouped by driver.
    const { data: deliveries, error: de } = await svc
      .from("deliveries")
      .select("id, driver_id, orders(delivery_fee)")
      .eq("status", "delivered")
      .not("driver_id", "is", null)
      .gte("delivered_at", periodDate + "T00:00:00")
      .lte("delivered_at", periodDate + "T23:59:59");

    if (de) return jsonInternal();

    const byDriver = new Map<string, { fare: number; count: number }>();
    for (const d of deliveries ?? []) {
      const did = d.driver_id as string;
      if (!byDriver.has(did)) {
        byDriver.set(did, { fare: 0, count: 0 });
      }
      const entry = byDriver.get(did)!;
      const order = d.orders as { delivery_fee?: number } | null;
      entry.fare += order?.delivery_fee ?? 0;
      entry.count += 1;
    }

    let created = 0;
    let totalPaid = 0;

    for (const [driverId, entry] of byDriver) {
      if (entry.fare <= 0) continue;

      // Create payout row (idempotent via unique constraint).
      const { data: payout, error: pe } = await svc
        .from("payouts")
        .upsert({
          driver_id: driverId,
          period_date: periodDate,
          amount: entry.fare,
          delivery_count: entry.count,
          status: "completed",
        }, { onConflict: "driver_id,period_date" })
        .select("id")
        .single();

      if (pe) {
        console.error("payout upsert failed for driver", driverId, pe);
        continue;
      }

      // Credit the driver wallet (BR-COMM-003: 100% of delivery fee).
      const { data: wallet } = await svc
        .from("wallets")
        .select("id")
        .eq("user_id", driverId)
        .maybeSingle();

      if (wallet) {
        const { data: tx } = await svc.from("wallet_transactions").insert({
          wallet_id: wallet.id,
          tx_type: "credit",
          reason: "daily_payout",
          amount: entry.fare,
          reference_id: payout.id,
          status: "completed",
        }).select("id").single();

        // Link the wallet tx to the payout.
        if (tx) {
          await svc.from("payouts").update({ wallet_tx_id: tx.id }).eq("id", payout.id);
        }
      }

      created += 1;
      totalPaid += entry.fare;
    }

    return jsonOk({
      payouts_created: created,
      total_paid: totalPaid,
      period_date: periodDate,
      drivers_processed: byDriver.size,
    });
  } catch (err) {
    console.error("payout-drivers failure", err);
    return jsonInternal();
  }
}

export default { handler };
