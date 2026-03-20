// Edge Function: create-payment-intent
// Creates a Stripe Customer, a pending quote record in Supabase,
// and a PaymentIntent for the deposit amount.
// Returns: { clientSecret, quoteId }

import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2026-01-28.clover',
});

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
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const {
      clientName,
      clientEmail,
      businessName,
      planId,
      moduleIds,
      managementOptionId,
      billingCycle,
      setupTotalCents,
    } = await req.json();

    // --- Validate required fields ---
    if (!clientName || !clientEmail || !planId || !setupTotalCents) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // --- Calculate deposit ---
    // Always 50% of setup fee. Handover $400 is collected by admin at delivery.
    const depositCents = Math.floor(setupTotalCents / 2);
    const balanceCents = setupTotalCents - depositCents;

    // --- Find or create Stripe Customer ---
    const existingCustomers = await stripe.customers.list({ email: clientEmail, limit: 1 });
    const customer = existingCustomers.data.length > 0
      ? existingCustomers.data[0]
      : await stripe.customers.create({
          name: clientName,
          email: clientEmail,
          metadata: { businessName: businessName ?? '' },
        });

    // --- Create pending quote in Supabase ---
    const { data: quote, error: quoteError } = await supabase
      .from('quotes')
      .insert({
        client_name: clientName,
        client_email: clientEmail,
        business_name: businessName ?? '',
        plan_id: planId,
        module_ids: moduleIds ?? [],
        management_option_id: managementOptionId ?? null,
        billing_cycle: billingCycle ?? null,
        setup_total_cents: setupTotalCents,
        deposit_cents: depositCents,
        balance_cents: balanceCents,
        stripe_customer_id: customer.id,
        status: 'pending',
      })
      .select('id')
      .single();

    if (quoteError || !quote) {
      console.error('Quote insert error:', quoteError);
      return new Response(
        JSON.stringify({ error: 'Failed to create quote record.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    logEvent(quote.id, 'quote_created', { plan_id: planId, setup_total_cents: setupTotalCents });

    // --- Create Stripe PaymentIntent ---
    // setup_future_usage: 'off_session' saves the payment method to the customer
    // for the later balance charge and subscription creation.
    const paymentIntent = await stripe.paymentIntents.create({
      amount: depositCents,
      currency: 'usd',
      customer: customer.id,
      setup_future_usage: 'off_session',
      metadata: {
        quote_id: quote.id,
        plan_id: planId,
        is_deposit: 'true',
      },
    });

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        quoteId: quote.id,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('Unexpected error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
