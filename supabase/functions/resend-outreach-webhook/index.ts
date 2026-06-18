// Edge Function: resend-outreach-webhook
// Handles outbound tracking events from Resend: open, click, bounce, unsubscribe.
// Verifies Resend/svix HMAC signature and deduplicates by svix-id.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { Webhook } from 'https://esm.sh/svix@1?target=deno&no-check';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const webhookSecret = Deno.env.get('RESEND_WEBHOOK_SECRET');
  if (!webhookSecret) return json({ error: 'Missing webhook secret.' }, 500);

  const svixId        = req.headers.get('svix-id') ?? '';
  const svixTimestamp = req.headers.get('svix-timestamp') ?? '';
  const svixSignature = req.headers.get('svix-signature') ?? '';
  const rawBody = await req.text();

  try {
    const wh = new Webhook(webhookSecret);
    wh.verify(rawBody, { 'svix-id': svixId, 'svix-timestamp': svixTimestamp, 'svix-signature': svixSignature });
  } catch {
    return json({ error: 'Invalid signature.' }, 401);
  }

  // Idempotency: skip events already processed
  const { data: existing } = await supabase
    .from('outreach_webhook_events')
    .select('id')
    .eq('svix_id', svixId)
    .maybeSingle();
  if (existing) return json({ received: true });

  try {
    const { type, data } = JSON.parse(rawBody) as {
      type: string;
      data: { email_id?: string };
    };

    const emailId = data?.email_id;
    const now = new Date().toISOString();

    if (type === 'email.opened' && emailId) {
      await supabase
        .from('outreach_emails')
        .update({ opened_at: now })
        .eq('resend_id', emailId)
        .is('opened_at', null);
    } else if (type === 'email.clicked' && emailId) {
      await supabase
        .from('outreach_emails')
        .update({ clicked_at: now })
        .eq('resend_id', emailId)
        .is('clicked_at', null);
    } else if (type === 'email.bounced' && emailId) {
      const { data: email } = await supabase
        .from('outreach_emails')
        .select('lead_id')
        .eq('resend_id', emailId)
        .single();
      if (email?.lead_id) {
        await supabase
          .from('leads')
          .update({ status: 'bounced', notes: 'Email bounced.' })
          .eq('id', email.lead_id);
      }
    } else if (type === 'email.unsubscribed' && emailId) {
      const { data: email } = await supabase
        .from('outreach_emails')
        .select('lead_id')
        .eq('resend_id', emailId)
        .single();
      if (email?.lead_id) {
        await supabase.from('leads').update({ status: 'unsubscribed' }).eq('id', email.lead_id);
      }
    } else {
      console.log('Unhandled event type:', type);
    }

    await supabase.from('outreach_webhook_events').insert({ svix_id: svixId, event_type: type });
  } catch (err) {
    console.error('resend-outreach-webhook processing error:', err);
    // Return 200 so Resend does not retry a permanent failure
  }

  return json({ received: true });
});
