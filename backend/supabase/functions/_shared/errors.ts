// _shared/errors.ts
// Unified error envelope for PareFood Edge Functions (PF-DOC-14 §3.3, §3.4).
// Folders prefixed with `_` are not deployed as functions by the Supabase CLI;
// they are shared modules imported by function entry points.

export type ErrorCode =
  | "BUSINESS_RULE_VIOLATION"
  | "VALIDATION_ERROR"
  | "UNAUTHENTICATED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "RATE_LIMITED"
  | "INTERNAL";

const STATUS_BY_CODE: Record<ErrorCode, number> = {
  BUSINESS_RULE_VIOLATION: 400,
  VALIDATION_ERROR: 400,
  UNAUTHENTICATED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  RATE_LIMITED: 429,
  INTERNAL: 500,
};

export interface AppError {
  code: ErrorCode;
  message: string;
  rule?: string; // BR-XXX business-rule id (PF-DOC-18)
  state?: string; // current entity state, for CONFLICT
  field?: string; // offending field, for VALIDATION_ERROR
}

export function jsonError(
  code: ErrorCode,
  message: string,
  extra?: Partial<AppError>,
): Response {
  const error: AppError = { code, message, ...extra };
  return new Response(JSON.stringify({ error }), {
    status: STATUS_BY_CODE[code],
    headers: { "content-type": "application/json" },
  });
}

export function jsonOk(data: unknown): Response {
  return new Response(JSON.stringify({ data }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
}

export function jsonMethodNotAllowed(): Response {
  return new Response(JSON.stringify({ error: "Method not allowed" }), {
    status: 405,
    headers: { "content-type": "application/json" },
  });
}

// INTERNAL must never leak internals to the client (API-R03, PF-DOC-19).
export function jsonInternal(): Response {
  return jsonError("INTERNAL", "server_error");
}
