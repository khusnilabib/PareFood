// driver-pickup contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/driver-pickup";
const H = { "content-type": "application/json" };
const OK = "11111111-1111-4111-8111-111111111111";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("driver-pickup: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("driver-pickup: 400 missing idempotency", async () => {
  assertEquals((await handler(post({ delivery_id: OK, pickup_code: "1234" }))).status, 400);
});

Deno.test("driver-pickup: 400 invalid delivery_id", async () => {
  assertEquals((await handler(post({ delivery_id: "no", pickup_code: "1234" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("driver-pickup: 400 pickup_code not 4 digits", async () => {
  for (const bad of ["123", "12345", "abcd", ""]) {
    const r = await handler(post({ delivery_id: OK, pickup_code: bad }, { "x-idempotency-key": "k" }));
    assertEquals(r.status, 400);
  }
});

Deno.test("driver-pickup: dry-run 200 returns picked_up", async () => {
  const r = await handler(post({ delivery_id: OK, pickup_code: "1234" }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.status, "picked_up");
});
