// send-notification contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/send-notification";
const H = { "content-type": "application/json" };
const OK = "11111111-1111-4111-8111-111111111111";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("send-notification: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("send-notification: 400 missing idempotency", async () => {
  assertEquals((await handler(post({ user_id: OK, title: "t", body: "b" }))).status, 400);
});

Deno.test("send-notification: 400 invalid user_id", async () => {
  assertEquals((await handler(post({ user_id: "x", title: "t", body: "b" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("send-notification: 400 missing title", async () => {
  assertEquals((await handler(post({ user_id: OK, body: "b" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("send-notification: 400 missing body", async () => {
  assertEquals((await handler(post({ user_id: OK, title: "t" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("send-notification: dry-run 200 returns notification_id", async () => {
  const r = await handler(post(
    { user_id: OK, type: "order_ready", title: "Pesanan siap", body: "Pesanan Anda siap diambil." },
    { "x-idempotency-key": "k" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.user_id, OK);
  assertEquals(b.data.type, "order_ready");
  assertEquals(b.data.pushed, 0);
  assertEquals(b.data.dry_run, true);
});

Deno.test("send-notification: dry-run 200 defaults type to system", async () => {
  const r = await handler(post(
    { user_id: OK, title: "Selamat datang", body: "Selamat datang di PareFood!" },
    { "x-idempotency-key": "k" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.type, "system");
});
