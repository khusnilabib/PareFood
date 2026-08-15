// ready-order tests — hermetic contract & validation tests (TS-R06, no network).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/ready-order";
const JSON_HEADERS = { "content-type": "application/json" };
const OK_UUID = "22222222-2222-4222-8222-222222222222";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, {
    method: "POST",
    headers: { ...JSON_HEADERS, ...headers },
    body: JSON.stringify(body),
  });
}

Deno.test("ready-order: 405 on non-POST", async () => {
  const resp = await handler(new Request(URL, { method: "GET" }));
  assertEquals(resp.status, 405);
});

Deno.test("ready-order: 400 VALIDATION_ERROR when missing idempotency header", async () => {
  const resp = await handler(post({ order_id: OK_UUID }));
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
  assertEquals(b.error.field, "x-idempotency-key");
});

Deno.test("ready-order: 400 when body is not valid JSON", async () => {
  const req = new Request(URL, {
    method: "POST",
    headers: { ...JSON_HEADERS, "x-idempotency-key": "k1" },
    body: "{bad",
  });
  const resp = await handler(req);
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
});

Deno.test("ready-order: 400 when order_id is not a uuid", async () => {
  const resp = await handler(post({ order_id: 42 }, { "x-idempotency-key": "k1" }));
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
  assertEquals(b.error.field, "order_id");
});

Deno.test("ready-order: 400 when order_id missing entirely", async () => {
  const resp = await handler(post({}, { "x-idempotency-key": "k1" }));
  assertEquals(resp.status, 400);
  const b = await resp.json();
  assertEquals(b.error.code, "VALIDATION_ERROR");
  assertEquals(b.error.field, "order_id");
});

Deno.test("ready-order: dry-run 200 returns status ready + dispatch triggered", async () => {
  const resp = await handler(post({ order_id: OK_UUID }, { "x-idempotency-key": "idem-r" }));
  assertEquals(resp.status, 200);
  const b = await resp.json();
  assertEquals(b.data.order_id, OK_UUID);
  assertEquals(b.data.status, "ready");
  assertEquals(b.data.dispatch, "triggered");
  assertEquals(b.data.dry_run, true);
  assertEquals(b.data.idempotency_key, "idem-r");
});

Deno.test("ready-order: ignores extra unknown body fields (forward-compat, PF-DOC-23)", async () => {
  const resp = await handler(
    post({ order_id: OK_UUID, unexpected: "x" }, { "x-idempotency-key": "k" }),
  );
  assertEquals(resp.status, 200);
});
