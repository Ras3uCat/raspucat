// Edge Function: cleanup-expired-client-emails
// Scheduled daily by Supabase cron.
// Deprovisions Cloudflare routing rules for quotes that have been cancelled
// for more than 90 days and still have an active routing rule.
// Protected by SERVICE_ROLE_KEY (cron only — not exposed to admin panel).

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const authHeader = req.headers.get('Authorization') ?? '';
  if (authHeader.replace('Bearer ', '') !== Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    // Find quotes cancelled > 90 days ago that still have a routing rule
    const { data: expired, error } = await supabase
      .from('quotes')
      .select('id, provisioned_email, cloudflare_routing_rule_id')
      .not('cloudflare_routing_rule_id', 'is', null)
      .not('cancelled_at', 'is', null)
      .lt('cancelled_at', new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString());

    if (error) throw error;

    if (!expired || expired.length === 0) {
      return new Response(
        JSON.stringify({ success: true, deprovisioned: 0 }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    console.log(`cleanup-expired-client-emails: ${expired.length} quotes to deprovision`);

    const results = await Promise.allSettled(
      expired.map((quote) =>
        fetch(`${SUPABASE_URL}/functions/v1/admin-deprovision-client-email`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
          },
          body: JSON.stringify({ quoteId: quote.id }),
        })
      ),
    );

    const succeeded = results.filter((r) => r.status === 'fulfilled').length;
    const failed = results.filter((r) => r.status === 'rejected').length;

    console.log(`cleanup-expired-client-emails: ${succeeded} succeeded, ${failed} failed`);

    return new Response(
      JSON.stringify({ success: true, deprovisioned: succeeded, failed }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('cleanup-expired-client-emails error:', err);
    return new Response(JSON.stringify({ error: (err as Error).message ?? 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
