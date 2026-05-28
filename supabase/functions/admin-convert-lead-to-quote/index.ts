// Edge Function: admin-convert-lead-to-quote
// Converts an outreach lead to a client quote.
// 1. Creates Stripe customer + Checkout Session for deposit
// 2. Creates quote with all lead intelligence pre-populated
// 3. Creates Supabase Auth user + generates magic link
// 4. Sends conversion email with deposit link + portal access
// 5. Updates lead status to closed_won

import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2026-01-28.clover',
});

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const SITE_URL = Deno.env.get('SITE_URL') ?? 'https://ras3ucat.com';
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const FROM_EMAIL = 'hello@raspucat.com';
const FROM_NAME = 'Ryan at Raspucat';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) return;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: `${FROM_NAME} <${FROM_EMAIL}>`, to, subject, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
}

function buildConversionEmail(params: {
  clientName: string;
  planName: string;
  depositCents: number;
  depositUrl: string;
  magicLink: string;
  portalUrl: string;
}): string {
  const depositDollars = (params.depositCents / 100).toFixed(2);
  return `<!DOCTYPE html><html><body style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:24px;color:#1a1a2e;">
<h2 style="margin-bottom:4px;">Welcome to Raspucat 🎉</h2>
<p style="color:#555;">Hi ${params.clientName},</p>
<p>We're excited to get started on your ${params.planName} project. Here's everything you need to kick things off:</p>
<hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
<h3 style="margin-bottom:8px;">Step 1 — Pay your deposit ($${depositDollars})</h3>
<p>Your deposit secures your spot and kicks off the build.</p>
<p><a href="${params.depositUrl}" style="display:inline-block;background:#58E3EF;color:#1a1a2e;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:bold;">Pay Deposit →</a></p>
<hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
<h3 style="margin-bottom:8px;">Step 2 — Access your client portal</h3>
<p>Your portal is ready. Log in to complete your discovery form and track your project.</p>
<p><a href="${params.magicLink}" style="display:inline-block;background:#1a1a2e;color:#fff;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:bold;">Open My Portal →</a></p>
<p style="font-size:12px;color:#999;">This login link expires in 24 hours. Visit <a href="${params.portalUrl}">${params.portalUrl}</a> to request a new one.</p>
<hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
<p style="color:#555;">Questions? Reply to this email — I'm here.</p>
<p>— Ryan<br><span style="color:#999;font-size:12px;">Raspucat</span></p>
</body></html>`;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const {
      adminToken,
      leadId,
      planId,
      moduleIds,
      managementOptionId,
      billingCycle,
      setupTotalCents,
    } = await req.json();

    if (adminToken !== Deno.env.get('ADMIN_PASSWORD')) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    if (!leadId || !planId || !setupTotalCents) {
      return json({ error: 'leadId, planId, and setupTotalCents are required.' }, 400);
    }

    // --- Fetch lead ---
    const { data: lead, error: leadErr } = await supabase
      .from('leads')
      .select('*')
      .eq('id', leadId)
      .single();

    if (leadErr || !lead) return json({ error: 'Lead not found.' }, 404);

    const clientEmail = lead.email;
    if (!clientEmail) return json({ error: 'Lead has no email address.' }, 400);

    const clientName = lead.decision_maker_name ?? lead.company_name;
    const depositCents = Math.floor(setupTotalCents / 2);
    const balanceCents = setupTotalCents - depositCents;

    // --- Fetch plan name for email ---
    const { data: plan } = await supabase
      .from('plans')
      .select('name')
      .eq('id', planId)
      .single();
    const planName = plan?.name ?? 'Custom';

    // --- Create or find Stripe customer ---
    const existingCustomers = await stripe.customers.list({ email: clientEmail, limit: 1 });
    const customer = existingCustomers.data.length > 0
      ? existingCustomers.data[0]
      : await stripe.customers.create({
          name: clientName,
          email: clientEmail,
          metadata: { businessName: lead.company_name ?? '' },
        });

    // --- Create quote first so we have the ID for Stripe metadata ---
    const { data: quote, error: quoteErr } = await supabase
      .from('quotes')
      .insert({
        client_name: clientName,
        client_email: clientEmail,
        business_name: lead.company_name ?? null,
        plan_id: planId,
        module_ids: moduleIds ?? [],
        management_option_id: managementOptionId ?? null,
        billing_cycle: billingCycle ?? null,
        setup_total_cents: setupTotalCents,
        deposit_cents: depositCents,
        balance_cents: balanceCents,
        stripe_customer_id: customer.id,
        status: 'pending',
        portal_stage: 'awaiting_deposit',
        // Intelligence fields from lead
        outreach_lead_id: leadId,
        business_website: lead.website ?? null,
        industry: lead.industry ?? null,
        pain_points: lead.pain_points ?? [],
        website_audit: lead.website_audit ?? null,
        decision_maker_name: lead.decision_maker_name ?? null,
        decision_maker_title: lead.decision_maker_title ?? null,
      })
      .select('id')
      .single();

    if (quoteErr || !quote) {
      console.error('Quote insert error:', quoteErr);
      return json({ error: 'Failed to create quote.' }, 500);
    }

    // --- Create Stripe Checkout Session with quote_id in PaymentIntent metadata ---
    // quote_id in payment_intent_data.metadata ensures stripe-webhook can advance portal_stage
    const checkoutSession = await stripe.checkout.sessions.create({
      customer: customer.id,
      payment_method_types: ['card'],
      mode: 'payment',
      line_items: [{
        price_data: {
          currency: 'usd',
          unit_amount: depositCents,
          product_data: { name: `${planName} — Deposit` },
        },
        quantity: 1,
      }],
      success_url: `${SITE_URL}/portal?deposit=success`,
      cancel_url: `${SITE_URL}/portal`,
      payment_intent_data: {
        setup_future_usage: 'off_session',
        metadata: { quote_id: quote.id, plan_id: planId, is_deposit: 'true' },
      },
    });

    supabase.from('quotes').update({ stripe_checkout_url: checkoutSession.url })
      .eq('id', quote.id).then(() => {}).catch(console.error);

    // --- Create Supabase Auth user + magic link ---
    const { data: authData, error: authErr } = await supabase.auth.admin.createUser({
      email: clientEmail,
      email_confirm: true,
      user_metadata: { name: clientName, quote_id: quote.id },
    });

    let magicLink = `${SITE_URL}/portal/login`;
    if (!authErr && authData?.user) {
      const { data: linkData } = await supabase.auth.admin.generateLink({
        type: 'magiclink',
        email: clientEmail,
        options: { redirectTo: `${SITE_URL}/portal` },
      });
      if (linkData?.properties?.action_link) {
        magicLink = linkData.properties.action_link;
      }
    }

    // --- Update lead status ---
    await supabase
      .from('leads')
      .update({ status: 'closed_won' })
      .eq('id', leadId);

    // --- Send conversion email ---
    const portalUrl = `${SITE_URL}/portal`;
    await sendEmail(
      clientEmail,
      `Your ${planName} project is ready to start`,
      buildConversionEmail({
        clientName,
        planName,
        depositCents,
        depositUrl: checkoutSession.url!,
        magicLink,
        portalUrl,
      }),
    );

    return json({
      quoteId: quote.id,
      portalUrl,
      depositUrl: checkoutSession.url,
    });
  } catch (err) {
    console.error('admin-convert-lead-to-quote error:', err);
    return json({ error: (err as Error).message ?? 'Internal server error.' }, 500);
  }
});
