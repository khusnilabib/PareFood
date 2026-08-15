// webhook-psp Edge Function (full implementation)
// PF-DOC-14 §3.3, PF-DOC-19 §3.2 (signature verification), PF-DOC-18 §3.4
//
// Receives PSP webhook events (charge succeeded/failed, refund completed).
// Verifies the signature, looks up the payment intent, updates its status,
// and fires downstream effects (mark order paid, trigger dispatch).
//
//   POST /functions/v1/webhook-psp
//   Headers: X-PSP-Signature: <hmac>
//            X-PSP-Event: <event_type>
//   Body:    { "payment_intent_id": "<uuid>", "status": "succeeded"|"failed",
//              "psp_reference": "<text>" }
//
//   200 → { data: { received: true, intent_id, status } }
//   400 → missing signature / invalid body
//   401 → signature verification failed
//
// Idempotent: if the intent is already in the target status, returns 200
// without side effects (API-R02). Signature verification uses HMAC-SHA256
// with the PSP_WEBHOOK_SECRET env var.

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { isUuid } from "../_shared/auth.ts";

const WEBHOOK_SECRET = Deno.env.get("PSP_WEBHOOK_SECRET") ?? "";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();

  const signature = req.headers.get("x-psp-signature");
  if (!signature) {
    return jsonError("VALIDATION_ERROR", "Missing X-PSP-Signature header", {
      field: "x-psp-signature",
    });
  }

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch {
    return jsonError("VALIDATION_ERROR", "Invalid JSON body");
  }

  const { payment_intent_id, status, psp_reference } = body as {
    payment_intent_id?: unknown; status?: unknown; psp_reference?: unknown;
  };

  if (!isUuid(payment_intent_id)) {
    return jsonError("VALIDATION_ERROR", "payment_intent_id must be a uuid", {
      field: "payment_intent_id",
    });
  }
  if (status !== "succeeded" && status !== "failed" && status !== "refunded") {
    return jsonError("VALIDATION_ERROR", "status must be succeeded|failed|refunded", {
      field: "status",
    });
  }

  // --- Signature verification (PF-DOC-19 §3.2) ---
  // In production, verify HMAC-SHA256 of the raw body against WEBHOOK_SECRET.
  // In dry-run (no secret), skip verification (test env only).
  if (WEBHOOK_SECRET) {
    const rawBody = JSON.stringify(body);
    const expected = await hmacSha256(rawBody, WEBHOOK_SECRET);
    if (signature !== expected) {
      return jsonError("UNAUTHENTICATED", "Invalid webhook signature");
    }
  }

  // --- Dry-run (no backing Supabase in test env) ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({
      received: true,
      intent_id: payment_intent_id,
      status,
      psp_reference,
      dry_run: true,
    });
  }

  try {
    // --- Idempotent: check current status ---
    const { data: intent, error: ie } = await svc
      .from("payment_intents")
      .select("id, order_id, status, intent_type")
      .eq("id", payment_intent_id as string)
      .maybeSingle();

    if (ie || !intent) {
      return jsonError("NOT_FOUND", "Payment intent not found");
    }

    // Already terminal → idempotent ack (API-R02).
    if (intent.status === status) {
      return jsonOk({ received: true, intent_id: intent.id, status: intent.status, idempotent: true });
    }

    // --- Update the intent ---
    const { error: ue } = await svc
      .from("payment_intents")
      .update({
        status,
        psp_status: psp_reference as string,
        webhook_received_at: new Date().toISOString(),
      })
      .eq("id", payment_intent_id as string);
    if (ue) return jsonInternal();

    // --- Downstream effects ---
    if (status === "succeeded" && intent.order_id) {
      // Mark the order as paid.
      await svc.from("orders")
        .update({ payment_status: "paid" })
        .eq("id", intent.order_id);
    }
    if (status === "failed" && intent.order_id) {
      // Charge failed → order cannot proceed; the cron cancels it (BR-CANCEL).
      await svc.from("orders")
        .update({ payment_status: "failed" })
        .eq("id", intent.order_id);
    }
    if (status === "refunded" && intent.order_id) {
      await svc.from("orders")
        .update({ payment_status: "refunded" })
        .eq("id", intent.order_id);
    }

    return jsonOk({ received: true, intent_id: intent.id, status });
  } catch (err) {
    console.error("webhook-psp failure", err);
    return jsonInternal();
  }
}

// HMAC-SHA256 using Web Crypto API (available in Deno).
async function hmacSha256(message: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

export default { handler };
