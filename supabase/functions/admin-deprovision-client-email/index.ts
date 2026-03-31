// Edge Function: admin-deprovision-client-email
// Deletes the Cloudflare Email Routing rule for a quote and clears the provisioned email columns.
// Called by:
//   - admin panel (manual early deprovision from quote detail drawer)
//   - cleanup-expired-client-emails cron (auto, 90 days post-cancellation)
// Protected by ADMIN_PASSWORD or SERVICE_ROLE_KEY (cron uses service role).

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function isAuthorized(req: Request, body: Record<string, unknown>): boolean {
  const authHeader = req.headers.get('Authorization') ?? '';
  const bearer = authHeader.replace('Bearer ', '');
  return (
    bearer === Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ||
    body.adminToken === Deno.env.get('ADMIN_PASSWORD')
  );
}

async function deleteCloudflareRule(ruleId: string): Promise<void> {
  const zoneId = Deno.env.get('CLOUDFLARE_ZONE_ID')!;
  const token = Deno.env.get('CLOUDFLARE_API_TOKEN')!;

  const resp = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/email/routing/rules/${ruleId}`,
    {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  if (!resp.ok) {
    const json = await resp.json().catch(() => ({}));
    throw new Error(json.errors?.[0]?.message ?? `Cloudflare DELETE failed: ${resp.status}`);
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json();

    if (!isAuthorized(req, body)) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { quoteId } = body;
    if (!quoteId) {
      return new Response(JSON.stringify({ error: 'quoteId is required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: quote, error: fetchErr } = await supabase
      .from('quotes')
      .select('id, provisioned_email, cloudflare_routing_rule_id')
      .eq('id', quoteId)
      .single();

    if (fetchErr || !quote) {
      return new Response(JSON.stringify({ error: 'Quote not found.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!quote.cloudflare_routing_rule_id) {
      return new Response(
        JSON.stringify({ success: true, message: 'No routing rule to deprovision.' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Delete Cloudflare rule
    await deleteCloudflareRule(quote.cloudflare_routing_rule_id as string);

    // Clear provisioned email columns (retain client_slug — useful for audit/history)
    await supabase
      .from('quotes')
      .update({
        provisioned_email: null,
        cloudflare_routing_rule_id: null,
      })
      .eq('id', quoteId);

    console.log(`Deprovisioned email for quote ${quoteId}: ${quote.provisioned_email}`);

    return new Response(
      JSON.stringify({ success: true, deprovisioned_email: quote.provisioned_email }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-deprovision-client-email error:', err);
    return new Response(JSON.stringify({ error: (err as Error).message ?? 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
