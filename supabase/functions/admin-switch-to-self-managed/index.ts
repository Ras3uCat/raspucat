// Edge Function: admin-switch-to-self-managed
// Switches an active client to the Self-Managed option.
// Checks 12-month loyalty waiver: if subscription_started_at >= 12 months ago, fee is $0.
// Otherwise fee is $800 (admin invoices separately via Stripe dashboard).
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

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const FROM_EMAIL = Deno.env.get('RESEND_FROM_EMAIL') ?? 'onboarding@resend.dev';
const LOGO_URL = Deno.env.get('LOGO_URL') ?? 'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ryan@raspucat.com';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function logEvent(quoteId: string, eventType: string, metadata: Record<string, unknown> = {}): void {
  supabase.from('quote_events').insert({ quote_id: quoteId, event_type: eventType, metadata }).then(() => {}).catch(console.error);
}

function monthsSince(isoDate: string): number {
  const start = new Date(isoDate);
  const now = new Date();
  return (now.getFullYear() - start.getFullYear()) * 12 + (now.getMonth() - start.getMonth());
}

function themedEmail(contentHtml: string): string {
  return `<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#000612;font-family:'Inter',sans-serif;">
<div style="max-width:600px;margin:0 auto;padding:40px 24px;">
  <div style="text-align:center;padding-bottom:28px;border-bottom:1px solid rgba(88,227,239,0.12);">
    <img src="${LOGO_URL}" alt="Raspucat" style="height:56px;width:auto;display:block;margin:0 auto 12px;" />
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;letter-spacing:5px;color:#58E3EF;margin:0 0 6px;text-transform:uppercase;">Ras3uCat</p>
  </div>
  <div style="padding:40px 0 32px;">${contentHtml}</div>
  <div style="padding-top:28px;border-top:1px solid rgba(88,227,239,0.08);">
    <p style="color:rgba(232,254,255,0.4);font-size:13px;margin:0 0 4px;">With precision,</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;color:#58E3EF;margin:0;letter-spacing:1px;">Meow</p>
  </div>
</div>
</body>
</html>`;
}

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) return;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
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
        JSON.stringify({ error: 'No active subscription found on this quote.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (quote.management_option_id === 'handover') {
      return new Response(
        JSON.stringify({ error: 'Quote is already set to Self-Managed.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // 12-month waiver check
    const monthsActive = quote.subscription_started_at
      ? monthsSince(quote.subscription_started_at as string)
      : 0;
    const feeWaived = monthsActive >= 12;
    const feeCents = feeWaived ? 0 : 80000;

    // Cancel the Stripe subscription immediately
    await stripe.subscriptions.cancel(quote.stripe_subscription_id);

    const now = new Date().toISOString();

    const { error: updateError } = await supabase
      .from('quotes')
      .update({
        status: 'cancelled',
        cancelled_at: now,
        management_option_id: 'handover',
        billing_cycle: 'onetime',
        handoff_fee_cents: feeCents,
        stripe_subscription_id: null,
        subscription_started_at: null,
      })
      .eq('id', quoteId);

    if (updateError) {
      console.error('admin-switch-to-self-managed update error:', updateError);
      return new Response(
        JSON.stringify({ error: 'Subscription cancelled but DB update failed. Contact support.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    logEvent(quoteId, 'switched_to_self_managed', {
      months_active: monthsActive,
      fee_waived: feeWaived,
      fee_cents: feeCents,
      subscription_id: quote.stripe_subscription_id,
    });

    // Trigger handoff package email to client (fire-and-forget)
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    fetch(`${supabaseUrl}/functions/v1/admin-send-handoff`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${serviceKey}` },
      body: JSON.stringify({ quoteId, action: 'client_package' }),
    }).catch((err) => console.error('admin-send-handoff client_package failed:', err));

    // Admin notification email
    const feeNote = feeWaived
      ? `<p style="color:#58E3EF;">✅ Loyalty waiver applied — ${monthsActive} months active. No fee charged.</p>`
      : `<p style="color:#FFCC00;">⚠️ Fee due: <strong>$800</strong> — client was active for ${monthsActive} months (under 12). Invoice manually via Stripe dashboard.</p>`;

    sendEmail(
      ADMIN_EMAIL,
      `[Raspucat] ${quote.business_name ?? quote.client_name} switched to Self-Managed`,
      themedEmail(`
        <h2 style="color:#E8FEFF;font-size:20px;margin:0 0 16px;">Self-Managed Switch</h2>
        <p style="color:rgba(232,254,255,0.7);font-size:15px;margin:0 0 8px;">
          <strong style="color:#E8FEFF;">${quote.business_name ?? quote.client_name}</strong>
          has been switched to Self-Managed.
        </p>
        ${feeNote}
        <p style="color:rgba(232,254,255,0.5);font-size:13px;margin:16px 0 0;">Quote ID: ${quoteId}</p>
      `),
    ).catch(console.error);

    return new Response(
      JSON.stringify({ success: true, feeWaived, feeCents, monthsActive }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-switch-to-self-managed error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
