// accept-order Edge Function
// PF-DOC-14 §3.3 (function catalogue), PF-DOC-18 §3.3 (state machine), §3.4 (timeouts)
//
// Merchant accepts or declines a freshly-placed order.
//
//   POST /functions/v1/accept-order
//   Headers: Authorization: Bearer <JWT>           (business role, PF-DOC-19 §3.2)
//            X-Idempotency-Key: <uuid>             (API-R02, NFR-021)
//   Body:    { "order_id": "<uuid>", "decision": "accept" | "decline",
//              "prep_minutes"?: 5..45 }            (BR-TIMER-001, only for accept)
//
//   200 → { data: { order_id, status, estimated_minutes?, refund_status? } }
//   400 → BUSINESS_RULE_VIOLATION (BR-ACCEPT-001 | BR-TIMER-001) | VALIDATION_ERROR
//   401 → UNAUTHENTICATED        403 → FORBIDDEN (not restaurant owner / wrong role)
//   404 → NOT_FOUND              409 → CONFLICT (order not in `placed` state)
//
// State machine (PF-DOC-18 §3.3):
//   accept   : placed → accepted → preparing   (auto on accept)
//   decline  : placed → cancelled               (BR-CANCEL-006 → full refund)

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

// BR-ACCEPT-001: restaurant accept window (seconds). PF-DOC-18 §3.4 default 120.
const ACCEPT_WINDOW_SECONDS = 120;
// BR-TIMER-001: prep-time bounds (minutes). PF-DOC-18 §3.4.
const PREP_MIN_MINUTES = 5;
const PREP_MAX_MINUTES = 45;
const PREP_DEFAULT_MINUTES = 15;
// Dispatch buffer added to ETA (BR-ETA-001 pickup buffer). PF-DOC-18 §3.7.
const DISPATCH_BUFFER_MINUTES = 5;

export interface AcceptOrderDeps {
  // Injectable for tests; defaults read env (dry-run when env absent).
  service?: ReturnType<typeof serviceClient>;
  user?: ReturnType<typeof userClient>;
  now?: () => number;
}

export async function handler(
  req: Request,
  deps: AcceptOrderDeps = {},
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

  const { order_id, decision, prep_minutes } = body as {
    order_id?: unknown;
    decision?: unknown;
    prep_minutes?: unknown;
  };

  // --- Input validation (API-R06: never trust RLS-only for money/state) ---
  if (!isUuid(order_id)) {
    return jsonError("VALIDATION_ERROR", "order_id must be a uuid", { field: "order_id" });
  }
  if (decision !== "accept" && decision !== "decline") {
    return jsonError("VALIDATION_ERROR", "decision must be 'accept' or 'decline'", {
      field: "decision",
    });
  }

  let prepMinutes = PREP_DEFAULT_MINUTES;
  if (decision === "accept") {
    if (prep_minutes !== undefined) {
      const n = Number(prep_minutes);
      if (!Number.isInteger(n) || n < PREP_MIN_MINUTES || n > PREP_MAX_MINUTES) {
        return jsonError(
          "BUSINESS_RULE_VIOLATION",
          `prep_minutes must be an integer between ${PREP_MIN_MINUTES} and ${PREP_MAX_MINUTES}`,
          { rule: "BR-TIMER-001", field: "prep_minutes" },
        );
      }
      prepMinutes = n;
    }
  }

  // --- Dry-run (no backing Supabase in test env): return validated plan.
  // Auth, ownership, state and BR-ACCEPT timers are enforced only when a
  // service client is available; they are covered by the pgTAP integration suite.
  const svc = deps.service ?? serviceClient();
  if (!svc) {
    return jsonOk({
      order_id,
      decision,
      prep_minutes: decision === "accept" ? prepMinutes : undefined,
      idempotency_key: idempotency,
      dry_run: true,
      message: "accept-order validated (no DB side-effects in test env)",
    });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const user = deps.user ?? userClient(jwt);
  const guard = requireRole(await resolveCaller(user, jwt), "business", "admin");
  if (!guard.ok) return guard.response;
  const caller = guard.caller; // narrowed non-null after guard

  try {
    // --- Load order + ownership in one round-trip ---
    const { data: order, error: oe } = await svc
      .from("orders")
      .select("id, status, placed_at, restaurant_id, payment_method, payment_status, total")
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

    // --- State guard (optimistic concurrency, PF-DOC-14 §3.5) ---
    if (order.status !== "placed") {
      return jsonError("CONFLICT", "Order is not in 'placed' state", {
        state: order.status,
      });
    }

    // --- BR-ACCEPT-001: 120s accept window ---
    const placedAt = new Date(order.placed_at).getTime();
    const nowMs = (deps.now ?? Date.now)();
    const elapsedSec = Math.floor((nowMs - placedAt) / 1000);
    if (elapsedSec > ACCEPT_WINDOW_SECONDS) {
      // Window expired: the system cron auto-cancels (BR-CANCEL-005); reject here.
      return jsonError(
        "BUSINESS_RULE_VIOLATION",
        `Accept window of ${ACCEPT_WINDOW_SECONDS}s expired`,
        { rule: "BR-ACCEPT-001" },
      );
    }

    // ============ ACCEPT ============
    if (decision === "accept") {
      const estimated = prepMinutes + DISPATCH_BUFFER_MINUTES; // BR-ETA-001

      // placed → accepted (BR-ORDER state machine)
      const { error: e1 } = await svc
        .from("orders")
        .update({ status: "accepted", estimated_minutes: estimated })
        .eq("id", order_id)
        .eq("status", "placed"); // optimistic concurrency guard
      if (e1) return jsonInternal();

      await svc.from("order_status_history").insert({
        order_id,
        from_status: "placed",
        to_status: "accepted",
        changed_by: caller.id,
      });

      // accepted → preparing (auto on accept, PF-DOC-18 §3.3)
      const { error: e2 } = await svc
        .from("orders")
        .update({ status: "preparing" })
        .eq("id", order_id)
        .eq("status", "accepted");
      if (e2) return jsonInternal();

      await svc.from("order_status_history").insert({
        order_id,
        from_status: "accepted",
        to_status: "preparing",
        changed_by: caller.id,
      });

      return jsonOk({
        order_id,
        status: "preparing",
        prep_minutes: prepMinutes,
        estimated_minutes: estimated,
        idempotency_key: idempotency,
      });
    }

    // ============ DECLINE (BR-CANCEL-006 → full refund) ============
    const { error: ed } = await svc
      .from("orders")
      .update({
        status: "cancelled",
        cancelled_at: new Date().toISOString(),
        cancel_reason: "merchant_declined",
      })
      .eq("id", order_id)
      .eq("status", "placed");
    if (ed) return jsonInternal();

    await svc.from("order_status_history").insert({
      order_id,
      from_status: "placed",
      to_status: "cancelled",
      changed_by: caller.id,
      reason: "merchant_declined",
    });

    // Refund: non-COD charges are reversed by process-payment (BR-REFUND-001).
    // For COD there is no charge to reverse (BR-COD-003).
    let refund_status = "n/a";
    if (order.payment_method !== "cod" && order.payment_status === "paid") {
      const { data: intent } = await svc
        .from("payment_intents")
        .select("id")
        .eq("order_id", order_id)
        .eq("intent_type", "charge")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (intent) {
        await svc.from("payment_intents").insert({
          order_id,
          intent_type: "refund",
          amount: order.total,
          status: "created",
        });
        refund_status = "initiated";
      }
    }

    return jsonOk({
      order_id,
      status: "cancelled",
      refund_status,
      idempotency_key: idempotency,
    });
  } catch (err) {
    console.error("accept-order failure", err);
    return jsonInternal();
  }
}

export default { handler };
