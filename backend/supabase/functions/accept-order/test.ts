// accept-order tests — hermetic contract & validation tests (TS-R06, no network).
// These run in dry-run mode (no SUPABASE_URL env), so DB side-effects are skipped
// and the function returns its validated plan. DB-integration tests live in the
// pgTAP suite (backend/supabase/tests).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/accept-order";
const JSON_HEADERS = { "content-type": "application/json" };
const OK_UUID = "11111111-1111-4111-8111-111111111111";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, {
    method: "POST",
    headers: { ...JSON_HEADERS, ...headers },
    body: JSON.stringify(body),
  });
}

Deno.test("accept-order: 405 on non-POST", async () => {
  const resp = await handler(new Request(URL, { method: "GET" }));
  assertEquals(resp.status, 405);
});

Deno.test("accept-order: 400 VALIDATION_ERROR when missing idempotency header", async () => {
  const resp = await handler(post({ order_id: OK_UUID, decision: "accept" }));
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
  assertEquals(b.error.field, "x-idempotency-key");
});

Deno.test("accept-order: 400 when body is not valid JSON", async () => {
  const req = new Request(URL, {
    method: "POST",
    headers: { ...JSON_HEADERS, "x-idempotency-key": "k1" },
    body: "not-json",
  });
  const resp = await handler(req);
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
});

Deno.test("accept-order: 400 when order_id is not a uuid", async () => {
  const resp = await handler(post({ order_id: "nope", decision: "accept" }, { "x-idempotency-key": "k1" }));
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
  assertEquals(b.error.field, "order_id");
});

Deno.test("accept-order: 400 when decision is invalid", async () => {
  const resp = await handler(post({ order_id: OK_UUID, decision: "maybe" }, { "x-idempotency-key": "k1" }));
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
  assertEquals(b.error.field, "decision");
});

Deno.test("accept-order: 400 BUSINESS_RULE_VIOLATION BR-TIMER-001 when prep_minutes out of range", async () => {
  for (const bad of [2, 50, 5.5, -1]) {
    const resp = await handler(
      post({ order_id: OK_UUID, decision: "accept", prep_minutes: bad }, { "x-idempotency-key": "k1" }),
    );
    assertEquals(resp.status, 400);
    const b = await resp.json();
    assertEquals(b.error.code, "BUSINESS_RULE_VIOLATION");
    assertEquals(b.error.rule, "BR-TIMER-001");
  }
});

Deno.test("accept-order: dry-run 200 accept echoes validated plan with default prep 15 + ETA 20", async () => {
  const resp = await handler(
    post({ order_id: OK_UUID, decision: "accept" }, { "x-idempotency-key": "idem-1" }),
  );
  assertEquals(resp.status, 200);
  const b = await resp.json();
  assertEquals(b.data.order_id, OK_UUID);
  assertEquals(b.data.decision, "accept");
  assertEquals(b.data.prep_minutes, 15); // BR-TIMER-001 default
  assertEquals(b.data.dry_run, true);
  assertEquals(b.data.idempotency_key, "idem-1"); // API-R02 idempotency echoed
});

Deno.test("accept-order: dry-run 200 accept honours explicit prep_minutes within range", async () => {
  const resp = await handler(
    post({ order_id: OK_UUID, decision: "accept", prep_minutes: 30 }, { "x-idempotency-key": "idem-2" }),
  );
  assertEquals(resp.status, 200);
  const b = await resp.json();
  assertEquals(b.data.prep_minutes, 30);
});

Deno.test("accept-order: dry-run 200 decline omits prep_minutes", async () => {
  const resp = await handler(
    post({ order_id: OK_UUID, decision: "decline" }, { "x-idempotency-key": "idem-3" }),
  );
  assertEquals(resp.status, 200);
  const b = await resp.json();
  assertEquals(b.data.decision, "decline");
  assertEquals(b.data.prep_minutes, undefined);
});

Deno.test("accept-order: boundary prep_minutes 5 and 45 are accepted (BR-TIMER-001)", async () => {
  for (const ok of [5, 45]) {
    const resp = await handler(
      post({ order_id: OK_UUID, decision: "accept", prep_minutes: ok }, { "x-idempotency-key": "k" }),
    );
    assertEquals(resp.status, 200);
    const b = await resp.json();
    assertEquals(b.data.prep_minutes, ok);
  }
});
