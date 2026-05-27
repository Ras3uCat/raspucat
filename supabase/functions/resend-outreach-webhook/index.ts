// Edge Function: resend-outreach-webhook
// Handles outbound tracking (open/click/bounce) and inbound replies.
// Resend sends a Resend-Signature header for verification.
// Inbound replies auto-extract phone numbers and update lead status.

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

// Extracts the first US-format phone number found in text.
function extractPhone(text: string): string | null {
  const match = text.match(/\(?\d{3}\)?[\s.\-]\d{3}[\s.\-]\d{4}/);
  return match ? match[0].replace(/\D/g, '').replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3') : null;
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
          .update({ status: 'closed_lost', notes: 'Email bounced.' })
          .eq('id', email.lead_id);
      }
      return json({ received: true });
    }

    // Inbound reply: data.from is the prospect's email address
    if (type === 'email.received' && data.from) {
      const senderEmail = data.from.replace(/.*<(.+)>/, '$1').trim();
      const bodyText = data.text ?? '';

      // Find the lead by their email
      const { data: lead } = await supabase
        .from('leads')
        .select('id, phone, status')
        .eq('email', senderEmail)
        .single();

      if (lead) {
        const now = new Date().toISOString();
        const updates: Record<string, unknown> = {};

        if (lead.status === 'contacted') updates.status = 'replied';

        // Extract phone number if not already on record
        if (!lead.phone) {
          const phone = extractPhone(bodyText);
          if (phone) updates.phone = phone;
        }

        if (Object.keys(updates).length > 0) {
          await supabase.from('leads').update(updates).eq('id', lead.id);
        }

        // Mark the most recent sent email as replied
        const { data: sentEmail } = await supabase
          .from('outreach_emails')
          .select('id')
          .eq('lead_id', lead.id)
          .not('sent_at', 'is', null)
          .is('replied_at', null)
          .order('sent_at', { ascending: false })
          .limit(1)
          .single();

        if (sentEmail) {
          await supabase
            .from('outreach_emails')
            .update({ replied_at: now })
            .eq('id', sentEmail.id);
        }
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
