// place-order Edge Function (skeleton)
// Minimal validation + idempotency header handling

export async function handler(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { 'content-type': 'application/json' } });
  }

  const idempotency = req.headers.get('x-idempotency-key');
  if (!idempotency) {
    return new Response(JSON.stringify({ error: 'Missing X-Idempotency-Key header' }), { status: 400, headers: { 'content-type': 'application/json' } });
  }

  let body: any;
  try {
    body = await req.json();
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400, headers: { 'content-type': 'application/json' } });
  }

  // Basic validation (skeleton): require cart and address
  if (!body.cart || !body.address_id || !body.payment_method) {
    return new Response(JSON.stringify({ error: 'Missing required fields: cart, address_id, payment_method' }), { status: 400, headers: { 'content-type': 'application/json' } });
  }

  // Real implementation: validate price, stock, hours; check idempotency store; insert order + items; create payment_intent; return order + payment_intent
  // For skeleton, echo back idempotency key and received payload summary
  const result = {
    order: {
      id: crypto.randomUUID(),
      idempotency_key: idempotency,
      subtotal: body.subtotal ?? 0,
      total: body.total ?? 0,
    },
    message: 'Skeleton place-order executed (no DB side-effects in test env)'
  };

  return new Response(JSON.stringify({ data: result }), { status: 200, headers: { 'content-type': 'application/json' } });
}

// Default export for supabase function compatibility
export default { handler };
