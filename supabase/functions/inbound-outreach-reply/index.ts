// Edge Function: inbound-outreach-reply
// Called exclusively by the Cloudflare Email Worker when an inbound reply arrives
// at meow@raspucat.com. Stores reply body and updates lead status.
// Auth: x-worker-secret header must match CF_WORKER_SECRET env var.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const CF_WORKER_SECRET = Deno.env.get('CF_WORKER_SECRET');

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function extractPhone(text: string): string | null {
  const match = text.match(/\(?\d{3}\)?[\s.\-]\d{3}[\s.\-]\d{4}/);
  return match ? match[0].replace(/\D/g, '').replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3') : null;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  const workerSecret = req.headers.get('x-worker-secret');
  if (!CF_WORKER_SECRET || workerSecret !== CF_WORKER_SECRET) {
    return json({ error: 'Unauthorized.' }, 401);
  }

  try {
    const { from, subject, text, html } = await req.json() as {
      from: string;
      subject: string;
      text: string;
      html: string;
    };

    if (!from) return json({ error: 'from is required.' }, 400);

    // Normalize: strip display name if present ("John Smith <john@example.com>")
    const senderEmail = from.replace(/.*<(.+)>/, '$1').trim().toLowerCase();

    const { data: lead } = await supabase
      .from('leads')
      .select('id, phone, status')
      .eq('email', senderEmail)
      .single();

    if (!lead) {
      console.log('Inbound reply from unknown address:', senderEmail);
      return json({ received: true });
    }

    const now = new Date().toISOString();

    // Find the most recent sent email for this lead with no reply yet
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
        .update({
          replied_at: now,
          reply_body: text?.trim() || null,
          reply_html: html?.trim() || null,
          reply_from: from.trim(),
        })
        .eq('id', sentEmail.id);
    }

    const leadUpdates: Record<string, unknown> = {};
    if (lead.status === 'contacted') leadUpdates.status = 'replied';
    if (!lead.phone && text) {
      const phone = extractPhone(text);
      if (phone) leadUpdates.phone = phone;
    }

    if (Object.keys(leadUpdates).length > 0) {
      await supabase.from('leads').update(leadUpdates).eq('id', lead.id);
    }

    return json({ received: true });
  } catch (err) {
    console.error('inbound-outreach-reply error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
