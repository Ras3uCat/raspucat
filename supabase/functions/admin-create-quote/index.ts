// Edge Function: admin-create-quote
// Creates a new quote in pending status.
// Protected by ADMIN_PASSWORD env var.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function logEvent(quoteId: string, eventType: string, metadata: Record<string, unknown> = {}): void {
  supabase.from('quote_events').insert({ quote_id: quoteId, event_type: eventType, metadata }).then(() => {}).catch(console.error);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const {
      adminToken,
      clientName,
      clientEmail,
      businessName,
      planId,
      moduleIds,
      managementOptionId,
      billingCycle,
      setupTotalCents,
      isComped = false,
    } = await req.json();

    const adminPassword = Deno.env.get('ADMIN_PASSWORD');
    if (!adminPassword || adminToken !== adminPassword) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Validate required fields
    if (!clientName || !clientEmail || !planId || (!isComped && !(setupTotalCents > 0))) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: clientName, clientEmail, planId, setupTotalCents.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const resolvedSetupTotal = isComped ? 0 : setupTotalCents;
    const depositCents = isComped ? 0 : Math.floor(resolvedSetupTotal / 2);
    const balanceCents = isComped ? 0 : resolvedSetupTotal - depositCents;

    const { data: quote, error } = await supabase
      .from('quotes')
      .insert({
        client_name: clientName,
        client_email: clientEmail,
        business_name: businessName ?? null,
        plan_id: planId,
        module_ids: moduleIds ?? [],
        management_option_id: managementOptionId ?? null,
        billing_cycle: billingCycle ?? null,
        setup_total_cents: resolvedSetupTotal,
        deposit_cents: depositCents,
        balance_cents: balanceCents,
        is_comped: isComped,
        status: 'pending',
      })
      .select()
      .single();

    if (error) {
      console.error('admin-create-quote insert error:', error);
      return new Response(
        JSON.stringify({ error: 'Failed to create quote.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    logEvent(quote.id, 'quote_created', { plan_id: planId, setup_total_cents: resolvedSetupTotal, is_comped: isComped });

    return new Response(
      JSON.stringify({ quote }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-create-quote error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
