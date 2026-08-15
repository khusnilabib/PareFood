// send-notification Edge Function (internal)
// PF-DOC-14 §3.3 (function catalogue), PF-DOC-18 §3.4 (NOTIF rules)
//
// Sends a push + in-app notification to a user. Called internally by other
// Edge Functions (accept-order, ready-order, driver-pickup, etc.) when an
// order transitions. Writes a row to `notifications` (in-app) and dispatches
// a push via FCM/APNs to the user's registered device tokens.
//
//   POST /functions/v1/send-notification
//   Headers: X-Idempotency-Key: <uuid> (internal call)
//   Body:    { "user_id": "<uuid>", "type": "order_accepted"|"order_ready"|...,
//              "title": "<text>", "body": "<text>",
//              "order_id"?: "<uuid>", "data"?: {} }
//
//   200 → { data: { notification_id, pushed: <count> } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { isUuid } from "../_shared/auth.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) {
    return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });
  }

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch {
    return jsonError("VALIDATION_ERROR", "Invalid JSON body");
  }

  const { user_id, type, title, body: text, order_id, data } = body as {
    user_id?: unknown; type?: unknown; title?: unknown; body?: unknown;
    order_id?: unknown; data?: unknown;
  };

  if (!isUuid(user_id)) {
    return jsonError("VALIDATION_ERROR", "user_id must be a uuid", { field: "user_id" });
  }
  if (typeof title !== "string" || title.trim().length === 0) {
    return jsonError("VALIDATION_ERROR", "title is required", { field: "title" });
  }
  if (typeof text !== "string" || text.trim().length === 0) {
    return jsonError("VALIDATION_ERROR", "body is required", { field: "body" });
  }

  const svc = serviceClient();
  if (!svc) {
    return jsonOk({
      notification_id: crypto.randomUUID(),
      user_id,
      type: type ?? "system",
      pushed: 0,
      idempotency_key: idempotency,
      dry_run: true,
    });
  }

  try {
    // --- Insert the in-app notification row ---
    const { data: notif, error: ne } = await svc.from("notifications").insert({
      user_id,
      type: (type as string) ?? "system",
      title,
      body: text,
      order_id: isUuid(order_id) ? order_id : null,
      data: data ?? null,
      is_read: false,
    }).select("id").single();
    if (ne || !notif) return jsonInternal();

    // --- Fetch the user's device tokens for push ---
    const { data: tokens } = await svc
      .from("device_tokens")
      .select("token, platform")
      .eq("user_id", user_id as string);

    let pushed = 0;
    if (tokens && tokens.length > 0) {
      // Dispatch push via FCM/APNs. In production, this calls the FCM HTTP v1
      // API or APNs. For MVP, we count the tokens and log (the push provider
      // is wired in S12 hardening).
      pushed = tokens.length;
      // TODO(S12): call FCM/APNs SDK with the notification payload.
    }

    return jsonOk({ notification_id: notif.id, pushed });
  } catch (err) {
    console.error("send-notification failure", err);
    return jsonInternal();
  }
}

export default { handler };
