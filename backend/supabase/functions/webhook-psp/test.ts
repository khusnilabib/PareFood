// webhook-psp contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/webhook-psp";
const H = { "content-type": "application/json" };
const OK = "11111111-1111-4111-8111-111111111111";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("webhook-psp: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("webhook-psp: 400 missing signature", async () => {
  assertEquals((await handler(post({ payment_intent_id: OK, status: "succeeded" }))).status, 400);
});

Deno.test("webhook-psp: 400 invalid payment_intent_id", async () => {
  assertEquals((await handler(post({ payment_intent_id: "x", status: "succeeded" }, { "x-psp-signature": "sig" }))).status, 400);
});

Deno.test("webhook-psp: 400 invalid status", async () => {
  assertEquals((await handler(post({ payment_intent_id: OK, status: "pending" }, { "x-psp-signature": "sig" }))).status, 400);
});

Deno.test("webhook-psp: dry-run 200 succeeded", async () => {
  const r = await handler(post(
    { payment_intent_id: OK, status: "succeeded", psp_reference: "ref-123" },
    { "x-psp-signature": "sig" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.received, true);
  assertEquals(b.data.intent_id, OK);
  assertEquals(b.data.status, "succeeded");
  assertEquals(b.data.dry_run, true);
});

Deno.test("webhook-psp: dry-run 200 failed", async () => {
  const r = await handler(post(
    { payment_intent_id: OK, status: "failed", psp_reference: "ref-456" },
    { "x-psp-signature": "sig" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.status, "failed");
});

Deno.test("webhook-psp: dry-run 200 refunded", async () => {
  const r = await handler(post(
    { payment_intent_id: OK, status: "refunded", psp_reference: "ref-789" },
    { "x-psp-signature": "sig" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.status, "refunded");
});
