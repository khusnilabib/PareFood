import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

Deno.test("place-order returns 400 when missing idempotency header", async () => {
  const req = new Request("http://localhost/place-order", { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ cart: [], address_id: 'a', payment_method: 'ewallet' }) });
  const resp = await handler(req);
  assertEquals(resp.status, 400);
  const body = await resp.json();
  assertEquals(body.error, 'Missing X-Idempotency-Key header');
});

Deno.test("place-order returns 200 with idempotency key and echoes payload", async () => {
  const req = new Request("http://localhost/place-order", { method: 'POST', headers: { 'content-type': 'application/json', 'x-idempotency-key': 'abc-123' }, body: JSON.stringify({ cart: [{id: 'i1', qty: 1}], address_id: 'a', payment_method: 'ewallet', subtotal: 5000, total: 5500 }) });
  const resp = await handler(req);
  assertEquals(resp.status, 200);
  const body = await resp.json();
  assertEquals(body.data.order.idempotency_key, 'abc-123');
  assertEquals(body.data.order.subtotal, 5000);
});
