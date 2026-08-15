// reconcile contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/reconcile";
const H = { "content-type": "application/json" };

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("reconcile: 405 on non-POST", async () => {
  assertEquals((await handler(new Request(URL, { method: "GET" }))).status, 405);
});

Deno.test("reconcile: 400 missing idempotency", async () => {
  assertEquals((await handler(post({}))).status, 400);
});

Deno.test("reconcile: dry-run 200 default 7-day range", async () => {
  const r = await handler(post({}, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.gross_order_total, 0);
  assertEquals(b.data.cod_outstanding, 0);
  assertEquals(b.data.mismatch_count, 0);
  assertEquals(b.data.is_clean, true);
  assertEquals(b.data.dry_run, true);
});

Deno.test("reconcile: dry-run 200 custom date range", async () => {
  const r = await handler(post(
    { from: "2026-08-01T00:00:00Z", to: "2026-08-07T23:59:59Z" },
    { "x-idempotency-key": "k" },
  ));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.period.from, "2026-08-01T00:00:00Z");
  assertEquals(b.data.period.to, "2026-08-07T23:59:59Z");
});
