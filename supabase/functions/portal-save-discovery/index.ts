// Edge Function: portal-save-discovery
// Saves (draft) or submits the client discovery form.
// Auth: Supabase magic-link session — email must match quote.client_email

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

async function getAuthEmail(authHeader: string | null): Promise<string | null> {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice(7);
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user?.email) return null;
  return user.email;
}

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  const resendKey = Deno.env.get('RESEND_API_KEY');
  if (!resendKey) return;
  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: Deno.env.get('EMAIL_FROM') ?? 'hello@raspucat.com',
      to,
      subject,
      html,
    }),
  }).catch(console.error);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authEmail = await getAuthEmail(req.headers.get('Authorization'));
    if (!authEmail) return json({ error: 'Unauthorized.' }, 401);

    const { quote_id, discovery_data, submit } = await req.json();

    if (!quote_id || discovery_data === undefined || typeof discovery_data !== 'object') {
      return json({ error: 'Missing required fields.' }, 400);
    }

    // Verify ownership
    const { data: quote, error: fetchError } = await supabase
      .from('quotes')
      .select('id, client_email, business_name, discovery_submitted_at')
      .eq('id', quote_id)
      .single();

    if (fetchError || !quote) return json({ error: 'Quote not found.' }, 404);
    if (quote.client_email.toLowerCase() !== authEmail.toLowerCase()) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    // Idempotent: already submitted
    if (submit && quote.discovery_submitted_at) {
      return json({ ok: true, submitted: true, alreadySubmitted: true });
    }

    // Don't overwrite with empty object on draft save
    if (!submit && Object.keys(discovery_data).length === 0) {
      return json({ ok: true, submitted: false });
    }

    const updatePayload: Record<string, unknown> = { discovery_data };
    if (submit) {
      updatePayload['discovery_submitted_at'] = new Date().toISOString();
      updatePayload['portal_stage'] = 'transmitting';
    }

    const { error: updateError } = await supabase
      .from('quotes')
      .update(updatePayload)
      .eq('id', quote_id);

    if (updateError) {
      console.error('Discovery save error:', updateError);
      return json({ error: 'Failed to save.' }, 500);
    }

    if (submit) {
      const appUrl = Deno.env.get('APP_URL') ?? 'https://raspucat.com';
      const adminEmail = Deno.env.get('ADMIN_EMAIL') ?? 'meow@raspucat.com';

      // Client confirmation
      await sendEmail(
        quote.client_email,
        'Discovery Form Received — We\'re On It.',
        `<p>Hi ${quote.business_name},</p>
        <p>We've received your Discovery Form — thank you for taking the time. This gives us a strong foundation to begin crafting your site.</p>
        <p>We'll be in touch shortly to schedule a deep discovery session where we'll align on your vision, goals, and every detail that makes your brand unique.</p>
        <p>Track your project's progress anytime in your <a href="${appUrl}/portal">Client Portal</a>.</p>`,
      );

      // Admin notification
      await sendEmail(
        adminEmail,
        `Discovery Form Submitted — ${quote.business_name}`,
        `<p>Discovery form submitted by <strong>${quote.business_name}</strong>.</p>
        <p>Quote ID: <code>${quote.id}</code></p>
        <p><a href="${appUrl}/admin">View in Admin Panel →</a></p>`,
      );
    }

    return json({ ok: true, submitted: !!submit });
  } catch (err) {
    console.error('portal-save-discovery error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
