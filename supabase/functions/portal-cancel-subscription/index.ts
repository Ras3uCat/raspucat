// Edge Function: portal-cancel-subscription
// Called by the authenticated portal user to set cancel_at_period_end=true.
// Writes delivery_email to the quote and returns the period_end timestamp.
//
// Auth: JWT from the portal user session (Supabase auth).
// Body: { quoteId, deliveryEmail }

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

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    // Verify portal user session
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Authentication required.' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authErr } = await userClient.auth.getUser();
    if (authErr || !user) {
      return new Response(JSON.stringify({ error: 'Invalid session.' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { quoteId, deliveryEmail } = await req.json() as {
      quoteId: string;
      deliveryEmail: string;
    };

    if (!quoteId) {
      return new Response(JSON.stringify({ error: 'quoteId is required.' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!deliveryEmail || !EMAIL_PATTERN.test(deliveryEmail)) {
      return new Response(JSON.stringify({ error: 'A valid delivery email is required.' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Fetch quote and verify ownership
    const { data: quote, error: quoteErr } = await supabase
      .from('quotes')
      .select('id, user_id, stripe_subscription_id, subscription_cancel_at, status')
      .eq('id', quoteId)
      .single();

    if (quoteErr || !quote) {
      return new Response(JSON.stringify({ error: 'Quote not found.' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (quote.user_id !== user.id) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!quote.stripe_subscription_id) {
      return new Response(JSON.stringify({ error: 'No active subscription found.' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (quote.status === 'cancelled') {
      return new Response(JSON.stringify({ error: 'Subscription is already cancelled.' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (quote.subscription_cancel_at) {
      // Already scheduled — return the existing date
      return new Response(JSON.stringify({
        success: true,
        period_end: quote.subscription_cancel_at,
        already_scheduled: true,
      }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Set cancel_at_period_end on the Stripe subscription
    const subscription = await stripe.subscriptions.update(
      quote.stripe_subscription_id as string,
      { cancel_at_period_end: true },
    );

    const periodEnd = new Date(subscription.current_period_end * 1000).toISOString();

    // Write delivery_email and subscription_cancel_at to the quote
    await supabase
      .from('quotes')
      .update({
        delivery_email: deliveryEmail.trim().toLowerCase(),
        subscription_cancel_at: periodEnd,
      })
      .eq('id', quoteId);

    return new Response(JSON.stringify({ success: true, period_end: periodEnd }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('portal-cancel-subscription error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
