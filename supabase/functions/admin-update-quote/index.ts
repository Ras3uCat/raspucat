// Edge Function: admin-update-quote
// Updates a pending quote's fields.
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
      quoteId,
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

    // Fetch existing quote
    const { data: existing, error: fetchError } = await supabase
      .from('quotes')
      .select('id, status')
      .eq('id', quoteId)
      .single();

    if (fetchError || !existing) {
      return new Response(
        JSON.stringify({ error: 'Quote not found.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (existing.status !== 'pending') {
      return new Response(
        JSON.stringify({ error: 'Only pending quotes can be edited.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const resolvedSetupTotal = isComped ? 0 : setupTotalCents;
    const depositCents = isComped ? 0 : Math.floor(resolvedSetupTotal / 2);
    const balanceCents = isComped ? 0 : resolvedSetupTotal - depositCents;

    const { error: updateError } = await supabase
      .from('quotes')
      .update({
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
      })
      .eq('id', quoteId);

    if (updateError) {
      console.error('admin-update-quote update error:', updateError);
      return new Response(
        JSON.stringify({ error: 'Failed to update quote.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    logEvent(quoteId, 'quote_updated', { plan_id: planId });

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-update-quote error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
