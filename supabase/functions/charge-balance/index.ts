// Edge Function: charge-balance
// Charges the remaining 50% balance to the client's saved payment method.
// Called from the admin dashboard. Sends receipt emails to owner + client.

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

    // Guard: only charge if deposit paid and balance > 0
    if (quote.status !== 'deposit_paid' || quote.balance_cents <= 0) {
      return new Response(
        JSON.stringify({ error: 'Quote is not eligible for balance charge.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!quote.stripe_customer_id || !quote.stripe_payment_method_id) {
      return new Response(
        JSON.stringify({ error: 'Missing Stripe customer or payment method.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Charge balance off-session using saved payment method
    const paymentIntent = await stripe.paymentIntents.create({
      amount: quote.balance_cents,
      currency: 'usd',
      customer: quote.stripe_customer_id,
      payment_method: quote.stripe_payment_method_id,
      off_session: true,
      confirm: true,
      metadata: {
        quote_id: quote.id,
        is_balance: 'true',
      },
    });

    if (paymentIntent.status !== 'succeeded') {
      return new Response(
        JSON.stringify({ error: `Payment status: ${paymentIntent.status}` }),
        { status: 402, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Update quote status
    const { error: updateError } = await supabase
      .from('quotes')
      .update({ status: 'fully_paid' })
      .eq('id', quoteId);

    if (updateError) {
      console.error('Failed to update quote status:', updateError);
      return new Response(
        JSON.stringify({ error: 'Payment succeeded but failed to update quote status. Contact support.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    logEvent(quoteId, 'balance_charged', { amount_cents: quote.balance_cents });

    // Email owner
    await sendEmail(
      NOTIFICATION_EMAIL,
      `✅ Balance received — ${quote.client_name}`,
      `
        <h2>Final balance received</h2>
        <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
        <p><strong>Business:</strong> ${quote.business_name}</p>
        <p><strong>Amount charged:</strong> ${fmt(quote.balance_cents)}</p>
        <p><strong>Project is now fully paid.</strong></p>
        <p><strong>Quote ID:</strong> ${quote.id}</p>
      `,
    );

    // Client launch email is sent by stripe-webhook handleBalancePaid
    // (fires on payment_intent.succeeded with is_balance=true) — not sent here to avoid duplicate.

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('charge-balance error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
