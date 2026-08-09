import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

Deno.test('dispatch requires idempotency', async () => {
  const req = new Request('http://localhost/dispatch', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ order_id: 'o1' }) });
  const resp = await handler(req);
  assertEquals(resp.status, 400);
  const body = await resp.json();
  assertEquals(body.error, 'Missing X-Idempotency-Key header');
});

Deno.test('dispatch accepts order id', async () => {
  const req = new Request('http://localhost/dispatch', { method: 'POST', headers: { 'content-type': 'application/json', 'x-idempotency-key': 'd1' }, body: JSON.stringify({ order_id: 'o1' }) });
  const resp = await handler(req);
  assertEquals(resp.status, 200);
  const body = await resp.json();
  assertEquals(body.data.order_id, 'o1');
});
