// Edge Function: admin-add-module
// Charges the stored payment method for a new module and appends it to the quote.
// Protected by ADMIN_PASSWORD env var.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import Stripe from 'npm:stripe@14';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2026-01-28.clover',
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const FROM_EMAIL = Deno.env.get('RESEND_FROM_EMAIL') ?? 'onboarding@resend.dev';
const NOTIFICATION_EMAIL = Deno.env.get('NOTIFICATION_EMAIL') ?? 'meow@raspucat.com';
const LOGO_URL = Deno.env.get('LOGO_URL') ?? 'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';

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
  <div style="text-align:center;padding-bottom:28px;border-bottom:1px solid rgba(88,227,239,0.12);">
    <img src="${LOGO_URL}" alt="Ras3uCat" style="height:56px;width:auto;margin-bottom:12px;display:block;margin-left:auto;margin-right:auto;" />
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;letter-spacing:5px;color:#58E3EF;margin:0 0 6px;text-transform:uppercase;">Ras3uCat</p>
    <p style="font-size:10px;color:rgba(232,254,255,0.3);letter-spacing:2px;margin:0;text-transform:uppercase;">Designed to engage. Engineered to move. Deployed to perform.</p>
  </div>
  <div style="padding:40px 0 32px;">
    ${contentHtml}
  </div>
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

function logEvent(quoteId: string, eventType: string, metadata: Record<string, unknown> = {}): void {
  supabase.from('quote_events').insert({ quote_id: quoteId, event_type: eventType, metadata }).then(() => {}).catch(console.error);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { adminToken, quoteId, moduleId } = await req.json();

    const adminPassword = Deno.env.get('ADMIN_PASSWORD');
    if (!adminPassword || adminToken !== adminPassword) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Fetch quote
    const { data: quote, error: quoteError } = await supabase
      .from('quotes')
      .select('id, client_name, client_email, stripe_customer_id, stripe_payment_method_id, module_ids, site_url')
      .eq('id', quoteId)
      .single();

    if (quoteError || !quote) {
      return new Response(
        JSON.stringify({ error: 'Quote not found.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Guard: client must have paid deposit
    if (!quote.stripe_payment_method_id) {
      return new Response(
        JSON.stringify({ error: 'Client has not paid the deposit yet.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Guard: module must not already be on the quote
    const existingModuleIds: string[] = quote.module_ids ?? [];
    if (existingModuleIds.includes(moduleId)) {
      return new Response(
        JSON.stringify({ error: 'Module is already included in this quote.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Fetch module price
    const { data: module, error: moduleError } = await supabase
      .from('modules')
      .select('id, name, price')
      .eq('id', moduleId)
      .single();

    if (moduleError || !module) {
      return new Response(
        JSON.stringify({ error: 'Module not found.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Create Stripe PaymentIntent (off-session, confirm immediately)
    await stripe.paymentIntents.create({
      amount: module.price,
      currency: 'usd',
      customer: quote.stripe_customer_id,
      payment_method: quote.stripe_payment_method_id,
      off_session: true,
      confirm: true,
      metadata: {
        quote_id: quoteId,
        module_id: moduleId,
        is_module_addon: 'true',
      },
    });

    // Append module to quote
    await supabase
      .from('quotes')
      .update({
        module_ids: [...existingModuleIds, moduleId],
      })
      .eq('id', quoteId);

    logEvent(quoteId, 'module_added', { module_id: moduleId, module_name: module.name, amount_cents: module.price });

    // Add module admin URL to portal_deliverables if site_url is set
    const moduleAdminPaths: Record<string, string> = {
      booking:       '/admin/bookings',
      shop:          '/admin/shop',
      events:        '/admin/events',
      blog:          '/admin/blog',
      gallery:       '/admin/gallery',
      testimonials:  '/admin/testimonials',
      newsletter:    '/admin/newsletter',
      faq:           '/admin/faq',
    };
    const adminPath = moduleAdminPaths[moduleId];
    if (adminPath && quote.site_url) {
      await supabase.from('portal_deliverables').insert({
        quote_id: quoteId,
        title:    `${module.name} Admin Panel`,
        url:      `${quote.site_url}${adminPath}`,
        status:   'approved',
      });
    }

    // Send emails (non-blocking — do not await so a failed email doesn't block the response)
    const clientHtml = themedEmail(`
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Module Activated</p>
      <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">Your site just leveled up, ${quote.client_name}.</h1>
      <p style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0 0 28px;">
        A new module has been added to your site and is now live. We've taken care of the charge and the setup — no action needed on your end.
      </p>
      <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:24px;margin-bottom:24px;">
        <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 16px;text-transform:uppercase;">Module Added</p>
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:10px;">Module</td>
            <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:10px;">${module.name}</td>
          </tr>
          <tr>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">One-time charge</td>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#FFB938;font-size:13px;font-weight:600;text-align:right;">${fmt(module.price)}</td>
          </tr>
          <tr>
            <td style="padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Status</td>
            <td style="padding-top:10px;color:#58E3EF;font-size:13px;font-weight:500;text-align:right;">Active ✓</td>
          </tr>
        </table>
      </div>
      <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0;">
        If you have any questions about this addition, don't hesitate to reach out. We're always here.
      </p>
    `);

    const adminHtml = themedEmail(`
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Admin Notification</p>
      <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">Module add-on charged.</h1>
      <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:24px;">
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:10px;">Client</td>
            <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:10px;">${quote.client_name} (${quote.client_email})</td>
          </tr>
          <tr>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Module</td>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;">${module.name}</td>
          </tr>
          <tr>
            <td style="padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Charged</td>
            <td style="padding-top:10px;color:#FFB938;font-size:13px;font-weight:600;text-align:right;">${fmt(module.price)}</td>
          </tr>
          <tr>
            <td style="padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Quote ID</td>
            <td style="padding-top:10px;color:rgba(232,254,255,0.4);font-size:12px;font-family:monospace;text-align:right;">${quoteId}</td>
          </tr>
        </table>
      </div>
    `);

    Promise.all([
      sendEmail(quote.client_email, `${module.name} is now live on your site`, clientHtml),
      sendEmail(NOTIFICATION_EMAIL, `[Admin] Module add-on: ${module.name} — ${quote.client_name}`, adminHtml),
    ]).catch(console.error);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-add-module error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
