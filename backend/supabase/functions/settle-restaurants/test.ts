// settle-restaurants contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/settle-restaurants";
const H = { "content-type": "application/json" };

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("settle-restaurants: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("settle-restaurants: 400 missing idempotency", async () => {
  assertEquals((await handler(post({}))).status, 400);
});

Deno.test("settle-restaurants: dry-run 200 default 7-day period", async () => {
  const r = await handler(post({}, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.settlements_created, 0);
  assertEquals(b.data.period_days, 7);
  assertEquals(b.data.dry_run, true);
});

Deno.test("settle-restaurants: dry-run 200 custom period_days", async () => {
  const r = await handler(post({ period_days: 14 }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.period_days, 14);
});

Deno.test("settle-restaurants: dry-run 200 empty body ok for cron", async () => {
  const req = new Request(URL, { method: "POST", headers: { ...H, "x-idempotency-key": "k" } });
  const r = await handler(req);
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.period_days, 7);
});
