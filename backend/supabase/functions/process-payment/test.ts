import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

Deno.test("process-payment rejects missing idempotency", async () => {
  const req = new Request('http://localhost/process-payment', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ payment_intent_id: 'p1', action: 'charge' }) });
  const resp = await handler(req);
  assertEquals(resp.status, 400);
  const body = await resp.json();
  assertEquals(body.error, 'Missing X-Idempotency-Key header');
});

Deno.test("process-payment accepts valid request", async () => {
  const req = new Request('http://localhost/process-payment', { method: 'POST', headers: { 'content-type': 'application/json', 'x-idempotency-key': 'k1' }, body: JSON.stringify({ payment_intent_id: 'p1', action: 'charge' }) });
  const resp = await handler(req);
  assertEquals(resp.status, 200);
  const body = await resp.json();
  assertEquals(body.data.idempotency_key, 'k1');
  assertEquals(body.data.action, 'charge');
});
