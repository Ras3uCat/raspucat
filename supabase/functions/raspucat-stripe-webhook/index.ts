// Edge Function: raspucat-stripe-webhook
// Handles Stripe billing events for the Raspucat billing Stripe account.
// Register at: Stripe Dashboard → Webhooks → Add endpoint → <supabase-url>/functions/v1/raspucat-stripe-webhook
//
// Events handled:
//   customer.subscription.updated  — detect cancel_at_period_end=true, trigger handoff
//   invoice.paid                   — detect handoff invoices, fire client package
//   customer.subscription.deleted  — mark quote cancelled, fallback handoff

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

async function callSendHandoff(quoteId: string, action: 'admin_alert' | 'client_package'): Promise<void> {
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  try {
    const resp = await fetch(`${supabaseUrl}/functions/v1/admin-send-handoff`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${serviceKey}`,
      },
      body: JSON.stringify({ quoteId, action }),
    });
    if (!resp.ok) console.error('admin-send-handoff returned', resp.status, await resp.text());
  } catch (err) {
    console.error('admin-send-handoff call failed:', err);
  }
}

async function findQuoteBySubscriptionId(subscriptionId: string) {
  const { data } = await supabase
    .from('quotes')
    .select('*')
    .eq('stripe_subscription_id', subscriptionId)
    .maybeSingle();
  return data;
}

async function findQuoteByCustomerId(customerId: string) {
  const { data } = await supabase
    .from('quotes')
    .select('*')
    .eq('stripe_customer_id', customerId)
    .maybeSingle();
  return data;
}

async function handleSubscriptionUpdated(subscription: Stripe.Subscription): Promise<void> {
  if (!subscription.cancel_at_period_end) return; // Not a cancellation

  const quote = await findQuoteBySubscriptionId(subscription.id);
  if (!quote) {
    console.error('No quote found for subscription', subscription.id);
    return;
  }

  const periodEnd = new Date(subscription.current_period_end * 1000).toISOString();

  // Write subscription_cancel_at if not already set
  if (!quote.subscription_cancel_at) {
    await supabase
      .from('quotes')
      .update({ subscription_cancel_at: periodEnd })
      .eq('id', quote.id);
  }

  // Send admin alert immediately
  await callSendHandoff(quote.id, 'admin_alert');

  if ((quote.handoff_fee_cents ?? 0) > 0) {
    // Create handoff invoice — client package fires after invoice.paid
    await createHandoffInvoice(quote, periodEnd);
  } else {
    // No fee — send client package immediately
    await callSendHandoff(quote.id, 'client_package');
  }
}

async function createHandoffInvoice(quote: Record<string, unknown>, _periodEnd: string): Promise<void> {
  if (!quote.stripe_customer_id) {
    console.error('No stripe_customer_id on quote', quote.id);
    return;
  }

  try {
    // Create invoice
    const invoice = await stripe.invoices.create({
      customer: quote.stripe_customer_id as string,
      metadata: { type: 'handoff', quote_id: quote.id as string },
      auto_advance: false,
      collection_method: 'send_invoice',
      days_until_due: 7,
    });

    // Add line item
    await stripe.invoiceItems.create({
      customer: quote.stripe_customer_id as string,
      amount: quote.handoff_fee_cents as number,
      currency: 'usd',
      description: `Handoff fee — ${quote.business_name ?? 'site delivery'}`,
      invoice: invoice.id,
    });

    // Finalize and send
    await stripe.invoices.finalizeInvoice(invoice.id);
    await stripe.invoices.sendInvoice(invoice.id);

    // Write handoff_invoice_id for idempotency
    await supabase
      .from('quotes')
      .update({ handoff_invoice_id: invoice.id })
      .eq('id', quote.id);
  } catch (err) {
    console.error('Failed to create handoff invoice:', err);
  }
}

async function handleInvoicePaid(invoice: Stripe.Invoice): Promise<void> {
  if (invoice.metadata?.type !== 'handoff') return;

  const quoteId = invoice.metadata?.quote_id;
  if (!quoteId) {
    console.error('handoff invoice missing quote_id metadata:', invoice.id);
    return;
  }

  await callSendHandoff(quoteId, 'client_package');
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription): Promise<void> {
  // Try to find quote by subscription_id first, then by customer_id
  let quote = await findQuoteBySubscriptionId(subscription.id);
  if (!quote && subscription.customer) {
    quote = await findQuoteByCustomerId(subscription.customer as string);
  }
  if (!quote) {
    console.error('No quote found for deleted subscription', subscription.id);
    return;
  }

  const now = new Date().toISOString();

  // Set status to cancelled and write cancelled_at
  await supabase
    .from('quotes')
    .update({
      status: 'cancelled',
      cancelled_at: now,
      stripe_subscription_id: null,
      subscription_started_at: null,
    })
    .eq('id', quote.id);

  // Log event
  await supabase.from('quote_events').insert({
    quote_id: quote.id,
    event_type: 'subscription_cancelled',
    metadata: { subscription_id: subscription.id },
  });

  // Fallback: send client package if not already sent
  if (!quote.handoff_package_ready) {
    await callSendHandoff(quote.id, 'client_package');
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const webhookSecret = Deno.env.get('STRIPE_BILLING_WEBHOOK_SECRET');
  if (!webhookSecret) {
    console.error('STRIPE_BILLING_WEBHOOK_SECRET not configured.');
    return new Response('Webhook secret not configured.', { status: 500 });
  }

  const signature = req.headers.get('stripe-signature');
  if (!signature) {
    return new Response('Missing stripe-signature.', { status: 400 });
  }

  let event: Stripe.Event;
  try {
    const body = await req.text();
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);
  } catch (err) {
    console.error('Stripe signature verification failed:', err);
    return new Response('Invalid signature.', { status: 400 });
  }

  try {
    switch (event.type) {
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
        break;
      case 'invoice.paid':
        await handleInvoicePaid(event.data.object as Stripe.Invoice);
        break;
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;
      default:
        // Ignore unhandled events — return 200 so Stripe doesn't retry
        break;
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200, headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('raspucat-stripe-webhook handler error:', err);
    return new Response(JSON.stringify({ error: 'Handler error.' }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    });
  }
});
