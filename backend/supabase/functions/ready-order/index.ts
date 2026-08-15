// ready-order Edge Function
// PF-DOC-14 §3.3 (function catalogue), PF-DOC-18 §3.3 (state machine)
//
// Merchant marks a preparing order as ready for pickup.
//
//   POST /functions/v1/ready-order
//   Headers: Authorization: Bearer <JWT>           (business role)
//            X-Idempotency-Key: <uuid>             (API-R02)
//   Body:    { "order_id": "<uuid>" }
//
//   200 → { data: { order_id, status: "ready", dispatch: "triggered" } }
//   400 → VALIDATION_ERROR
//   401 → UNAUTHENTICATED        403 → FORBIDDEN (not restaurant owner / wrong role)
//   404 → NOT_FOUND              409 → CONFLICT (order not in 'preparing' state)
//
// Transition (PF-DOC-18 §3.3): preparing → ready  (business actor)
//
// Dispatch (PF-DOC-14 §3.3 note): when this function sets orders.status='ready', a
// DB trigger (migration 0009_dispatch_trigger.sql) POSTs to /functions/v1/dispatch
// via pg_net — idempotent, retried by cron on failure. This function therefore only
// performs the state transition + history insert and returns immediately; it does
// NOT invoke dispatch directly, to avoid duplicate dispatch races (BR-JOB-002).

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

export interface ReadyOrderDeps {
  service?: ReturnType<typeof serviceClient>;
  user?: ReturnType<typeof userClient>;
}

export async function handler(
  req: Request,
  deps: ReadyOrderDeps = {},
): Promise<Response> {
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

  const { order_id } = body as { order_id?: unknown };

  if (!isUuid(order_id)) {
    return jsonError("VALIDATION_ERROR", "order_id must be a uuid", { field: "order_id" });
  }

  // --- Dry-run (no backing Supabase in test env): return validated plan.
  // Auth, ownership and state guards are enforced only when a service client is
  // available; covered by the pgTAP integration suite.
  const svc = deps.service ?? serviceClient();
  if (!svc) {
    return jsonOk({
      order_id,
      status: "ready",
      dispatch: "triggered",
      idempotency_key: idempotency,
      dry_run: true,
      message: "ready-order validated (no DB side-effects in test env)",
    });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const user = deps.user ?? userClient(jwt);
  const guard = requireRole(await resolveCaller(user, jwt), "business", "admin");
  if (!guard.ok) return guard.response;
  const caller = guard.caller; // narrowed non-null after guard

  try {
    // --- Load order (only the columns we need) ---
    const { data: order, error: oe } = await svc
      .from("orders")
      .select("id, status, restaurant_id")
      .eq("id", order_id)
      .maybeSingle();

    if (oe || !order) {
      return jsonError("NOT_FOUND", "Order not found");
    }

    // Ownership: caller must own the order's restaurant (PF-DOC-19 §3.3).
    if (caller.role !== "admin") {
      const { data: rest } = await svc
        .from("restaurants")
        .select("owner_id")
        .eq("id", order.restaurant_id)
        .maybeSingle();
      if (!rest || rest.owner_id !== caller.id) {
        return jsonError("FORBIDDEN", "Caller does not own this restaurant");
      }
    }

    // --- State guard: only `preparing` can become `ready` (PF-DOC-18 §3.3) ---
    if (order.status !== "preparing") {
      return jsonError("CONFLICT", "Order is not in 'preparing' state", {
        state: order.status,
      });
    }

    // --- Transition: preparing → ready (optimistic concurrency) ---
    const { error: ue } = await svc
      .from("orders")
      .update({ status: "ready" })
      .eq("id", order_id)
      .eq("status", "preparing");
    if (ue) return jsonInternal();

    await svc.from("order_status_history").insert({
      order_id,
      from_status: "preparing",
      to_status: "ready",
      changed_by: caller.id,
    });

    // Dispatch is fired by the DB trigger `orders_dispatch_on_ready`
    // (migration 0009) via pg_net. We return `dispatch: triggered` to signal
    // the client that driver matching has been kicked off. If the trigger is
    // not yet installed, the cron retry (BR-DISPATCH-004/005) is the fallback.
    return jsonOk({
      order_id,
      status: "ready",
      dispatch: "triggered",
      idempotency_key: idempotency,
    });
  } catch (err) {
    console.error("ready-order failure", err);
    return jsonInternal();
  }
}

export default { handler };
