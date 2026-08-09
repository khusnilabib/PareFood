// process-payment Edge Function (skeleton)
// Expects payment_intent_id and action (charge/refund). Requires idempotency key.

export async function handler(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { 'content-type': 'application/json' } });
  }

  const idempotency = req.headers.get('x-idempotency-key');
  if (!idempotency) return new Response(JSON.stringify({ error: 'Missing X-Idempotency-Key header' }), { status: 400, headers: { 'content-type': 'application/json' } });

  let body: any;
  try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: { 'content-type': 'application/json' } }); }

  if (!body.payment_intent_id || !body.action) return new Response(JSON.stringify({ error: 'Missing payment_intent_id or action' }), { status: 400, headers: { 'content-type': 'application/json' } });

  // Skeleton: echo back
  return new Response(JSON.stringify({ data: { payment_intent_id: body.payment_intent_id, action: body.action, idempotency_key: idempotency } }), { status: 200, headers: { 'content-type': 'application/json' } });
}

export default { handler };
