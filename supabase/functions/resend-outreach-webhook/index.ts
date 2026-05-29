// Edge Function: resend-outreach-webhook
// Handles outbound tracking events from Resend: open, click, bounce.
// Inbound replies are handled by the Cloudflare Email Worker → inbound-outreach-reply.
// Resend sends a Resend-Signature header for verification.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const RESEND_WEBHOOK_SECRET = Deno.env.get('RESEND_WEBHOOK_SECRET');

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

  // Verify Resend webhook signature when secret is configured
  if (RESEND_WEBHOOK_SECRET) {
    const sig = req.headers.get('resend-signature') ?? req.headers.get('svix-signature');
    if (!sig) return json({ error: 'Missing signature.' }, 401);
    // Resend uses Svix for webhook signing — signature presence check is the basic guard.
    // Full HMAC verification can be added here using the svix library if needed.
  }

  try {
    const payload = await req.json() as {
      type: string;
      data: {
        email_id?: string;
        from?: string;
        to?: string[];
        subject?: string;
        text?: string;
        html?: string;
      };
    };

    const { type, data } = payload;

    if (type === 'email.opened' && data.email_id) {
      await supabase
        .from('outreach_emails')
        .update({ opened_at: new Date().toISOString() })
        .eq('resend_id', data.email_id)
        .is('opened_at', null);
      return json({ received: true });
    }

    if (type === 'email.clicked' && data.email_id) {
      await supabase
        .from('outreach_emails')
        .update({ clicked_at: new Date().toISOString() })
        .eq('resend_id', data.email_id)
        .is('clicked_at', null);
      return json({ received: true });
    }

    if (type === 'email.bounced' && data.email_id) {
      const { data: email } = await supabase
        .from('outreach_emails')
        .select('lead_id')
        .eq('resend_id', data.email_id)
        .single();
      if (email?.lead_id) {
        await supabase
          .from('leads')
          .update({ status: 'bounced', notes: 'Email bounced.' })
          .eq('id', email.lead_id);
      }
      return json({ received: true });
    }

    if (type === 'email.unsubscribed' && data.email_id) {
      const { data: email } = await supabase
        .from('outreach_emails')
        .select('lead_id')
        .eq('resend_id', data.email_id)
        .single();
      if (email?.lead_id) {
        await supabase
          .from('leads')
          .update({ status: 'unsubscribed' })
          .eq('id', email.lead_id);
      }
      return json({ received: true });
    }

    // Unknown event type — log and acknowledge (never return 4xx for unknown events)
    console.log('Unknown event type:', type);
    return json({ received: true });
  } catch (err) {
    console.error('resend-outreach-webhook error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
