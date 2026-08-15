// driver-delivered contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/driver-delivered";
const H = { "content-type": "application/json" };
const OK = "11111111-1111-4111-8111-111111111111";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("driver-delivered: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("driver-delivered: 400 missing idempotency", async () => {
  assertEquals((await handler(post({ delivery_id: OK, proof_photo_url: "https://x/y.jpg" }))).status, 400);
});

Deno.test("driver-delivered: 400 invalid delivery_id", async () => {
  assertEquals((await handler(post({ delivery_id: null, proof_photo_url: "https://x/y.jpg" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("driver-delivered: 400 invalid proof_photo_url", async () => {
  for (const bad of ["", "not-a-url", "ftp://x"]) {
    const r = await handler(post({ delivery_id: OK, proof_photo_url: bad }, { "x-idempotency-key": "k" }));
    assertEquals(r.status, 400);
  }
});

Deno.test("driver-delivered: dry-run 200 returns delivered", async () => {
  const r = await handler(post({ delivery_id: OK, proof_photo_url: "https://cdn/proof.jpg" }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.status, "delivered");
});
