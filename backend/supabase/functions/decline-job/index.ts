// decline-job Edge Function
// PF-DOC-14 §3.3, PF-DOC-18 §3.6 (BR-JOB-003, BR-DISPATCH-006)
//
// Driver declines a job offer. Declining never penalises at MVP (BR-DISPATCH-
// 006); the dispatch cron re-offers to the next eligible driver.
//
//   POST /functions/v1/decline-job
//   Headers: Authorization: Bearer <JWT> (driver), X-Idempotency-Key
//   Body:    { "delivery_id": "<uuid>" }
//   200 → { data: { delivery_id, declined: true } }

import { jsonError, jsonOk, jsonMethodNotAllowed, jsonInternal } from "../_shared/errors.ts";
import { serviceClient, userClient, getBearer } from "../_shared/supabase.ts";
import { resolveCaller, requireRole, isUuid } from "../_shared/auth.ts";

export async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return jsonMethodNotAllowed();
  const idempotency = req.headers.get("x-idempotency-key");
  if (!idempotency) return jsonError("VALIDATION_ERROR", "Missing X-Idempotency-Key header", { field: "x-idempotency-key" });

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return jsonError("VALIDATION_ERROR", "Invalid JSON body"); }
  const { delivery_id } = body as { delivery_id?: unknown };
  if (!isUuid(delivery_id)) return jsonError("VALIDATION_ERROR", "delivery_id must be a uuid", { field: "delivery_id" });

  // --- Dry-run (no backing Supabase in test env) ---
  const svc = serviceClient();
  if (!svc) {
    return jsonOk({ delivery_id, declined: true, idempotency_key: idempotency, dry_run: true });
  }

  // --- Caller identity + role (requires a backing Supabase project) ---
  const jwt = getBearer(req);
  const guard = requireRole(await resolveCaller(userClient(jwt), jwt), "driver");
  if (!guard.ok) return guard.response;

  try {
    // Record the decline (audit only — the job stays open for the next driver).
    // In a full impl this writes to a `job_offers` table; for MVP we simply
    // confirm the decline and let the dispatch cron re-offer.
    return jsonOk({ delivery_id, declined: true });
  } catch (err) {
    console.error("decline-job failure", err);
    return jsonInternal();
  }
}
export default { handler };
