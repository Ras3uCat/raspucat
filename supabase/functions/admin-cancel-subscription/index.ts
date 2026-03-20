// Edge Function: admin-cancel-subscription
// Cancels the active Stripe subscription for a quote and clears subscription fields in DB.
// Protected by ADMIN_PASSWORD env var.

import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const FROM_EMAIL = Deno.env.get('RESEND_FROM_EMAIL') ?? 'onboarding@resend.dev';
const LOGO_URL = Deno.env.get('LOGO_URL') ?? 'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) return;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
}

function themedEmail(contentHtml: string): string {
  return `<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#000612;font-family:'Inter',sans-serif;">
<div style="max-width:600px;margin:0 auto;padding:40px 24px;">
  <div style="text-align:center;padding-bottom:28px;border-bottom:1px solid rgba(88,227,239,0.12);">
    <img src="${LOGO_URL}" alt="Ras3uCat" style="height:56px;width:auto;display:block;margin:0 auto 12px;" />
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;letter-spacing:5px;color:#58E3EF;margin:0 0 6px;text-transform:uppercase;">Ras3uCat</p>
    <p style="font-size:10px;color:rgba(232,254,255,0.3);letter-spacing:2px;margin:0;text-transform:uppercase;">Building the future, one line of code at a time.</p>
  </div>
  <div style="padding:40px 0 32px;">${contentHtml}</div>
  <div style="padding-top:28px;border-top:1px solid rgba(88,227,239,0.08);">
    <p style="color:rgba(232,254,255,0.4);font-size:13px;margin:0 0 4px;">With precision,</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;color:#58E3EF;margin:0;letter-spacing:1px;">Meow</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:11px;color:rgba(232,254,255,0.2);margin:4px 0 0;letter-spacing:1px;">Ras3uCat</p>
  </div>
  <div style="text-align:center;padding-top:40px;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:rgba(88,227,239,0.2);margin:0;">Sync complete △ M3OW</p>
  </div>
</div>
</body>
</html>`;
}

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
    const { data: quote, error: quoteError } = await supabase
      .from('quotes')
      .select('*')
      .eq('id', quoteId)
      .single();

    if (quoteError || !quote) {
      return new Response(
        JSON.stringify({ error: 'Quote not found.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!quote.stripe_subscription_id) {
      return new Response(
        JSON.stringify({ error: 'Quote has no active subscription.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Cancel subscription in Stripe
    await stripe.subscriptions.cancel(quote.stripe_subscription_id);

    // Clear subscription fields in DB (preserve status as fully_paid)
    const { error: updateError } = await supabase
      .from('quotes')
      .update({
        stripe_subscription_id: null,
        subscription_started_at: null,
      })
      .eq('id', quoteId);

    if (updateError) {
      console.error('Failed to update quote after subscription cancel:', updateError);
      return new Response(
        JSON.stringify({ error: 'Subscription cancelled but failed to update quote. Contact support.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    logEvent(quoteId, 'subscription_cancelled', { subscription_id: quote.stripe_subscription_id });

    // Email client
    await sendEmail(
      quote.client_email,
      'Your management subscription has been cancelled',
      themedEmail(`
        <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Subscription Update</p>
        <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">Your subscription has been cancelled, ${quote.client_name}.</h1>
        <p style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0 0 28px;">
          Your management subscription for <strong style="color:#E8FEFF;">${quote.business_name}</strong> has been cancelled effective immediately. You will not be charged further.
        </p>
        <p style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0;">
          If you have any questions or believe this was done in error, please reach out and we'll sort it out right away.
        </p>
      `),
    );

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-cancel-subscription error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
