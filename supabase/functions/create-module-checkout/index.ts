// Edge Function: create-module-checkout
// Two modes:
//   1. Prepare  { quote_id, module_id }               → creates PaymentIntent, returns card info
//   2. Confirm  { quote_id, module_id, payment_intent_id } → confirms off-session with saved card

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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // ── Input ─────────────────────────────────────────────────────────────────────
  const { quote_id, module_id, payment_intent_id } = await req.json() as {
    quote_id: string;
    module_id: string;
    payment_intent_id?: string;
  };

  if (!quote_id || !module_id) {
    return new Response(JSON.stringify({ error: 'quote_id and module_id are required.' }), {
      status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // ── Fetch quote (scoped to authenticated user) ────────────────────────────────
  const { data: quote, error: quoteError } = await supabase
    .from('quotes')
    .select('*')
    .eq('id', quote_id)
    .eq('user_id', user.id)
    .maybeSingle();

  if (quoteError || !quote) {
    return new Response(JSON.stringify({ error: 'Quote not found.' }), {
      status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  if (!quote.stripe_customer_id) {
    return new Response(JSON.stringify({ error: 'No payment method on file.' }), {
      status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // ── Guard: not already owned ──────────────────────────────────────────────────
  if ((quote.module_ids ?? []).includes(module_id)) {
    return new Response(JSON.stringify({ error: 'Module already included in your plan.' }), {
      status: 409, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // ── Guard: not already pending ────────────────────────────────────────────────
  const { data: existing } = await supabase
    .from('client_modules_pending')
    .select('id')
    .eq('quote_id', quote_id)
    .eq('module_id', module_id)
    .maybeSingle();

  if (existing) {
    return new Response(JSON.stringify({ error: 'Module already purchased.' }), {
      status: 409, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // ── Fetch module ──────────────────────────────────────────────────────────────
  const { data: module, error: modError } = await supabase
    .from('modules')
    .select('*')
    .eq('id', module_id)
    .maybeSingle();

  if (modError || !module) {
    return new Response(JSON.stringify({ error: 'Module not found.' }), {
      status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const metadata = { type: 'module_addon', quote_id: quote.id, module_id: module.id };

  // ── MODE 2: Confirm existing PaymentIntent with saved card ────────────────────
  if (payment_intent_id && quote.stripe_payment_method_id) {
    try {
      const confirmed = await stripe.paymentIntents.confirm(payment_intent_id, {
        payment_method: quote.stripe_payment_method_id,
        off_session: true,
      });

      if (confirmed.status === 'succeeded') {
        // Webhook handles client_modules_pending insertion
        return new Response(JSON.stringify({ success: true }), {
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }

      // Needs 3DS — return clientSecret so Flutter can show the element
      return new Response(
        JSON.stringify({ clientSecret: confirmed.client_secret, requiresAction: true }),
        { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      );
    } catch (_) {
      // Card declined — return clientSecret for the form fallback
      const pi = await stripe.paymentIntents.retrieve(payment_intent_id);
      return new Response(
        JSON.stringify({ clientSecret: pi.client_secret, requiresAction: true }),
        { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      );
    }
  }

  // ── MODE 1: Prepare — create PaymentIntent + fetch saved card info ─────────────
  const paymentIntent = await stripe.paymentIntents.create({
    amount: module.price,
    currency: 'usd',
    customer: quote.stripe_customer_id,
    setup_future_usage: 'off_session',
    metadata,
  });

  // Fetch saved card details to show in the confirmation dialog
  let last4: string | null = null;
  let brand: string | null = null;
  if (quote.stripe_payment_method_id) {
    try {
      const pm = await stripe.paymentMethods.retrieve(quote.stripe_payment_method_id);
      last4 = pm.card?.last4 ?? null;
      brand = pm.card?.brand ?? null;
    } catch (_) {
      // Non-critical — dialog will just skip the saved card option
    }
  }

  return new Response(
    JSON.stringify({
      clientSecret: paymentIntent.client_secret,
      hasSavedCard: !!last4,
      last4,
      brand,
      paymentMethodId: quote.stripe_payment_method_id ?? null,
    }),
    { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
  );
});
