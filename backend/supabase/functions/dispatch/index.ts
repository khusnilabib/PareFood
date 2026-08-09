// dispatch Edge Function (skeleton)
// Accepts order_id and produces a dispatch decision. Idempotent via header.

export async function handler(req: Request): Promise<Response> {
  if (req.method !== 'POST') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { 'content-type': 'application/json' } });
  const idempotency = req.headers.get('x-idempotency-key');
  if (!idempotency) return new Response(JSON.stringify({ error: 'Missing X-Idempotency-Key header' }), { status: 400, headers: { 'content-type': 'application/json' } });
  let body:any; try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: { 'content-type': 'application/json' } }); }
  if (!body.order_id) return new Response(JSON.stringify({ error: 'Missing order_id' }), { status: 400, headers: { 'content-type': 'application/json' } });

  // Real implementation: run matching algorithm, create delivery row, notify drivers.
  const decision = { assigned: false, delivery_id: null };
  return new Response(JSON.stringify({ data: { order_id: body.order_id, decision, idempotency_key: idempotency } }), { status: 200, headers: { 'content-type': 'application/json' } });
}
export default { handler };
