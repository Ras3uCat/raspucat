// Edge Function: admin-provision-outreach-email
// One-time setup: creates the Cloudflare Email Routing rule for hello@raspucat.com
// pointing inbound email to the raspucat-email-worker Worker.
//
// Prerequisites:
//   1. raspucat-email-worker must be deployed via `wrangler deploy`
//   2. CLOUDFLARE_ZONE_ID and CLOUDFLARE_API_TOKEN must be set as Supabase secrets
//
// Invoke once:
//   supabase functions invoke admin-provision-outreach-email \
//     --body '{"adminToken":"YOUR_ADMIN_PASSWORD"}'
//
// Idempotent — returns the existing rule if hello@raspucat.com is already routed.

const OUTREACH_EMAIL = 'hello@raspucat.com';
const WORKER_NAME = 'raspucat-email-worker';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function cfGet(path: string, token: string) {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  return res.json();
}

async function cfPost(path: string, token: string, body: unknown) {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { ok: res.ok, data: await res.json() };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { adminToken } = await req.json();
    if (adminToken !== Deno.env.get('ADMIN_PASSWORD')) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    const zoneId = Deno.env.get('CLOUDFLARE_ZONE_ID');
    const token = Deno.env.get('CLOUDFLARE_API_TOKEN');

    if (!zoneId || !token) {
      return json({ error: 'CLOUDFLARE_ZONE_ID and CLOUDFLARE_API_TOKEN must be set.' }, 500);
    }

    // Check if a rule already exists for hello@raspucat.com
    const existing = await cfGet(`/zones/${zoneId}/email/routing/rules`, token);
    const existingRule = existing.result?.find((r: { matchers?: { value: string }[] }) =>
      r.matchers?.some((m: { value: string }) => m.value === OUTREACH_EMAIL)
    );

    if (existingRule) {
      return json({
        success: true,
        already_exists: true,
        rule_id: existingRule.id,
        email: OUTREACH_EMAIL,
      });
    }

    // Create the routing rule → Worker
    const { ok, data } = await cfPost(
      `/zones/${zoneId}/email/routing/rules`,
      token,
      {
        name: `Outreach: ${OUTREACH_EMAIL}`,
        enabled: true,
        matchers: [{ type: 'literal', field: 'to', value: OUTREACH_EMAIL }],
        actions: [{ type: 'worker', value: [WORKER_NAME] }],
      },
    );

    if (!ok || !data.result?.id) {
      console.error('Cloudflare API error:', JSON.stringify(data));
      return json(
        { error: data.errors?.[0]?.message ?? 'Cloudflare API error', details: data },
        500,
      );
    }

    return json({
      success: true,
      rule_id: data.result.id,
      email: OUTREACH_EMAIL,
      worker: WORKER_NAME,
    });
  } catch (err) {
    console.error('admin-provision-outreach-email error:', err);
    return json({ error: (err as Error).message ?? 'Internal server error.' }, 500);
  }
});
