// payout-drivers contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/payout-drivers";
const H = { "content-type": "application/json" };

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("payout-drivers: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("payout-drivers: 400 missing idempotency", async () => {
  assertEquals((await handler(post({}))).status, 400);
});

Deno.test("payout-drivers: dry-run 200 default yesterday", async () => {
  const r = await handler(post({}, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.payouts_created, 0);
  assertEquals(b.data.total_paid, 0);
  assertEquals(b.data.dry_run, true);
  // period_date is yesterday (YYYY-MM-DD format).
  assertEquals(b.data.period_date.length, 10);
});

Deno.test("payout-drivers: dry-run 200 custom date", async () => {
  const r = await handler(post({ date: "2026-08-10" }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.period_date, "2026-08-10");
});
