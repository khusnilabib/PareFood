// process-payment contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/process-payment";
const H = { "content-type": "application/json" };
const OK = "11111111-1111-4111-8111-111111111111";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("process-payment: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("process-payment: 400 missing idempotency", async () => {
  assertEquals((await handler(post({ order_id: OK, action: "charge", amount: 50000, method: "ewallet" }))).status, 400);
});

Deno.test("process-payment: 400 invalid order_id", async () => {
  assertEquals((await handler(post({ order_id: "x", action: "charge", amount: 50000, method: "ewallet" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("process-payment: 400 invalid action", async () => {
  assertEquals((await handler(post({ order_id: OK, action: "void", amount: 50000, method: "ewallet" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("process-payment: 400 non-positive amount", async () => {
  assertEquals((await handler(post({ order_id: OK, action: "charge", amount: 0, method: "ewallet" }, { "x-idempotency-key": "k" }))).status, 400);
  assertEquals((await handler(post({ order_id: OK, action: "charge", amount: -5, method: "ewallet" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("process-payment: 400 invalid method", async () => {
  assertEquals((await handler(post({ order_id: OK, action: "charge", amount: 50000, method: "bitcoin" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("process-payment: dry-run 200 charge COD returns succeeded", async () => {
  const r = await handler(post({ order_id: OK, action: "charge", amount: 50000, method: "cod" }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.status, "succeeded");
  assertEquals(b.data.psp, "cod");
  assertEquals(b.data.dry_run, true);
});

Deno.test("process-payment: dry-run 200 charge ewallet returns processing", async () => {
  const r = await handler(post({ order_id: OK, action: "charge", amount: 50000, method: "ewallet" }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.status, "processing");
  assertEquals(b.data.intent_type, "charge");
});

Deno.test("process-payment: dry-run 200 refund returns processing", async () => {
  const r = await handler(post({ order_id: OK, action: "refund", amount: 50000, method: "ewallet" }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.intent_type, "refund");
});
