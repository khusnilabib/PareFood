// webhook-psp Edge Function (skeleton)
// Verifies signature (skeleton) and returns 200 ACK. Idempotent handling via header.

export async function handler(req: Request): Promise<Response> {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  // PSP webhooks typically signed; here we accept and echo header presence
  const signature = req.headers.get('x-psp-signature');
  if (!signature) return new Response(JSON.stringify({ error: 'Missing signature' }), { status: 400, headers: { 'content-type': 'application/json' } });

  let body:any; try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400, headers: { 'content-type': 'application/json' } }); }

  // Real implementation: verify signature, lookup payment_intent, mark succeeded/failed, idempotent.
  return new Response(JSON.stringify({ data: { received: true, event: body.event ?? null } }), { status: 200, headers: { 'content-type': 'application/json' } });
}

export default { handler };
