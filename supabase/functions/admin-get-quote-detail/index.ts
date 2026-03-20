// Edge Function: admin-get-quote-detail
// Returns full detail for a single quote, including module names and payment method info.
// Protected by ADMIN_PASSWORD env var.

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

// Reverse map: Stripe Price ID → human-readable plan label
function buildPriceLabels(): Record<string, string> {
  const map: Record<string, string> = {};
  const entries = [
    ['STRIPE_PRICE_STANDARD_MONTHLY', 'Standard Management — Monthly'],
    ['STRIPE_PRICE_STANDARD_ANNUAL',  'Standard Management — Annual'],
    ['STRIPE_PRICE_PREMIUM_MONTHLY',  'Premium Management — Monthly'],
    ['STRIPE_PRICE_PREMIUM_ANNUAL',   'Premium Management — Annual'],
  ] as const;
  for (const [envVar, label] of entries) {
    const id = Deno.env.get(envVar);
    if (id) map[id] = label;
  }
  return map;
}
const PRICE_LABELS = buildPriceLabels();

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { quoteId, adminToken } = await req.json();
    const adminPassword = Deno.env.get('ADMIN_PASSWORD');

    if (!adminPassword || adminToken !== adminPassword) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!quoteId) {
      return new Response(
        JSON.stringify({ error: 'quoteId is required.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Fetch quote with management option details
    const { data: quote, error: quoteError } = await supabase
      .from('quotes')
      .select('*, management_options(name, monthly_price, annual_price, onetime_price)')
      .eq('id', quoteId)
      .single();

    if (quoteError || !quote) {
      return new Response(
        JSON.stringify({ error: 'Quote not found.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Fetch module names
    const moduleIds: string[] = quote.module_ids ?? [];
    let modules: { id: string; name: string }[] = [];

    if (moduleIds.length > 0) {
      const { data: moduleRows } = await supabase
        .from('modules')
        .select('id, name')
        .in('id', moduleIds);
      modules = moduleRows ?? [];
    }

    // Fetch activity events
    const { data: events } = await supabase
      .from('quote_events')
      .select('event_type, metadata, created_at')
      .eq('quote_id', quoteId)
      .order('created_at', { ascending: false });

    // Retrieve payment method + subscription from Stripe (best-effort, parallel)
    let paymentMethodLast4: string | null = null;
    let paymentMethodBrand: string | null = null;
    let currentPeriodEnd: string | null = null;
    let pendingChangeDescription: string | null = null;
    let pendingChangeDate: string | null = null;

    const stripePromises: Promise<void>[] = [];

    if (quote.stripe_payment_method_id) {
      stripePromises.push(
        stripe.paymentMethods.retrieve(quote.stripe_payment_method_id).then((pm) => {
          paymentMethodLast4 = pm.card?.last4 ?? null;
          paymentMethodBrand = pm.card?.brand ?? null;
        }).catch(() => {}),
      );
    }

    if (quote.stripe_subscription_id) {
      stripePromises.push(
        stripe.subscriptions.retrieve(quote.stripe_subscription_id).then(async (sub) => {
          currentPeriodEnd = new Date(sub.current_period_end * 1000).toISOString();

          // Portal end-of-period changes create a Subscription Schedule.
          // Check phases beyond the current one for upcoming plan changes.
          if (sub.schedule) {
            try {
              const scheduleId = typeof sub.schedule === 'string'
                ? sub.schedule : (sub.schedule as { id: string })?.id;
              // Expand price so we can read its nickname directly — no env var dependency.
              const schedule = await stripe.subscriptionSchedules.retrieve(scheduleId!, {
                expand: ['phases.items.price'],
              });
              const now = Math.floor(Date.now() / 1000);
              const futurePhase = schedule.phases.find((p) => p.start_date > now);
              if (futurePhase) {
                pendingChangeDate = new Date(futurePhase.start_date * 1000).toISOString();
                const priceObj = futurePhase.items?.[0]?.price as { id: string; nickname?: string | null } | string | undefined;
                const nickname = typeof priceObj === 'object' ? priceObj?.nickname : null;
                const priceId = typeof priceObj === 'string' ? priceObj : priceObj?.id;
                pendingChangeDescription = nickname
                  ?? (priceId ? (PRICE_LABELS[priceId] ?? `Plan change (${priceId})`) : 'Subscription change scheduled');
              }
            } catch (_) { /* non-fatal */ }
          }
        }).catch(() => {}),
      );
    }

    await Promise.all(stripePromises);

    // Fallback for immediate plan changes (no Stripe schedule): read from the most recent
    // subscription_plan_changed event logged by the webhook.
    if (!pendingChangeDescription && events) {
      const planEvent = (events as { event_type: string; metadata: Record<string, unknown>; created_at: string }[])
        .find(e => e.event_type === 'subscription_plan_changed');
      if (planEvent?.metadata?.changeDescription) {
        pendingChangeDescription = planEvent.metadata.changeDescription as string;
        pendingChangeDate = planEvent.created_at;
      }
    }

    // Flatten management_options and compute subscription_amount_cents
    type MgmtOption = { name: string; monthly_price: number; annual_price: number; onetime_price: number };
    const mgmt = quote.management_options as MgmtOption | null;
    const managementOptionName = mgmt?.name ?? null;

    let subscriptionAmountCents = 0;
    if (mgmt) {
      if (quote.billing_cycle === 'monthly') subscriptionAmountCents = mgmt.monthly_price;
      else if (quote.billing_cycle === 'annual') subscriptionAmountCents = mgmt.annual_price;
      else if (quote.billing_cycle === 'onetime') subscriptionAmountCents = mgmt.onetime_price;
    }

    // Strip nested relation object before spreading
    const { management_options: _mgmt, ...flatQuote } = quote;

    return new Response(
      JSON.stringify({
        quote: {
          ...flatQuote,
          management_option_name: managementOptionName,
          subscription_amount_cents: subscriptionAmountCents,
          modules,
          payment_method_last4: paymentMethodLast4,
          payment_method_brand: paymentMethodBrand,
          current_period_end: currentPeriodEnd,
          pending_change_description: pendingChangeDescription,
          pending_change_date: pendingChangeDate,
          events: events ?? [],
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-get-quote-detail error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
