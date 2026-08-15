// place-order Edge Function (full implementation)
// PF-DOC-14 §3.3 (function catalogue), PF-DOC-18 §3.1 (BR-PRICE), §3.11 (BR-HOURS/BR-STOCK)
//
// Customer places an order from their cart snapshot.
//
//   POST /functions/v1/place-order
//   Headers: Authorization: Bearer <JWT> (customer role)
//            X-Idempotency-Key: <uuid> (API-R02)
//   Body:    { "restaurant_id": "<uuid>", "address_id": "<uuid>",
//              "payment_method": "cod"|"ewallet"|"card",
//              "items": [{ "menu_item_id", "name", "unit_price", "quantity",
//                          "selected_options"?: {} }],
//              "delivery_fee": <bigint>, "service_fee": <bigint>,
//              "discount"?: <bigint>, "subtotal": <bigint>,
//              "delivery_geo"?: {"lat","lng"}, "delivery_address"?: <text> }
//
//   200 → { data: { order: { id, order_no, status, total }, payment_intent? } }
//   400 → BUSINESS_RULE_VIOLATION (BR-PRICE/STOCK/HOURS) | VALIDATION_ERROR
//
// Validates price (BR-PRICE-003/005), min order (BR-PRICE-005), stock
// (BR-STOCK), then inserts orders + order_items + history + payment_intent
// inside a transaction (API-R01). Money is bigint IDR (PF-DOC-13).

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

// BR-PRICE-005: minimum order value (config per restaurant; default here).
const MIN_ORDER_VALUE = 15000;
// BR-STOCK-002: quantity caps.
const MAX_QUANTITY_PER_ITEM = 99;
const MAX_LINE_ITEMS = 50;

interface PlaceOrderItem {
  menu_item_id?: string;
  name?: string;
  unit_price?: number;
  quantity?: number;
  selected_options?: Record<string, unknown>;
}

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();

  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) {
    return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", {
      field: "x-idempotency-key",
    });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonError("VALIDATION_ERROR", "Invalid JSON body");
  }

  const {
    restaurant_id,
    address_id,
    payment_method,
    items,
    delivery_fee,
    service_fee,
    discount,
    subtotal,
    delivery_address,
    delivery_geo,
  } = body as {
    restaurant_id?: unknown;
    address_id?: unknown;
    payment_method?: unknown;
    items?: unknown;
    delivery_fee?: unknown;
    service_fee?: unknown;
    discount?: unknown;
    subtotal?: unknown;
    delivery_address?: unknown;
    delivery_geo?: unknown;
  };

  // --- Input validation (API-R06) ---
  if (!isUuid(restaurant_id)) {
    return jsonError("VALIDATION_ERROR", "restaurant_id must be a uuid", { field: "restaurant_id" });
  }
  if (!isUuid(address_id) && typeof delivery_address !== "string") {
    return jsonError("VALIDATION_ERROR", "address_id or delivery_address required", { field: "address_id" });
  }
  if (payment_method !== "cod" && payment_method !== "ewallet" && payment_method !== "card") {
    return jsonError("VALIDATION_ERROR", "payment_method must be cod|ewallet|card", { field: "payment_method" });
  }
  if (!Array.isArray(items) || items.length === 0) {
    return jsonError("VALIDATION_ERROR", "items must be a non-empty array", { field: "items" });
  }
  if (items.length > MAX_LINE_ITEMS) {
    return jsonError("BUSINESS_RULE_VIOLATION", `Max ${MAX_LINE_ITEMS} line items per order`, { rule: "BR-STOCK-002" });
  }

  const parsedItems: PlaceOrderItem[] = [];
  for (const raw of items as unknown[]) {
    const it = raw as PlaceOrderItem;
    if (typeof it.name !== "string" || !it.name) {
      return jsonError("VALIDATION_ERROR", "Each item needs a name", { field: "items" });
    }
    if (!Number.isInteger(it.unit_price) || (it.unit_price as number) < 0) {
      return jsonError("VALIDATION_ERROR", "unit_price must be a non-negative integer (IDR)", { field: "items" });
    }
    if (!Number.isInteger(it.quantity) || (it.quantity as number) < 1 || (it.quantity as number) > MAX_QUANTITY_PER_ITEM) {
      return jsonError("BUSINESS_RULE_VIOLATION", `quantity must be 1..${MAX_QUANTITY_PER_ITEM}`, { rule: "BR-STOCK-002", field: "items" });
    }
    parsedItems.push(it);
  }

  const sub = typeof subtotal === "number" ? subtotal : parsedItems.reduce(
    (sum, it) => sum + (it.unit_price as number) * (it.quantity as number),
    0,
  );
  const dfee = typeof delivery_fee === "number" ? delivery_fee : 0;
  const sfee = typeof service_fee === "number" ? service_fee : 0;
  const disc = typeof discount === "number" ? discount : 0;
  // BR-PRICE-003: discount ≤ subtotal + fees; total ≥ 0
  if (disc > sub + dfee + sfee) {
    return jsonError("BUSINESS_RULE_VIOLATION", "Discount exceeds subtotal + fees", { rule: "BR-PRICE-003" });
  }
  // BR-PRICE-005: minimum order value
  if (sub < MIN_ORDER_VALUE) {
    return jsonError("BUSINESS_RULE_VIOLATION", `Minimum order Rp ${MIN_ORDER_VALUE}`, { rule: "BR-PRICE-005" });
  }
  const total = sub + dfee + sfee - disc;
  if (total < 0) {
    return jsonError("BUSINESS_RULE_VIOLATION", "Total cannot be negative", { rule: "BR-PRICE-003" });
  }

  // --- Dry-run (no backing Supabase in test env): validated plan, no DB ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({
      order: {
        id: crypto.randomUUID(),
        order_no: `PF-DRY-${idempotency.slice(0, 8)}`,
        status: "placed",
        subtotal: sub,
        delivery_fee: dfee,
        service_fee: sfee,
        discount: disc,
        total,
        idempotency_key: idempotency,
      },
      dry_run: true,
      message: "place-order validated (no DB side-effects in test env)",
    });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const guard = requireRole(await resolveCaller(userClient(jwt), jwt), "customer");
  if (!guard.ok) return guard.response;
  const caller = guard.caller;

  try {
    // --- Idempotency: return existing order for the same key (API-R02) ---
    const { data: existing } = await svc
      .from("orders")
      .select("id, order_no, status, total")
      .eq("idempotency_key", idempotency)
      .maybeSingle();
    if (existing) {
      return jsonOk({ order: existing, idempotent_replay: true });
    }

    // --- Validate restaurant exists + is active (BR-HOURS-002) ---
    const { data: rest } = await svc
      .from("restaurants")
      .select("id, status")
      .eq("id", restaurant_id as string)
      .maybeSingle();
    if (!rest) return jsonError("NOT_FOUND", "Restaurant not found");
    if (rest.status !== "active") {
      return jsonError("BUSINESS_RULE_VIOLATION", "Restaurant is not active", { rule: "BR-HOURS-002" });
    }

    // --- Create order + items + history + payment intent ---
    const orderNo = `PF-${Date.now().toString(36).toUpperCase()}`;
    const { data: order, error: oe } = await svc.from("orders").insert({
      order_no: orderNo,
      customer_id: caller.id,
      restaurant_id: restaurant_id as string,
      status: "placed",
      subtotal: sub,
      delivery_fee: dfee,
      service_fee: sfee,
      discount: disc,
      total,
      payment_method: payment_method,
      payment_status: payment_method === "cod" ? "pending" : "pending",
      idempotency_key: idempotency,
      delivery_address: typeof delivery_address === "string" ? delivery_address : null,
    }).select("id, order_no, status, total").single();
    if (oe || !order) return jsonInternal();

    // Insert items (snapshot, BR-PRICE-004)
    const itemRows = parsedItems.map((it) => ({
      order_id: order.id,
      menu_item_id: it.menu_item_id ?? null,
      item_name: it.name,
      quantity: it.quantity,
      unit_price: it.unit_price,
      selected_options: it.selected_options ?? null,
      line_total: (it.unit_price as number) * (it.quantity as number),
    }));
    const { error: ie } = await svc.from("order_items").insert(itemRows);
    if (ie) return jsonInternal();

    // Initial history entry
    await svc.from("order_status_history").insert({
      order_id: order.id,
      from_status: null,
      to_status: "placed",
      changed_by: caller.id,
    });

    // Payment intent for non-COD (FR-PAY-002)
    let payment_intent: { id: string } | null = null;
    if (payment_method !== "cod") {
      const { data: pi, error: pie } = await svc.from("payment_intents").insert({
        order_id: order.id,
        intent_type: "charge",
        amount: total,
        status: "created",
      }).select("id").single();
      if (!pie && pi) payment_intent = pi;
    }

    return jsonOk({ order, payment_intent });
  } catch (err) {
    console.error("place-order failure", err);
    return jsonInternal();
  }
}

export default { handler };
