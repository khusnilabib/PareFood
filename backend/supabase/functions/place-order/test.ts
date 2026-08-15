// place-order contract tests (dry-run, hermetic — TS-R06, ADR 0003).

import { assertEquals } from "https://deno.land/std@0.201.0/testing/asserts.ts";
import { handler } from "./index.ts";

const URL = "http://localhost/place-order";
const H = { "content-type": "application/json" };
const OK_REST = "11111111-1111-4111-8111-111111111111";
const OK_ADDR = "22222222-2222-4222-8222-222222222222";

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, { method: "POST", headers: { ...H, ...headers }, body: JSON.stringify(body) });
}

Deno.test("place-order: 405 on non-POST", async () => {
  const r = await handler(new Request(URL, { method: "GET" }));
  assertEquals(r.status, 405);
});

Deno.test("place-order: 400 missing idempotency", async () => {
  const r = await handler(post({ restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "cod", items: [] }));
  assertEquals(r.status, 400);
});

Deno.test("place-order: 400 missing required fields", async () => {
  const r = await handler(post({}, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 400);
});

Deno.test("place-order: 400 invalid payment_method", async () => {
  const r = await handler(post({
    restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "bitcoin",
    items: [{ name: "Nasi", unit_price: 20000, quantity: 1 }],
  }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 400);
});

Deno.test("place-order: 400 empty items", async () => {
  const r = await handler(post({
    restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "cod", items: [],
  }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 400);
});

Deno.test("place-order: 400 BR-STOCK-002 quantity too high", async () => {
  const r = await handler(post({
    restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "cod",
    items: [{ name: "Nasi", unit_price: 20000, quantity: 100 }],
  }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 400);
  const b = await r.json();
  assertEquals(b.error.rule, "BR-STOCK-002");
});

Deno.test("place-order: 400 BR-PRICE-005 min order value", async () => {
  const r = await handler(post({
    restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "cod",
    items: [{ name: "Es Teh", unit_price: 5000, quantity: 1 }], // 5000 < 15000
  }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 400);
  const b = await r.json();
  assertEquals(b.error.rule, "BR-PRICE-005");
});

Deno.test("place-order: 400 BR-PRICE-003 discount > subtotal+fees", async () => {
  const r = await handler(post({
    restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "cod",
    items: [{ name: "Nasi", unit_price: 20000, quantity: 1 }],
    discount: 100000,
  }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 400);
  const b = await r.json();
  assertEquals(b.error.rule, "BR-PRICE-003");
});

Deno.test("place-order: dry-run 200 returns order with computed total", async () => {
  const r = await handler(post({
    restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "ewallet",
    items: [{ name: "Nasi Goreng", unit_price: 25000, quantity: 2 }],
    delivery_fee: 6000, service_fee: 2000,
  }, { "x-idempotency-key": "idem-1" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.order.status, "placed");
  assertEquals(b.data.order.subtotal, 50000);
  assertEquals(b.data.order.total, 58000); // 50000 + 6000 + 2000 - 0
  assertEquals(b.data.order.idempotency_key, "idem-1");
  assertEquals(b.data.dry_run, true);
});

Deno.test("place-order: dry-run computes subtotal from items when omitted", async () => {
  const r = await handler(post({
    restaurant_id: OK_REST, address_id: OK_ADDR, payment_method: "cod",
    items: [{ name: "A", unit_price: 20000, quantity: 2 }, { name: "B", unit_price: 10000, quantity: 1 }],
  }, { "x-idempotency-key": "k" }));
  assertEquals(r.status, 200);
  const b = await r.json();
  assertEquals(b.data.order.subtotal, 50000);
});
