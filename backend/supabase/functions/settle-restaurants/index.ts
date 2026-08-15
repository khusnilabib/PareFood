// settle-restaurants Edge Function (cron)
// PF-DOC-14 §3.3, PF-DOC-18 §3.2 (BR-SETTLE-001: T+7 settlement)
//
// Aggregates delivered orders per restaurant for the period and creates/
// updates settlement rows. Called daily by pg_cron. Idempotent per period:
// re-running for the same period updates the totals, not duplicates.
//
//   POST /functions/v1/settle-restaurants
//   Headers: X-Idempotency-Key (internal cron call)
//   Body:    { "period_days"?: 7 }  (default 7; T+7 settlement window)
//   200 → { data: { settlements_created, settlements_updated, period } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";

const DEFAULT_PERIOD_DAYS = 7;

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) {
    return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });
  }

  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch { /* empty body is fine for cron */ }
  const periodDays = typeof body.period_days === "number" && body.period_days > 0
    ? body.period_days
    : DEFAULT_PERIOD_DAYS;

  const svc = serviceClient();
  if (!svc) {
    return jsonOk({
      settlements_created: 0,
      settlements_updated: 0,
      period_days: periodDays,
      idempotency_key: idempotency,
      dry_run: true,
    });
  }

  try {
    const now = new Date();
    const periodEnd = now.toISOString().slice(0, 10);
    const periodStart = new Date(now.getTime() - periodDays * 86400000).toISOString().slice(0, 10);

    // Fetch delivered orders with no settlement row yet, grouped by restaurant.
    const { data: orders, error: oe } = await svc
      .from("orders")
      .select("id, restaurant_id, subtotal, delivery_fee, total, completed_at")
      .eq("status", "delivered")
      .not("completed_at", "is", null)
      .gte("completed_at", periodStart)
      .lte("completed_at", periodEnd + "T23:59:59");

    if (oe) return jsonInternal();

    // Group by restaurant.
    const byRestaurant = new Map<string, { gross: number; count: number; orderIds: string[] }>();
    for (const o of orders ?? []) {
      const rid = o.restaurant_id as string;
      if (!byRestaurant.has(rid)) {
        byRestaurant.set(rid, { gross: 0, count: 0, orderIds: [] });
      }
      const entry = byRestaurant.get(rid)!;
      entry.gross += (o.subtotal as number) ?? 0;
      entry.count += 1;
      entry.orderIds.push(o.id as string);
    }

    // Fetch commission rates per restaurant.
    const restaurantIds = [...byRestaurant.keys()];
    let created = 0;
    let updated = 0;

    for (const rid of restaurantIds) {
      const { data: rest } = await svc
        .from("restaurants")
        .select("commission_rate_pct")
        .eq("id", rid)
        .maybeSingle();

      const ratePct = rest?.commission_rate_pct ?? 15;
      const entry = byRestaurant.get(rid)!;
      const commission = Math.round(entry.gross * (ratePct / 100));
      const net = entry.gross - commission;

      // Upsert settlement for this restaurant + period.
      const { error: se } = await svc.from("settlements").upsert({
        restaurant_id: rid,
        period_start: periodStart,
        period_end: periodEnd,
        gross_amount: entry.gross,
        commission_amount: commission,
        net_amount: net,
        status: "calculated",
      }, { onConflict: "restaurant_id,period_start,period_end" });

      if (se) {
        console.error("settlement upsert failed for", rid, se);
      } else {
        created += 1;
      }
    }

    return jsonOk({
      settlements_created: created,
      settlements_updated: updated,
      period_start: periodStart,
      period_end: periodEnd,
      restaurants_processed: restaurantIds.length,
    });
  } catch (err) {
    console.error("settle-restaurants failure", err);
    return jsonInternal();
  }
}

export default { handler };
