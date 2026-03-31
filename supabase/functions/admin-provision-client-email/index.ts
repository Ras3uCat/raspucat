// Edge Function: admin-provision-client-email
// Called from admin panel when creating/saving a quote.
// 1. Derives a slug from the client/site name (lowercased, alphanumeric only, max 50 chars)
// 2. Checks quotes.client_slug for collisions — appends numeric suffix if taken
// 3. POSTs to Cloudflare Email Routing API to create a forwarding rule
// 4. Writes client_slug, provisioned_email, cloudflare_routing_rule_id, client_email_provisioned_at to quote
// Protected by ADMIN_PASSWORD.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function deriveSlug(name: string): string {
  return name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // strip accents
    .replace(/[^a-z0-9]/g, '')       // strip non-alphanumeric
    .slice(0, 50);
}

async function resolveUniqueSlug(baseSlug: string, excludeQuoteId?: string): Promise<string> {
  let candidate = baseSlug;
  let suffix = 2;

  while (true) {
    const query = supabase
      .from('quotes')
      .select('id')
      .eq('client_slug', candidate);

    if (excludeQuoteId) query.neq('id', excludeQuoteId);

    const { data } = await query.maybeSingle();
    if (!data) return candidate;

    candidate = `${baseSlug}${suffix}`;
    suffix++;
  }
}

async function createCloudflareRule(
  slug: string,
  clientName: string,
): Promise<{ ruleId: string; email: string }> {
  const zoneId = Deno.env.get('CLOUDFLARE_ZONE_ID')!;
  const token = Deno.env.get('CLOUDFLARE_API_TOKEN')!;
  const forwardTo = Deno.env.get('CLOUDFLARE_FORWARD_TO')!;
  const email = `${slug}@raspucat.com`;

  const resp = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/email/routing/rules`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: `Client: ${clientName}`,
        enabled: true,
        matchers: [{ type: 'literal', field: 'to', value: email }],
        actions: [{ type: 'forward', value: [forwardTo] }],
      }),
    },
  );

  const json = await resp.json();

  if (!resp.ok || !json.result?.id) {
    console.error('Cloudflare API error:', JSON.stringify(json));
    throw new Error(json.errors?.[0]?.message ?? 'Cloudflare API error');
  }

  return { ruleId: json.result.id as string, email };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { quoteId, clientName, slugOverride, adminToken } = await req.json();

    if (adminToken !== Deno.env.get('ADMIN_PASSWORD')) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!quoteId || !clientName) {
      return new Response(JSON.stringify({ error: 'quoteId and clientName are required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Fetch the quote to check if already provisioned
    const { data: quote, error: fetchErr } = await supabase
      .from('quotes')
      .select('id, provisioned_email, cloudflare_routing_rule_id, client_name')
      .eq('id', quoteId)
      .single();

    if (fetchErr || !quote) {
      return new Response(JSON.stringify({ error: 'Quote not found.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (quote.provisioned_email) {
      return new Response(
        JSON.stringify({ error: 'Email already provisioned.', provisioned_email: quote.provisioned_email }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Derive and deduplicate slug
    const baseSlug = slugOverride ? deriveSlug(slugOverride) : deriveSlug(clientName as string);
    if (!baseSlug) {
      return new Response(JSON.stringify({ error: 'Could not derive a valid slug from client name.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const slug = await resolveUniqueSlug(baseSlug, quoteId);

    // Create Cloudflare routing rule
    const { ruleId, email } = await createCloudflareRule(slug, clientName as string);

    // Persist to quote
    const { error: updateErr } = await supabase
      .from('quotes')
      .update({
        client_slug: slug,
        provisioned_email: email,
        cloudflare_routing_rule_id: ruleId,
        client_email_provisioned_at: new Date().toISOString(),
      })
      .eq('id', quoteId);

    if (updateErr) {
      console.error('Failed to persist provisioned email:', updateErr);
      return new Response(JSON.stringify({ error: 'Cloudflare rule created but DB write failed.', email, ruleId }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(
      JSON.stringify({ success: true, slug, provisioned_email: email, rule_id: ruleId }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-provision-client-email error:', err);
    return new Response(JSON.stringify({ error: (err as Error).message ?? 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
