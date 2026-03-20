// Edge Function: stripe-webhook
// Handles incoming Stripe webhook events:
//   - payment_intent.succeeded        → deposit paid, update quote, email owner + client
//   - invoice.payment_succeeded       → subscription renewal, email owner + client
//   - invoice.payment_failed          → failed renewal, alert owner + client
//   - customer.subscription.updated   → plan changed via portal, log event + notify owner
//   - customer.subscription.deleted   → subscription cancelled, update quote, notify owner

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
const CUSTOMER_PORTAL_URL = Deno.env.get('STRIPE_CUSTOMER_PORTAL_URL') ?? '';
const LOGO_URL = Deno.env.get('LOGO_URL') ?? 'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';

// Reverse map: Stripe Price ID → human-readable plan label
function buildPriceLabels(): Record<string, string> {
  const map: Record<string, string> = {};
  const entries: [string, string][] = [
    ['STRIPE_PRICE_STANDARD_MONTHLY', 'Standard — Monthly'],
    ['STRIPE_PRICE_STANDARD_ANNUAL',  'Standard — Annual'],
    ['STRIPE_PRICE_PREMIUM_MONTHLY',  'Premium — Monthly'],
    ['STRIPE_PRICE_PREMIUM_ANNUAL',   'Premium — Annual'],
  ];
  for (const [envVar, label] of entries) {
    const id = Deno.env.get(envVar);
    if (id) map[id] = label;
  }
  return map;
}
const PRICE_LABELS = buildPriceLabels();

// ─── Event logger ─────────────────────────────────────────────────────────────

function logEvent(quoteId: string, eventType: string, metadata: Record<string, unknown> = {}): void {
  supabase.from('quote_events').insert({ quote_id: quoteId, event_type: eventType, metadata }).then(() => {}).catch(console.error);
}

// ─── Email helpers ─────────────────────────────────────────────────────────────

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
  if (!res.ok) {
    const body = await res.text();
    console.error('Resend error:', res.status, body);
  }
}

// ─── Format cents to dollars ──────────────────────────────────────────────────

function fmt(cents: number): string {
  return `$${(cents / 100).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
}

// ─── Idempotency check ────────────────────────────────────────────────────────

async function alreadyProcessed(evtId: string): Promise<boolean> {
  const { data } = await supabase
    .from('processed_webhook_events')
    .select('evt_id')
    .eq('evt_id', evtId)
    .maybeSingle();
  return !!data;
}

async function markProcessed(evtId: string): Promise<void> {
  await supabase.from('processed_webhook_events').insert({ evt_id: evtId });
}

// ─── Event handlers ───────────────────────────────────────────────────────────

async function handleModuleAddonPaymentIntent(paymentIntent: Stripe.PaymentIntent): Promise<void> {
  const { quote_id, module_id } = paymentIntent.metadata as { quote_id: string; module_id: string };
  if (!quote_id || !module_id) return;

  const { error: insertError } = await supabase
    .from('client_modules_pending')
    .insert({ quote_id, module_id });

  if (insertError) {
    console.error('Failed to insert client_modules_pending:', insertError);
    return;
  }

  const [{ data: quote }, { data: module }] = await Promise.all([
    supabase.from('quotes').select('*').eq('id', quote_id).maybeSingle(),
    supabase.from('modules').select('*').eq('id', module_id).maybeSingle(),
  ]);

  if (!quote || !module) return;

  logEvent(quote_id, 'addon_purchased', {
    module_id,
    module_name: module.name,
    amount_cents: module.price,
  });

  await sendEmail(
    NOTIFICATION_EMAIL,
    `⚡ Add-on purchased — ${quote.client_name}`,
    `
      <h2>Client purchased an add-on module</h2>
      <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
      <p><strong>Business:</strong> ${quote.business_name}</p>
      <p><strong>Module:</strong> ${module.name} — ${fmt(module.price)}</p>
      <p><strong>Quote ID:</strong> ${quote.id}</p>
      <p>Queued in "Feature Pending" in the admin panel.</p>
    `,
  );

  await sendEmail(
    quote.client_email,
    `Add-on confirmed — ${module.name}`,
    themedEmail(`
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Module Queued</p>
      <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;">Your add-on is in the queue, ${quote.client_name}.</h1>
      <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:28px;margin-bottom:24px;">
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:10px;">Module</td>
            <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:10px;">${module.name}</td>
          </tr>
          <tr>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Amount paid</td>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#FFB938;font-size:13px;font-weight:600;text-align:right;">${fmt(module.price)}</td>
          </tr>
        </table>
      </div>
      <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0;">
        Payment received. <strong style="color:#E8FEFF;">${module.name}</strong> has been queued for implementation.
        Track the status in your <a href="${Deno.env.get('APP_URL') ?? 'https://raspucat.com'}/portal" style="color:#58E3EF;">client portal</a>.
      </p>
    `),
  );
}

async function handleDepositPaid(paymentIntent: Stripe.PaymentIntent): Promise<void> {
  // Skip balance charges and module add-ons — handled separately
  if (paymentIntent.metadata?.is_balance === 'true') return;
  if (paymentIntent.metadata?.type === 'module_addon') return;

  const quoteId = paymentIntent.metadata?.quote_id;
  if (!quoteId) {
    console.warn('payment_intent.succeeded missing quote_id metadata — skipping');
    return;
  }

  const paymentMethodId =
    typeof paymentIntent.payment_method === 'string'
      ? paymentIntent.payment_method
      : paymentIntent.payment_method?.id ?? null;

  const { data: quote, error } = await supabase
    .from('quotes')
    .update({
      status: 'deposit_paid',
      stripe_payment_intent_id: paymentIntent.id,
      stripe_payment_method_id: paymentMethodId,
    })
    .eq('id', quoteId)
    .select('*')
    .single();

  if (error || !quote) {
    console.error('Failed to update quote on deposit:', error);
    return;
  }

  logEvent(quoteId, 'deposit_paid', { amount_cents: paymentIntent.amount });

  // Fetch supporting data for email
  const [{ data: modules }, { data: plan }, { data: mgmt }] = await Promise.all([
    supabase.from('modules').select('id, name, price').in('id', quote.module_ids ?? []),
    supabase.from('plans').select('id, name, locked_module_ids').eq('id', quote.plan_id).maybeSingle(),
    quote.management_option_id
      ? supabase.from('management_options').select('*').eq('id', quote.management_option_id).maybeSingle()
      : Promise.resolve({ data: null }),
  ]);

  // Compute management fee and real due-on-launch
  let mgmtFeeCents = 0;
  if (mgmt) {
    if (quote.billing_cycle === 'onetime') mgmtFeeCents = mgmt.onetime_price;
    else if (quote.billing_cycle === 'annual') mgmtFeeCents = mgmt.annual_price;
    else if (quote.billing_cycle === 'monthly') mgmtFeeCents = mgmt.monthly_price;
  }
  const dueOnLaunchCents = quote.balance_cents + mgmtFeeCents;

  const dueOnLaunchLabel = mgmt
    ? `${fmt(dueOnLaunchCents)} (${fmt(quote.balance_cents)} balance + ${fmt(mgmtFeeCents)} ${
        quote.billing_cycle === 'onetime' ? 'handover fee' :
        quote.billing_cycle === 'annual' ? '1st year' : '1st month'
      })`
    : fmt(dueOnLaunchCents);

  // Email owner (plain, informational)
  await sendEmail(
    NOTIFICATION_EMAIL,
    `Deposit received — ${quote.client_name}`,
    `
      <h2>New deposit received</h2>
      <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
      <p><strong>Business:</strong> ${quote.business_name}</p>
      <p><strong>Plan:</strong> ${quote.plan_id}</p>
      <p><strong>Modules:</strong> ${(quote.module_ids ?? []).join(', ') || 'None'}</p>
      <p><strong>Management:</strong> ${quote.management_option_id ?? 'None'} (${quote.billing_cycle ?? '—'})</p>
      <p><strong>Setup total:</strong> ${fmt(quote.setup_total_cents)}</p>
      <p><strong>Deposit paid:</strong> ${fmt(quote.deposit_cents)}</p>
      <p><strong>Due on launch:</strong> ${dueOnLaunchLabel}</p>
      <p><strong>Quote ID:</strong> ${quote.id}</p>
    `,
  );

  // Build module rows for client email
  const lockedIds: string[] = plan?.locked_module_ids ?? [];
  const allModules = modules ?? [];
  const lockedModules = allModules.filter((m) => lockedIds.includes(m.id));
  const addonModules = allModules.filter((m) => !lockedIds.includes(m.id));

  const moduleRow = (name: string, price: number | null, isAddon = false) => `
    <tr>
      <td style="padding:5px 0;color:rgba(232,254,255,${isAddon ? '0.6' : '0.5'});font-size:13px;">
        <span style="color:#58E3EF;margin-right:8px;">▸</span>${name}
      </td>
      <td style="padding:5px 0;text-align:right;font-size:12px;color:rgba(232,254,255,0.4);">
        ${price !== null ? fmt(price) : ''}
      </td>
    </tr>`;

  const lockedRows = lockedModules.map((m) => moduleRow(m.name, null, false)).join('');
  const addonRows = addonModules.map((m) => moduleRow(m.name, m.price, true)).join('');

  const modulesSection = `
    ${lockedRows.length ? `
      <p style="font-size:10px;color:rgba(88,227,239,0.5);letter-spacing:2px;text-transform:uppercase;margin:0 0 6px;">Included in Plan</p>
      <table style="width:100%;border-collapse:collapse;margin-bottom:14px;">${lockedRows}</table>
    ` : ''}
    ${addonRows.length ? `
      <p style="font-size:10px;color:rgba(88,227,239,0.5);letter-spacing:2px;text-transform:uppercase;margin:0 0 6px;">Add-ons</p>
      <table style="width:100%;border-collapse:collapse;margin-bottom:14px;">${addonRows}</table>
    ` : ''}`;

  // Management / subscription block
  const isRecurring = mgmt && quote.billing_cycle !== 'onetime';
  const mgmtBlock = mgmt ? `
    <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.15);border-left:3px solid #58E3EF;border-radius:10px;padding:22px;margin-bottom:16px;">
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">
        ${isRecurring ? 'Management Subscription' : 'Handover & Docs'}
      </p>
      <p style="color:#E8FEFF;font-size:14px;font-weight:500;margin:0 0 6px;">${mgmt.name}</p>
      <p style="color:rgba(232,254,255,0.55);font-size:13px;line-height:1.6;margin:0 0 14px;">${mgmt.description}</p>
      ${isRecurring ? `
        <p style="color:rgba(232,254,255,0.5);font-size:13px;margin:0;">
          Your subscription of <strong style="color:#FFB938;">${
            quote.billing_cycle === 'annual' ? fmt(mgmt.annual_price) + '/yr' : fmt(mgmt.monthly_price) + '/mo'
          }</strong> begins automatically at launch — no further action needed.
          ${quote.billing_cycle === 'annual' && mgmt.annual_savings > 0
            ? `<br><span style="color:#58E3EF;font-size:12px;">Saving ${fmt(mgmt.annual_savings)}/yr on annual billing.</span>`
            : ''}
        </p>
      ` : `
        <p style="color:rgba(232,254,255,0.5);font-size:13px;margin:0;">
          The handover fee of <strong style="color:#FFB938;">${fmt(mgmt.onetime_price)}</strong> is collected at delivery.
        </p>
      `}
    </div>` : '';

  // Stripe portal link
  const portalBlock = CUSTOMER_PORTAL_URL ? `
    <div style="text-align:center;margin-bottom:24px;">
      <a href="${CUSTOMER_PORTAL_URL}" style="display:inline-block;padding:12px 28px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58E3EF;font-family:'Space Grotesk',sans-serif;font-size:13px;letter-spacing:1px;text-decoration:none;">
        Manage Payment Method
      </a>
    </div>` : '';

  const clientHtml = themedEmail(`
  <!-- Hero -->
  <div style="padding-bottom:32px;text-align:center;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Mission Initiated</p>
    <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">Deposit confirmed, ${quote.client_name}.</h1>
    <p style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0 auto;max-width:460px;">
      Thank you for trusting us with your vision. Before a single line is written, we study your mission — your brand, your audience, your goals. What we build will not just look the part. It will work like an extension of what you stand for.
    </p>
  </div>

  <!-- Order Summary -->
  <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:28px;margin-bottom:16px;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 20px;text-transform:uppercase;">Order Summary</p>

    <!-- Plan -->
    <table style="width:100%;border-collapse:collapse;margin-bottom:16px;">
      <tr>
        <td style="color:rgba(232,254,255,0.4);font-size:12px;text-transform:uppercase;letter-spacing:1px;padding-bottom:6px;">Plan</td>
        <td style="color:#E8FEFF;font-size:14px;font-weight:500;text-align:right;padding-bottom:6px;">${plan?.name ?? quote.plan_id}</td>
      </tr>
    </table>

    <div style="border-top:1px solid rgba(88,227,239,0.08);margin-bottom:18px;"></div>

    <!-- Modules -->
    ${modulesSection}

    <div style="border-top:1px solid rgba(88,227,239,0.08);margin:4px 0 18px;"></div>

    <!-- Pricing -->
    <table style="width:100%;border-collapse:collapse;">
      <tr>
        <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:8px;">Setup total</td>
        <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:8px;">${fmt(quote.setup_total_cents)}</td>
      </tr>
      <tr>
        <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Deposit paid today</td>
        <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#FFB938;font-size:13px;font-weight:600;text-align:right;">${fmt(quote.deposit_cents)}</td>
      </tr>
      <tr>
        <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-top:8px;">Due on launch</td>
        <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-top:8px;">${dueOnLaunchLabel}</td>
      </tr>
    </table>
  </div>

  <!-- Management block -->
  ${mgmtBlock}

  <!-- Portal link -->
  ${portalBlock}

  <!-- Client Portal -->
  <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-left:3px solid #58E3EF;border-radius:10px;padding:22px;margin-bottom:16px;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 10px;text-transform:uppercase;">Your Client Portal</p>
    <p style="color:rgba(232,254,255,0.6);font-size:14px;line-height:1.7;margin:0 0 16px;">
      Track your project's progress, review deliverables, exchange files, and communicate with our team — all in one place.
    </p>
    <div style="text-align:center;">
      <a href="${Deno.env.get('APP_URL') ?? 'https://raspucat.com'}/portal/login" style="display:inline-block;padding:12px 28px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58E3EF;font-family:'Space Grotesk',sans-serif;font-size:13px;letter-spacing:1px;text-decoration:none;">
        Access Your Portal →
      </a>
    </div>
    <p style="color:rgba(232,254,255,0.3);font-size:12px;text-align:center;margin:12px 0 0;">
      Sign in with <strong style="color:rgba(232,254,255,0.5);">${quote.client_email}</strong> to receive your access link.
    </p>
  </div>

  <!-- Next steps -->
  <div style="padding:28px 0;border-top:1px solid rgba(88,227,239,0.08);">
    <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0 0 14px;">
      We will be in touch shortly to schedule a discovery session and align on your mission. From there — we engineer, refine, and deploy with precision.
    </p>
    <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0;">
      The remaining balance is collected at launch, once you are completely satisfied with the result.
    </p>
  </div>
  `);

  await sendEmail(
    quote.client_email,
    `Deposit Received. Countdown to Launch.`,
    clientHtml,
  );
}

async function handleUpcomingRenewal(invoice: Stripe.Invoice): Promise<void> {
  const customerId =
    typeof invoice.customer === 'string' ? invoice.customer : invoice.customer?.id;
  if (!customerId) return;

  const { data: quote } = await supabase
    .from('quotes')
    .select('*')
    .eq('stripe_customer_id', customerId)
    .maybeSingle();

  if (!quote) return;

  const billingDate = invoice.period_end
    ? new Date(invoice.period_end * 1000).toLocaleDateString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric',
      })
    : '—';

  const portalLink = CUSTOMER_PORTAL_URL
    ? `<p><a href="${CUSTOMER_PORTAL_URL}">Update your payment method</a></p>`
    : '';

  await sendEmail(
    quote.client_email,
    `Upcoming payment reminder — Raspucat`,
    themedEmail(`
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Heads Up</p>
      <h1 style="font-family:'Space Grotesk',sans-serif;font-size:24px;font-weight:600;color:#E8FEFF;margin:0 0 24px;line-height:1.3;">Just a reminder, ${quote.client_name}.</h1>
      <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:24px;margin-bottom:24px;">
        <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0 0 16px;">
          Your <strong style="color:#E8FEFF;">${quote.management_option_id}</strong> subscription payment of
          <strong style="color:#FFB938;">${fmt(invoice.amount_due)}</strong> will be charged in
          <strong style="color:#E8FEFF;">3 days</strong> on ${billingDate}.
        </p>
        <p style="color:rgba(232,254,255,0.4);font-size:13px;margin:0;">No action needed — we just wanted to give you a heads up.</p>
      </div>
      ${portalLink ? `<div style="text-align:center;margin-bottom:24px;"><a href="${CUSTOMER_PORTAL_URL}" style="display:inline-block;padding:12px 28px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58E3EF;font-family:'Space Grotesk',sans-serif;font-size:13px;letter-spacing:1px;text-decoration:none;">Update Payment Method</a></div>` : ''}
    `),
  );
}

async function handleSubscriptionRenewal(invoice: Stripe.Invoice): Promise<void> {
  // Skip the first invoice — it overlaps with the deposit confirmation email
  if (invoice.billing_reason === 'subscription_create') return;

  const customerId =
    typeof invoice.customer === 'string' ? invoice.customer : invoice.customer?.id;
  if (!customerId) return;

  const { data: quote } = await supabase
    .from('quotes')
    .select('*')
    .eq('stripe_customer_id', customerId)
    .maybeSingle();

  if (!quote) {
    console.warn('No quote found for customer:', customerId);
    return;
  }

  const amountPaid = invoice.amount_paid;
  const periodEnd = invoice.period_end
    ? new Date(invoice.period_end * 1000).toLocaleDateString('en-US', {
        month: 'long',
        year: 'numeric',
      })
    : '—';

  // Email owner
  await sendEmail(
    NOTIFICATION_EMAIL,
    `💳 Subscription renewal — ${quote.client_name}`,
    `
      <h2>Subscription payment received</h2>
      <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
      <p><strong>Amount:</strong> ${fmt(amountPaid)}</p>
      <p><strong>Plan:</strong> ${quote.management_option_id}</p>
      <p><strong>Next billing:</strong> ${periodEnd}</p>
    `,
  );

  // Email client
  const portalLink = CUSTOMER_PORTAL_URL
    ? `<p><a href="${CUSTOMER_PORTAL_URL}">Manage your subscription</a></p>`
    : '';

  await sendEmail(
    quote.client_email,
    `Your Raspucat management subscription — ${periodEnd}`,
    themedEmail(`
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Renewal Confirmed</p>
      <h1 style="font-family:'Space Grotesk',sans-serif;font-size:24px;font-weight:600;color:#E8FEFF;margin:0 0 24px;line-height:1.3;">Payment received, ${quote.client_name}.</h1>
      <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:24px;margin-bottom:24px;">
        <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 16px;text-transform:uppercase;">Subscription Summary</p>
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:10px;">Plan</td>
            <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:10px;">${quote.management_option_id}</td>
          </tr>
          <tr>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Amount charged</td>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#FFB938;font-size:13px;font-weight:600;text-align:right;">${fmt(amountPaid)}</td>
          </tr>
          <tr>
            <td style="padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Next billing date</td>
            <td style="padding-top:10px;color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;">${periodEnd}</td>
          </tr>
        </table>
      </div>
      ${portalLink ? `<div style="text-align:center;margin-bottom:24px;"><a href="${CUSTOMER_PORTAL_URL}" style="display:inline-block;padding:12px 28px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58E3EF;font-family:'Space Grotesk',sans-serif;font-size:13px;letter-spacing:1px;text-decoration:none;">Manage Subscription</a></div>` : ''}
    `),
  );
}

async function handlePaymentFailed(invoice: Stripe.Invoice): Promise<void> {
  const customerId =
    typeof invoice.customer === 'string' ? invoice.customer : invoice.customer?.id;
  if (!customerId) return;

  const { data: quote } = await supabase
    .from('quotes')
    .select('*')
    .eq('stripe_customer_id', customerId)
    .maybeSingle();

  if (!quote) return;

  const nextRetry = invoice.next_payment_attempt
    ? new Date(invoice.next_payment_attempt * 1000).toLocaleDateString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric',
      })
    : 'soon';

  // Alert owner
  await sendEmail(
    NOTIFICATION_EMAIL,
    `⚠️ Payment failed — ${quote.client_name}`,
    `
      <h2>Subscription payment failed</h2>
      <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
      <p><strong>Amount:</strong> ${fmt(invoice.amount_due)}</p>
      <p><strong>Next retry:</strong> ${nextRetry}</p>
      <p>Stripe will retry automatically. If it continues to fail, the subscription may be cancelled.</p>
    `,
  );

  // Alert client
  const portalLink = CUSTOMER_PORTAL_URL
    ? `<p><a href="${CUSTOMER_PORTAL_URL}">Update your payment method</a></p>`
    : '';

  await sendEmail(
    quote.client_email,
    `Action needed — Raspucat payment failed`,
    themedEmail(`
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#FFB938;margin:0 0 14px;text-transform:uppercase;">Action Required</p>
      <h1 style="font-family:'Space Grotesk',sans-serif;font-size:24px;font-weight:600;color:#E8FEFF;margin:0 0 24px;line-height:1.3;">We couldn't process your payment, ${quote.client_name}.</h1>
      <div style="background:#0B0E1F;border:1px solid rgba(255,185,56,0.25);border-left:3px solid #FFB938;border-radius:12px;padding:24px;margin-bottom:24px;">
        <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0 0 12px;">
          Your <strong style="color:#E8FEFF;">${quote.management_option_id}</strong> subscription payment of
          <strong style="color:#FFB938;">${fmt(invoice.amount_due)}</strong> failed.
        </p>
        <p style="color:rgba(232,254,255,0.4);font-size:13px;margin:0;">
          Stripe will retry on <strong style="color:#E8FEFF;">${nextRetry}</strong>. To avoid any interruption to your service, please update your payment method before then.
        </p>
      </div>
      ${portalLink ? `<div style="text-align:center;margin-bottom:24px;"><a href="${CUSTOMER_PORTAL_URL}" style="display:inline-block;padding:12px 28px;background:rgba(255,185,56,0.1);border:1px solid rgba(255,185,56,0.5);border-radius:8px;color:#FFB938;font-family:'Space Grotesk',sans-serif;font-size:13px;letter-spacing:1px;text-decoration:none;">Update Payment Method</a></div>` : ''}
    `),
  );
}

async function handleModuleAddonPurchase(session: Stripe.Checkout.Session): Promise<void> {
  if (session.metadata?.type !== 'module_addon') return;

  const { quote_id, module_id } = session.metadata as { quote_id: string; module_id: string };
  if (!quote_id || !module_id) return;

  const { error: insertError } = await supabase
    .from('client_modules_pending')
    .insert({ quote_id, module_id });

  if (insertError) {
    console.error('Failed to insert client_modules_pending:', insertError);
    return;
  }

  const [{ data: quote }, { data: module }] = await Promise.all([
    supabase.from('quotes').select('*').eq('id', quote_id).maybeSingle(),
    supabase.from('modules').select('*').eq('id', module_id).maybeSingle(),
  ]);

  if (!quote || !module) return;

  await sendEmail(
    NOTIFICATION_EMAIL,
    `⚡ Add-on purchased — ${quote.client_name}`,
    `
      <h2>Client purchased an add-on module</h2>
      <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
      <p><strong>Business:</strong> ${quote.business_name}</p>
      <p><strong>Module:</strong> ${module.name} — ${fmt(module.price)}</p>
      <p><strong>Quote ID:</strong> ${quote.id}</p>
      <p>Queued in "Feature Pending" in the admin panel.</p>
    `,
  );

  await sendEmail(
    quote.client_email,
    `Add-on confirmed — ${module.name}`,
    themedEmail(`
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Module Queued</p>
      <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;">Your add-on is in the queue, ${quote.client_name}.</h1>
      <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:28px;margin-bottom:24px;">
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:10px;">Module</td>
            <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:10px;">${module.name}</td>
          </tr>
          <tr>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Amount paid</td>
            <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#FFB938;font-size:13px;font-weight:600;text-align:right;">${fmt(module.price)}</td>
          </tr>
        </table>
      </div>
      <p style="color:rgba(232,254,255,0.55);font-size:14px;line-height:1.8;margin:0;">
        Payment received. <strong style="color:#E8FEFF;">${module.name}</strong> has been queued for implementation.
        Track the status in your <a href="${Deno.env.get('APP_URL') ?? 'https://raspucat.com'}/portal" style="color:#58E3EF;">client portal</a>.
      </p>
    `),
  );
}

async function handleSubscriptionUpdated(
  subscription: Stripe.Subscription,
  previousAttributes: Record<string, unknown>,
): Promise<void> {
  // Only act on plan-relevant changes:
  //   scheduleChanged  → portal scheduled end-of-period change (schedule attached)
  //   itemsChanged     → immediate plan change (items replaced)
  const scheduleChanged = 'schedule' in previousAttributes;
  const itemsChanged = 'items' in previousAttributes;
  if (!scheduleChanged && !itemsChanged) return;

  // Prefer metadata.quote_id (set at subscription creation) — fall back to customer_id lookup.
  const quoteId = subscription.metadata?.quote_id;
  const customerId = typeof subscription.customer === 'string'
    ? subscription.customer : subscription.customer?.id;

  const query = supabase
    .from('quotes')
    .select('id, client_name, client_email, management_option_id');

  const { data: quote } = await (quoteId
    ? query.eq('id', quoteId)
    : query.eq('stripe_customer_id', customerId ?? '')
  ).single();

  if (!quote) {
    console.warn('handleSubscriptionUpdated: no quote found for', { quoteId, customerId });
    return;
  }

  let changeDescription = '';
  let effectiveLabel = '';

  if (scheduleChanged && subscription.schedule) {
    // End-of-period change: read the future schedule phase for the new price.
    try {
      const scheduleId = typeof subscription.schedule === 'string'
        ? subscription.schedule : (subscription.schedule as { id: string })?.id;
      console.log('handleSubscriptionUpdated: retrieving schedule', scheduleId);
      const schedule = await stripe.subscriptionSchedules.retrieve(scheduleId!);
      const now = Math.floor(Date.now() / 1000);
      const futurePhase = schedule.phases.find((p) => p.start_date > now);
      console.log('handleSubscriptionUpdated: phases', JSON.stringify(schedule.phases.map(p => ({ start: p.start_date, now }))));
      if (futurePhase) {
        const newPriceId = futurePhase.items?.[0]?.price as string | undefined;
        const newLabel = newPriceId ? (PRICE_LABELS[newPriceId] ?? newPriceId) : 'a different plan';
        const effectiveDate = new Date(futurePhase.start_date * 1000).toLocaleDateString(
          'en-US', { month: 'long', day: 'numeric', year: 'numeric' },
        );
        changeDescription = `Scheduled change to ${newLabel}`;
        effectiveLabel = `effective ${effectiveDate} (end of billing period)`;
      } else {
        console.log('handleSubscriptionUpdated: no future phase found — skipping');
      }
    } catch (err) {
      console.error('handleSubscriptionUpdated: schedule retrieval failed', err);
    }
  } else if (itemsChanged) {
    // Immediate change: new price is already on the subscription.
    // The webhook payload includes the full price object — use nickname directly.
    const price = subscription.items.data[0]?.price as { id?: string; nickname?: string | null } | undefined;
    const newLabel = price?.nickname ?? (price?.id ? (PRICE_LABELS[price.id] ?? price.id) : 'a new plan');
    changeDescription = `Changed to ${newLabel}`;
    effectiveLabel = 'effective immediately';
  }

  if (!changeDescription) return;

  logEvent(quote.id, 'subscription_plan_changed', { changeDescription, effectiveLabel });

  await Promise.all([
    // Owner notification — plain, actionable
    sendEmail(
      NOTIFICATION_EMAIL,
      `⚠️ Subscription change — ${quote.client_name}`,
      `
        <h2>Subscription plan changed</h2>
        <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
        <p><strong>Change:</strong> ${changeDescription}</p>
        <p><strong>Timing:</strong> ${effectiveLabel}</p>
        <p><em>Open the admin panel to review the quote detail.</em></p>
      `,
    ),
    // Client confirmation — branded
    sendEmail(
      quote.client_email,
      `Your subscription has been updated`,
      themedEmail(`
        <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Subscription Update</p>
        <h1 style="font-family:'Space Grotesk',sans-serif;font-size:24px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">We've noted your plan change, ${quote.client_name}.</h1>
        <p style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0 0 28px;">
          Your subscription has been updated. Here's a summary of what's changing:
        </p>
        <div style="background:#0B0E1F;border:1px solid rgba(88,227,239,0.18);border-radius:12px;padding:24px;margin-bottom:28px;">
          <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 16px;text-transform:uppercase;">Change Summary</p>
          <table style="width:100%;border-collapse:collapse;">
            <tr>
              <td style="color:rgba(232,254,255,0.45);font-size:13px;padding-bottom:10px;">Update</td>
              <td style="color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;padding-bottom:10px;">${changeDescription}</td>
            </tr>
            <tr>
              <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:rgba(232,254,255,0.45);font-size:13px;">Timing</td>
              <td style="border-top:1px solid rgba(88,227,239,0.08);padding-top:10px;color:#E8FEFF;font-size:13px;font-weight:500;text-align:right;">${effectiveLabel}</td>
            </tr>
          </table>
        </div>
        <p style="color:rgba(232,254,255,0.5);font-size:13px;line-height:1.8;margin:0;">
          If you did not make this change or have questions, please reply to this email.
        </p>
      `),
    ),
  ]);
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription): Promise<void> {
  const customerId =
    typeof subscription.customer === 'string'
      ? subscription.customer
      : subscription.customer?.id;
  if (!customerId) return;

  const { data: quote, error } = await supabase
    .from('quotes')
    .update({
      stripe_subscription_id: null,
      subscription_started_at: null,
    })
    .eq('stripe_customer_id', customerId)
    .select('*')
    .single();

  if (error || !quote) {
    console.warn('No quote found for cancelled subscription, customer:', customerId);
    return;
  }

  const effectiveDate = new Date(subscription.canceled_at! * 1000).toLocaleDateString(
    'en-US',
    { month: 'long', day: 'numeric', year: 'numeric' },
  );

  await sendEmail(
    NOTIFICATION_EMAIL,
    `🔴 Subscription cancelled — ${quote.client_name}`,
    `
      <h2>Subscription cancelled</h2>
      <p><strong>Client:</strong> ${quote.client_name} (${quote.client_email})</p>
      <p><strong>Plan:</strong> ${quote.management_option_id}</p>
      <p><strong>Effective:</strong> ${effectiveDate}</p>
    `,
  );
}

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  const signature = req.headers.get('stripe-signature');
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');

  if (!signature || !webhookSecret) {
    return new Response('Missing signature or webhook secret.', { status: 400 });
  }

  let event: Stripe.Event;

  try {
    const body = await req.text();
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return new Response('Invalid signature.', { status: 400 });
  }

  // Idempotency — skip if already processed
  if (await alreadyProcessed(event.id)) {
    console.log('Duplicate event, skipping:', event.id);
    return new Response('ok', { status: 200 });
  }

  try {
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const pi = event.data.object as Stripe.PaymentIntent;
        if (pi.metadata?.type === 'module_addon') {
          await handleModuleAddonPaymentIntent(pi);
        } else {
          await handleDepositPaid(pi);
        }
        break;
      }
      case 'invoice.upcoming':
        await handleUpcomingRenewal(event.data.object as Stripe.Invoice);
        break;
      case 'invoice.payment_succeeded':
        await handleSubscriptionRenewal(event.data.object as Stripe.Invoice);
        break;
      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object as Stripe.Invoice);
        break;
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(
          event.data.object as Stripe.Subscription,
          (event.data.previous_attributes ?? {}) as Record<string, unknown>,
        );
        break;
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;
      default:
        console.log('Unhandled event type:', event.type);
    }

    await markProcessed(event.id);
    return new Response('ok', { status: 200 });
  } catch (err) {
    console.error('Error processing event:', event.type, err);
    // Return 200 to prevent Stripe retrying an event that will keep failing
    // Log the error for investigation instead
    return new Response('ok', { status: 200 });
  }
});
