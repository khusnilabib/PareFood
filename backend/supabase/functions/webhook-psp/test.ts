import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

Deno.test('webhook-psp rejects missing signature', async () => {
  const req = new Request('http://localhost/webhook', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ event: 'payment.succeeded' }) });
  const resp = await handler(req);
  assertEquals(resp.status, 400);
  const body = await resp.json();
  assertEquals(body.error, 'Missing signature');
});

Deno.test('webhook-psp accepts signed events', async () => {
  const req = new Request('http://localhost/webhook', { method: 'POST', headers: { 'content-type': 'application/json', 'x-psp-signature': 'sig' }, body: JSON.stringify({ event: 'payment.succeeded' }) });
  const resp = await handler(req);
  assertEquals(resp.status, 200);
  const body = await resp.json();
  assertEquals(body.data.received, true);
  assertEquals(body.data.event, 'payment.succeeded');
});
