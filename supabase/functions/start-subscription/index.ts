// Edge Function: start-subscription
// Creates a Stripe Subscription for a client using their saved payment method.
// Called from the admin dashboard when the site goes live.

import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2026-01-28.clover',
});

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const FROM_EMAIL = Deno.env.get('RESEND_FROM_EMAIL') ?? 'onboarding@resend.dev';
const NOTIFICATION_EMAIL = Deno.env.get('NOTIFICATION_EMAIL') ?? 'meow@raspucat.com';
const LOGO_URL = Deno.env.get('LOGO_URL') ?? 'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';
const CUSTOMER_PORTAL_URL = Deno.env.get('STRIPE_CUSTOMER_PORTAL_URL') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function logEvent(quoteId: string, eventType: string, metadata: Record<string, unknown> = {}): void {
  supabase.from('quote_events').insert({ quote_id: quoteId, event_type: eventType, metadata }).then(() => {}).catch(console.error);
}

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) {
    console.warn('RESEND_API_KEY not set — skipping email to', to);
    return;
  }
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
}

function fmt(cents: number): string {
  return `$${(cents / 100).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
}

function themedEmail(contentHtml: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600&family=Inter:wght@400;500&display=swap');
  </style>
</head>
<body style="margin:0;padding:0;background:#000612;font-family:'Inter',sans-serif;-webkit-font-smoothing:antialiased;">
<div style="max-width:600px;margin:0 auto;padding:40px 24px;">

  <!-- Header -->
  <div style="text-align:center;padding-bottom:28px;border-bottom:1px solid rgba(88,227,239,0.12);">
    <img src="${LOGO_URL}" alt="Ras3uCat" style="height:56px;width:auto;margin-bottom:12px;display:block;margin-left:auto;margin-right:auto;" />
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;letter-spacing:5px;color:#58E3EF;margin:0 0 6px;text-transform:uppercase;">Ras3uCat</p>
    <p style="font-size:10px;color:rgba(232,254,255,0.3);letter-spacing:2px;margin:0;text-transform:uppercase;">Building the future, one line of code at a time.</p>
  </div>

  <!-- Content -->
  <div style="padding:40px 0 32px;">
    ${contentHtml}
  </div>

  <!-- Signature -->
  <div style="padding-top:28px;border-top:1px solid rgba(88,227,239,0.08);">
    <p style="color:rgba(232,254,255,0.4);font-size:13px;margin:0 0 4px;">With precision,</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;color:#58E3EF;margin:0;letter-spacing:1px;">Meow</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:11px;color:rgba(232,254,255,0.2);margin:4px 0 0;letter-spacing:1px;">Ras3uCat</p>
  </div>

  <!-- Footer -->
  <div style="text-align:center;padding-top:40px;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:rgba(88,227,239,0.2);margin:0;">Sync complete △ M3OW</p>
  </div>

</div>
</body>
</html>`;
}

// Stripe Price IDs for each management plan + billing cycle.
// Create these in your Stripe Dashboard → Products and paste the price IDs here,
// or set them as environment variables.
const PRICE_IDS: Record<string, Record<string, string>> = {
  standard: {
    monthly: Deno.env.get('STRIPE_PRICE_STANDARD_MONTHLY') ?? '',
    annual: Deno.env.get('STRIPE_PRICE_STANDARD_ANNUAL') ?? '',
  },
  premium: {
    monthly: Deno.env.get('STRIPE_PRICE_PREMIUM_MONTHLY') ?? '',
    annual: Deno.env.get('STRIPE_PRICE_PREMIUM_ANNUAL') ?? '',
  },
};

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

    // Fetch quote
    const { data: quote, error: fetchError } = await supabase
      .from('quotes')
      .select('*')
      .eq('id', quoteId)
      .single();

    if (fetchError || !quote) {
      return new Response(
        JSON.stringify({ error: 'Quote not found.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Comped projects bypass Stripe entirely — mark active and exit.
    if (quote.is_comped) {
      await supabase.from('quotes').update({
        status: 'active',
        subscription_started_at: new Date().toISOString(),
      }).eq('id', quoteId);

      await supabase.from('quote_events').insert({
        quote_id: quoteId,
        event_type: 'quote_comped_activated',
      });

      // No email sent for comped activations (internal side projects only).
      return new Response(JSON.stringify({ comped: true }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Guard: only start subscription for eligible quotes
    if (quote.billing_cycle === 'onetime') {
      return new Response(
        JSON.stringify({ error: 'Handover & Docs does not have a subscription.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (quote.subscription_started_at) {
      return new Response(
        JSON.stringify({ error: 'Subscription already started.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!quote.stripe_customer_id || !quote.stripe_payment_method_id) {
      return new Response(
        JSON.stringify({ error: 'Missing Stripe customer or payment method.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Resolve Stripe Price ID
    const managementId = quote.management_option_id as string;
    const billingCycle = quote.billing_cycle as string;
    const priceId = PRICE_IDS[managementId]?.[billingCycle];

    if (!priceId) {
      return new Response(
        JSON.stringify({
          error: `No Stripe Price ID configured for ${managementId}/${billingCycle}. Set STRIPE_PRICE_${managementId.toUpperCase()}_${billingCycle.toUpperCase()} in secrets.`,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Set saved payment method as the customer default
    await stripe.customers.update(quote.stripe_customer_id, {
      invoice_settings: { default_payment_method: quote.stripe_payment_method_id },
    });

    // Create the subscription — apply promo code discount if one was used at checkout
    const subscriptionParams: Stripe.SubscriptionCreateParams = {
      customer: quote.stripe_customer_id,
      items: [{ price: priceId }],
      default_payment_method: quote.stripe_payment_method_id,
      metadata: { quote_id: quote.id },
    };
    if (quote.subscription_promotion_code_id) {
      subscriptionParams.discounts = [{ promotion_code: quote.subscription_promotion_code_id }];
    }
    const subscription = await stripe.subscriptions.create(subscriptionParams);

    // Update quote with subscription details
    const now = new Date().toISOString();
    await supabase
      .from('quotes')
      .update({
        stripe_subscription_id: subscription.id,
        subscription_started_at: now,
        activated_at: now,
        status: 'active',
      })
      .eq('id', quoteId);

    logEvent(quote.id, 'subscription_started', { subscription_id: subscription.id, billing_cycle: billingCycle });

    const cycleLabel = billingCycle === 'annual' ? '/yr' : '/mo';
    const billingAmount = billingCycle === 'annual'
      ? fmt((subscription.items.data[0]?.price?.unit_amount ?? 0))
      : fmt((subscription.items.data[0]?.price?.unit_amount ?? 0));

    // Email owner
    await sendEmail(
      NOTIFICATION_EMAIL,
      `🚀 Subscription started — ${quote.client_name}`,
      `
        <h2>Subscription activated</h2>
        <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
        <p><strong>Business:</strong> ${quote.business_name}</p>
        <p><strong>Plan:</strong> ${managementId} (${billingCycle})</p>
        <p><strong>Subscription ID:</strong> ${subscription.id}</p>
      `,
    );

    // Email client
    const portalBlock = CUSTOMER_PORTAL_URL
      ? `<div style="text-align:center;margin-bottom:24px;"><a href="${CUSTOMER_PORTAL_URL}" style="display:inline-block;padding:12px 28px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58E3EF;font-family:'Space Grotesk',sans-serif;font-size:13px;letter-spacing:1px;text-decoration:none;">Manage Subscription</a></div>`
      : '';

    await sendEmail(
      quote.client_email,
      `Your site is live — subscription active`,
      themedEmail(`
        <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">We Have Liftoff</p>
        <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">Your site is live, ${quote.client_name}.</h1>
        <p style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0 0 28px;">
          Your management subscription is now active. We're in your corner — monitoring, maintaining, and improving your site from here on out.
        </p>
        <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:24px;margin-bottom:16px;">
          <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 16px;text-transform:uppercase;">Subscription Details</p>
          <table style="width:100%;border-collapse:collapse;">
            <tr>
              <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:10px;">Plan</td>
              <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:10px;">${managementId.charAt(0).toUpperCase() + managementId.slice(1)}</td>
            </tr>
            <tr>
              <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Billing</td>
              <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;">${billingAmount}${cycleLabel}</td>
            </tr>
            <tr>
              <td style="padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Status</td>
              <td style="padding-top:10px;color:#58E3EF;font-size:13px;font-weight:500;text-align:right;">Active ✓</td>
            </tr>
          </table>
        </div>
        ${portalBlock}
        <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0;">
          Your billing cycle renews automatically.${CUSTOMER_PORTAL_URL ? ' You can update your payment method or manage your subscription at any time via the link above.' : ' If you ever need to update your payment method, just reach out.'}
        </p>
      `),
    );

    return new Response(
      JSON.stringify({ success: true, subscriptionId: subscription.id }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('start-subscription error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
