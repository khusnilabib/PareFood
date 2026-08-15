// register-device-token contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/register-device-token";
const H = { "content-type": "application/json" };

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("register-device-token: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("register-device-token: 400 missing idempotency", async () => {
  assertEquals((await handler(post({ token: "abc123", platform: "fcm" }))).status, 400);
});

Deno.test("register-device-token: 400 missing token", async () => {
  assertEquals((await handler(post({ platform: "fcm" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("register-device-token: 400 empty token", async () => {
  assertEquals((await handler(post({ token: "", platform: "fcm" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("register-device-token: 400 invalid platform", async () => {
  assertEquals((await handler(post({ token: "abc", platform: "sms" }, { "x-idempotency-key": "k" }))).status, 400);
});

Deno.test("register-device-token: dry-run 200 returns registered=true", async () => {
  const r = await handler(post(
    { token: "fcm-token-abc123", platform: "fcm" },
    { "x-idempotency-key": "k" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.registered, true);
  assertEquals(b.data.dry_run, true);
});

Deno.test("register-device-token: dry-run 200 accepts apns platform", async () => {
  const r = await handler(post(
    { token: "apns-token-xyz", platform: "apns" },
    { "x-idempotency-key": "k" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.registered, true);
});
