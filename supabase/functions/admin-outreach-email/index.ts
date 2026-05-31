// Edge Function: admin-outreach-email
// Protected by ADMIN_PASSWORD. Manages email drafts, sending, and settings.
// Body: { adminToken, action, ...payload }
//
// Actions:
//   draft          { leadId, subject, bodyHtml }  — save draft (sent_at=null)
//   send           { emailId }                     — send one approved draft
//   send-batch     {}                              — send all pending drafts for top leads
//   delete-draft   { emailId }
//   list-drafts    { leadId? }
//   settings-get   {}
//   settings-update { emailsPerRun?, runsPerWeek?, followUpDays?, maxFollowUps?,
//                     targetIndustries?, targetCities? }

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const SITE_URL = Deno.env.get('SITE_URL') ?? 'https://ras3ucat.com';
const FROM_EMAIL = 'hello@raspucat.com';
const FROM_NAME = 'Ryan';

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

async function sendViaResend(to: string, subject: string, html: string): Promise<string | null> {
  if (!RESEND_API_KEY) return null;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: `${FROM_NAME} <${FROM_EMAIL}>`, to, subject, html }),
  });
  if (!res.ok) {
    console.error('Resend error:', res.status, await res.text());
    return null;
  }
  const data = await res.json() as { id: string };
  return data.id ?? null;
}

function wrapEmailHtml(bodyHtml: string, leadId: string): string {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const unsubUrl = `${supabaseUrl}/functions/v1/public-unsubscribe?id=${leadId}`;
  const bookingUrl = `${SITE_URL}/book?leadId=${leadId}`;
  return `
<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
  body{margin:0;padding:0;background:#000612;font-family:-apple-system,sans-serif;color:#E8FEFF}
  .wrap{max-width:580px;margin:0 auto;padding:32px 24px}
  .content{background:rgba(88,227,239,0.04);border:1px solid rgba(88,227,239,0.12);
    border-radius:8px;padding:28px 24px;margin-bottom:24px}
  .cta{display:inline-block;background:#58E3EF;color:#000612;font-weight:600;
    padding:12px 24px;border-radius:6px;text-decoration:none;margin:16px 0}
  .footer{font-size:12px;color:rgba(232,255,255,0.4);line-height:1.6}
  a{color:#58E3EF}
</style></head><body>
<div class="wrap">
  <div class="content">
    ${bodyHtml}
    <p><a class="cta" href="${bookingUrl}">Book a free 30-min call →</a></p>
  </div>
  <div class="footer">
    <p>Ryan · Raspucat Web Studio · Liberty Hill, TX</p>
    <p><a href="${unsubUrl}">Unsubscribe</a> from these emails.</p>
  </div>
</div></body></html>`;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json();
    const { adminToken, action } = body;

    const adminPassword = Deno.env.get('ADMIN_PASSWORD');
    const cronSecret = Deno.env.get('CRON_SECRET');
    const authHeader = req.headers.get('Authorization');
    const isCron = cronSecret && authHeader === `Bearer ${cronSecret}`;
    const isAdmin = adminPassword && adminToken === adminPassword;
    if (!isCron && !isAdmin) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    if (action === 'settings-get') {
      const { data } = await supabase.from('outreach_settings').select('*').limit(1).single();
      return json({ settings: data ?? null });
    }

    if (action === 'settings-update') {
      const { data: existing } = await supabase
        .from('outreach_settings').select('id').limit(1).single();

      const fields: Record<string, unknown> = { updated_at: new Date().toISOString() };
      if (body.emailsPerRun !== undefined) fields.emails_per_run = body.emailsPerRun;
      if (body.runsPerWeek !== undefined) fields.runs_per_week = body.runsPerWeek;
      if (body.followUpDays !== undefined) fields.follow_up_days = body.followUpDays;
      if (body.maxFollowUps !== undefined) fields.max_follow_ups = body.maxFollowUps;
      if (body.targetIndustries !== undefined) fields.target_industries = body.targetIndustries;
      if (body.targetCities !== undefined) fields.target_cities = body.targetCities;
      if (body.discoveryRunsPerWeek !== undefined) fields.discovery_runs_per_week = body.discoveryRunsPerWeek;

      if (existing?.id) {
        await supabase.from('outreach_settings').update(fields).eq('id', existing.id);
      } else {
        await supabase.from('outreach_settings').insert(fields);
      }
      const { data } = await supabase.from('outreach_settings').select('*').limit(1).single();
      return json({ settings: data });
    }

    if (action === 'draft') {
      const { leadId, subject, bodyHtml, notes } = body;
      if (!leadId || !subject || !bodyHtml) {
        return json({ error: 'leadId, subject, and bodyHtml required.' }, 400);
      }
      const { data: existing } = await supabase
        .from('outreach_emails')
        .select('sequence_step')
        .eq('lead_id', leadId)
        .order('sequence_step', { ascending: false })
        .limit(1)
        .single();
      const step = (existing?.sequence_step ?? 0) + 1;

      const { data, error } = await supabase
        .from('outreach_emails')
        .insert({ lead_id: leadId, subject, body_html: bodyHtml, sequence_step: step, sent_at: null, ...(notes ? { notes } : {}) })
        .select('*')
        .single();
      if (error) {
        console.error('draft error:', error);
        return json({ error: 'Failed to save draft.' }, 500);
      }
      return json({ email: data });
    }

    if (action === 'list-drafts') {
      const { leadId } = body;
      let query = supabase
        .from('outreach_emails')
        .select('id, lead_id, subject, body_html, notes, sequence_step, created_at, resend_id, sent_at, opened_at, clicked_at, replied_at, leads(company_name, email, industry, city)')
        .is('sent_at', null)
        .order('created_at', { ascending: true });
      if (leadId) query = query.eq('lead_id', leadId);
      const { data, error } = await query;
      if (error) return json({ error: 'Failed to list drafts.' }, 500);
      return json({ drafts: data ?? [] });
    }

    if (action === 'delete-draft') {
      const { emailId } = body;
      if (!emailId) return json({ error: 'emailId required.' }, 400);
      await supabase.from('outreach_emails').delete().eq('id', emailId).is('sent_at', null);
      return json({ success: true });
    }

    if (action === 'send') {
      const { emailId } = body;
      if (!emailId) return json({ error: 'emailId required.' }, 400);

      const { data: email, error: fetchErr } = await supabase
        .from('outreach_emails')
        .select('*, leads(company_name, email, id)')
        .eq('id', emailId)
        .is('sent_at', null)
        .single();
      if (fetchErr || !email) return json({ error: 'Draft not found.' }, 404);

      const lead = email.leads as { company_name: string; email: string; id: string } | null;
      if (!lead?.email) return json({ error: 'Lead has no email address.' }, 400);

      const wrappedHtml = wrapEmailHtml(email.body_html, lead.id);
      const resendId = await sendViaResend(lead.email, email.subject, wrappedHtml);

      const now = new Date().toISOString();
      await supabase
        .from('outreach_emails')
        .update({ sent_at: now, resend_id: resendId })
        .eq('id', emailId);
      await supabase
        .from('leads')
        .update({
          status: 'contacted',
          last_contacted_at: now,
          next_followup_at: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
        })
        .eq('id', lead.id)
        .eq('status', 'prospect');

      return json({ success: true, resendId });
    }

    if (action === 'send-batch') {
      const { data: drafts, error } = await supabase
        .from('outreach_emails')
        .select('*, leads(company_name, email, id, status)')
        .is('sent_at', null)
        .order('created_at', { ascending: true });

      if (error || !drafts) return json({ error: 'Failed to fetch drafts.' }, 500);

      let sent = 0;
      let failed = 0;
      const now = new Date().toISOString();
      const followupAt = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();

      for (const email of drafts) {
        const lead = email.leads as { company_name: string; email: string; id: string; status: string } | null;
        if (!lead?.email) { failed++; continue; }

        const wrappedHtml = wrapEmailHtml(email.body_html, lead.id);
        const resendId = await sendViaResend(lead.email, email.subject, wrappedHtml);

        await supabase
          .from('outreach_emails')
          .update({ sent_at: now, resend_id: resendId })
          .eq('id', email.id);

        if (lead.status === 'prospect') {
          await supabase
            .from('leads')
            .update({ status: 'contacted', last_contacted_at: now, next_followup_at: followupAt })
            .eq('id', lead.id);
        }
        sent++;
      }
      return json({ sent, failed });
    }

    if (action === 'auto-draft-followups') {
      const { data: settings } = await supabase
        .from('outreach_settings').select('*').limit(1).single();
      const followUpDays = settings?.follow_up_days ?? 3;
      const maxFollowUps = settings?.max_follow_ups ?? 3;

      const { data: leads, error: leadsErr } = await supabase
        .from('leads')
        .select('id, company_name, email, industry, city, website')
        .eq('status', 'contacted')
        .lte('next_followup_at', new Date().toISOString())
        .not('email', 'is', null);

      if (leadsErr || !leads) return json({ error: 'Failed to fetch leads.' }, 500);

      let drafted = 0;
      let skipped = 0;

      for (const lead of leads) {
        const { count } = await supabase
          .from('outreach_emails')
          .select('id', { count: 'exact', head: true })
          .eq('lead_id', lead.id)
          .not('sent_at', 'is', null);

        if ((count ?? 0) >= maxFollowUps) { skipped++; continue; }

        const { data: existing } = await supabase
          .from('outreach_emails')
          .select('sequence_step')
          .eq('lead_id', lead.id)
          .order('sequence_step', { ascending: false })
          .limit(1)
          .single();
        const step = (existing?.sequence_step ?? 0) + 1;

        const subject = `Following up — ${lead.company_name}`;
        const bodyHtml = `
<p>Hi there,</p>
<p>I wanted to follow up on my previous email about your website for ${lead.company_name}.</p>
<p>I've had a chance to look at your site and put together some ideas that could help you [add specific value here].</p>
<p>Would you be open to a quick 30-minute call to talk through it?</p>
<p>Ryan<br>Raspucat Web Studio</p>
        `.trim();

        await supabase.from('outreach_emails').insert({
          lead_id: lead.id,
          subject,
          body_html: bodyHtml,
          sequence_step: step,
          sent_at: null,
        });

        const nextFollowupAt = new Date(Date.now() + followUpDays * 24 * 60 * 60 * 1000).toISOString();
        await supabase
          .from('leads')
          .update({ next_followup_at: nextFollowupAt })
          .eq('id', lead.id);

        drafted++;
      }

      return json({ drafted, skipped });
    }

    return json({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    console.error('admin-outreach-email error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
