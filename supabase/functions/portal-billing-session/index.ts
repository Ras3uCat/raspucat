// Edge Function: portal-billing-session
// Creates a Stripe Billing Portal session for the authenticated client.
// Accepts { quoteId } in the request body to scope the session to that
// specific subscription, preventing cross-project bleed on multi-project clients.

import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2026-01-28.clover',
});

const supabaseAdmin = createClient(
  SUPABASE_URL,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const JWKS = createRemoteJWKSet(
  new URL(`${SUPABASE_URL}/auth/v1/.well-known/jwks.json`),
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const jwt = authHeader.replace('Bearer ', '');

    if (!jwt) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    let userId: string;
    try {
      const { payload } = await jwtVerify(jwt, JWKS, {
        issuer: `${SUPABASE_URL}/auth/v1`,
        audience: 'authenticated',
      });
      userId = payload.sub as string;
    } catch (e) {
      console.error('JWT verification failed:', e);
      return new Response(
        JSON.stringify({ error: 'Unauthorized.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Read quoteId from body — used to scope the portal to the right subscription.
    let quoteId: string | null = null;
    try {
      const body = await req.json();
      quoteId = body?.quoteId ?? null;
    } catch (_) { /* body is optional */ }

    // Server-side authoritative lookup. If quoteId is provided, scope to that quote
    // (and verify it belongs to this user). Otherwise fall back to most recent quote.
    const query = supabaseAdmin
      .from('quotes')
      .select('stripe_customer_id, stripe_subscription_id')
      .eq('user_id', userId)
      .not('stripe_customer_id', 'is', null);

    const { data: quote, error: quoteError } = await (quoteId
      ? query.eq('id', quoteId)
      : query.order('created_at', { ascending: false }).limit(1)
    ).single();

    if (quoteError || !quote?.stripe_customer_id) {
      return new Response(
        JSON.stringify({ error: 'No billing account found.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const appUrl = Deno.env.get('APP_URL') ?? 'https://raspucat.com';
    const returnUrl = `${appUrl}/portal`;

    // Scope the session to the specific subscription when available.
    // This prevents multi-project clients seeing other projects' billing info.
    const sessionParams: Stripe.BillingPortal.SessionCreateParams = {
      customer: quote.stripe_customer_id,
      return_url: returnUrl,
    };

    if (quote.stripe_subscription_id) {
      sessionParams.flow_data = {
        type: 'subscription_update',
        subscription_update: {
          subscription: quote.stripe_subscription_id,
        },
      };
    }

    const session = await stripe.billingPortal.sessions.create(sessionParams);

    return new Response(
      JSON.stringify({ url: session.url }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('portal-billing-session error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
