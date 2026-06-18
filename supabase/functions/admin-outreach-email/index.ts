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
const FROM_NAME = 'Ras3ucat';

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

const LOGO_URL = 'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';

function wrapEmailHtml(bodyHtml: string, leadId: string, subject?: string): string {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const unsubUrl = `${supabaseUrl}/functions/v1/public-unsubscribe?id=${leadId}`;
  const bookingUrl = `${SITE_URL}/book?leadId=${leadId}`;
  const subjectHeader = subject
    ? `<p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58e3ef;margin:0 0 14px;text-transform:uppercase;">Web Design &amp; Development</p><h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#e8feff;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">${subject}</h1>`
    : '';
  const bookingButtonHtml = `<div style="text-align:center;margin:28px 0;"><a href="${bookingUrl}" style="display:inline-block;padding:14px 36px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58e3ef;font-family:'Space Grotesk',sans-serif;font-size:13px;font-weight:600;letter-spacing:2px;text-decoration:none;text-transform:uppercase;">Book a Free Website Audit &amp; Strategy Session &rarr;</a></div>`;
  // Strip sign-off block — footer already contains attribution
  const stripped = bodyHtml
    .replace(/<p[^>]*>\s*Best,\s*<\/p>\s*<p[^>]*>\s*Ryan and Cytarah Richardson\s*<\/p>\s*<p[^>]*>\s*Ras3?u?[Cc]at\s*<\/p>\s*<p[^>]*>\s*meow@raspucat\.com\s*<\/p>/gi, '')
    .replace(/<p[^>]*>\s*Best,(<br\s*\/?>)\s*Ryan and Cytarah Richardson\1\s*Ras3?u?[Cc]at\1\s*meow@raspucat\.com\s*<\/p>/gi, '');
  const processedBody = stripped
    .replace(/<p[^>]*>[^<]*\{BOOKING_LINK\}[^<]*<\/p>/gi, bookingButtonHtml)
    .replace(/\{BOOKING_LINK\}/gi, bookingButtonHtml);
  const hasInlineButton = processedBody !== stripped;
  const DEMO_URL = 'https://demo.raspucat.com';
  const demoButtonHtml = `<div style="text-align:center;margin:28px 0;"><a href="${DEMO_URL}" style="display:inline-block;padding:14px 36px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58e3ef;font-family:'Space Grotesk',sans-serif;font-size:13px;font-weight:600;letter-spacing:2px;text-decoration:none;text-transform:uppercase;">Explore the Demo &rarr;</a></div>`;
  const finalBody = processedBody
    .replace(/<p[^>]*>[^<]*\{DEMO_LINK\}[^<]*<\/p>/gi, demoButtonHtml)
    .replace(/\{DEMO_LINK\}/gi, demoButtonHtml);
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600&family=Inter:wght@400;500&display=swap');
    p { color: rgba(232,254,255,0.65); font-size: 15px; line-height: 1.8; margin: 0 0 16px; }
    ul { margin: 0 0 16px; padding-left: 20px; }
    li { color: rgba(232,254,255,0.65); font-size: 15px; line-height: 1.8; margin: 0 0 6px; }
  </style>
</head>
<body style="margin:0;padding:0;background:#000612;font-family:Inter,sans-serif;-webkit-font-smoothing:antialiased;">
<div style="max-width:600px;margin:0 auto;padding:40px 24px;">
  <div style="text-align:center;padding-bottom:28px;border-bottom:1px solid rgba(88,227,239,0.12);">
    <img src="${LOGO_URL}" alt="Ras3uCat" style="height:56px;width:auto;display:block;margin:0 auto 12px;" />
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;letter-spacing:5px;color:#58E3EF;margin:0 0 6px;text-transform:uppercase;">Ras3uCat</p>
    <p style="font-size:10px;color:rgba(232,254,255,0.3);letter-spacing:2px;margin:0;text-transform:uppercase;">Designed to engage. Engineered to move. Deployed to perform.</p>
  </div>
  <div style="padding:40px 0 32px;">
    ${subjectHeader}${finalBody}${hasInlineButton ? '' : `<div style="text-align:center;margin-top:28px;">${bookingButtonHtml}</div>`}
  </div>
  <div style="padding-top:28px;border-top:1px solid rgba(88,227,239,0.08);">
    <p style="color:rgba(232,254,255,0.4);font-size:13px;margin:0 0 4px;">Best,</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;color:#58E3EF;margin:0;letter-spacing:1px;">Ryan and Cytarah</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:11px;color:rgba(232,254,255,0.2);margin:4px 0 0;letter-spacing:1px;">Ras3uCat &middot; <img src="${LOGO_URL}" alt="" style="height:13px;width:auto;vertical-align:middle;display:inline-block;margin:0 1px;" /> &middot; meow@raspucat.com</p>
  </div>
  <div style="text-align:center;padding-top:32px;">
    <p style="font-size:11px;color:rgba(232,254,255,0.2);margin:0 0 8px;"><a href="${unsubUrl}" style="color:rgba(88,227,239,0.3);text-decoration:none;">Unsubscribe</a></p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:rgba(88,227,239,0.2);margin:0;">Sync complete &#9651; M3OW</p>
  </div>
</div>
</body>
</html>`;
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

    if (action === 'send-test') {
      const { emailId } = body;
      if (!emailId) return json({ error: 'emailId required.' }, 400);
      const { data: email, error: fetchErr } = await supabase
        .from('outreach_emails')
        .select('*, leads(company_name, id)')
        .eq('id', emailId)
        .single();
      if (fetchErr || !email) return json({ error: 'Draft not found.' }, 404);
      const lead = email.leads as { company_name: string; id: string } | null;
      const wrappedHtml = wrapEmailHtml(email.body_html, lead?.id ?? emailId, email.subject);
      const resendId = await sendViaResend('ras3ucat@gmail.com', `[TEST] ${email.subject}`, wrappedHtml);
      if (!resendId) return json({ error: 'Failed to send test email.' }, 500);
      return json({ success: true, resendId });
    }

    if (action === 'update-draft') {
      const { emailId, subject, bodyHtml } = body;
      if (!emailId) return json({ error: 'emailId required.' }, 400);
      const fields: Record<string, unknown> = {};
      if (subject !== undefined) fields.subject = subject;
      if (bodyHtml !== undefined) fields.body_html = bodyHtml;
      if (Object.keys(fields).length === 0) return json({ error: 'Nothing to update.' }, 400);
      const { data, error } = await supabase
        .from('outreach_emails')
        .update(fields)
        .eq('id', emailId)
        .is('sent_at', null)
        .select('*')
        .single();
      if (error) return json({ error: 'Failed to update draft.' }, 500);
      return json({ email: data });
    }

    if (action === 'preview') {
      const { emailId } = body;
      if (!emailId) return json({ error: 'emailId required.' }, 400);
      const { data: email, error: fetchErr } = await supabase
        .from('outreach_emails')
        .select('body_html, lead_id, subject')
        .eq('id', emailId)
        .single();
      if (fetchErr || !email) return json({ error: 'Draft not found.' }, 404);
      return json({ html: wrapEmailHtml(email.body_html, email.lead_id, email.subject) });
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

      const wrappedHtml = wrapEmailHtml(email.body_html, lead.id, email.subject);
      const resendId = await sendViaResend(lead.email, email.subject, wrappedHtml);

      const { data: sendSettings } = await supabase
        .from('outreach_settings').select('follow_up_days').limit(1).maybeSingle();
      const sendFollowUpDays = Math.max(1, sendSettings?.follow_up_days ?? 3);

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
          next_followup_at: new Date(Date.now() + sendFollowUpDays * 24 * 60 * 60 * 1000).toISOString(),
        })
        .eq('id', lead.id)
        .eq('status', 'prospect');

      return json({ success: true, resendId });
    }

    if (action === 'send-batch') {
      const { data: batchSettings } = await supabase
        .from('outreach_settings').select('follow_up_days').limit(1).maybeSingle();
      const batchFollowUpDays = Math.max(1, batchSettings?.follow_up_days ?? 3);

      const { data: drafts, error } = await supabase
        .from('outreach_emails')
        .select('*, leads(company_name, email, id, status)')
        .is('sent_at', null)
        .is('resend_id', null)
        .order('created_at', { ascending: true });

      if (error || !drafts) return json({ error: 'Failed to fetch drafts.' }, 500);

      let sent = 0;
      let failed = 0;
      let skipped = 0;
      const now = new Date().toISOString();
      const followupAt = new Date(Date.now() + batchFollowUpDays * 24 * 60 * 60 * 1000).toISOString();

      for (const email of drafts) {
        const lead = email.leads as { company_name: string; email: string; id: string; status: string } | null;
        if (!lead?.email) { failed++; continue; }
        if (email.resend_id) { skipped++; continue; }

        const wrappedHtml = wrapEmailHtml(email.body_html, lead.id, email.subject);
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
      return json({ sent, failed, skipped });
    }

    if (action === 'auto-draft-followups') {
      const { data: settings } = await supabase
        .from('outreach_settings').select('*').limit(1).single();
      const followUpDays = settings?.follow_up_days ?? 3;
      const maxFollowUps = settings?.max_follow_ups ?? 3;

      // 033: load industry templates once before the loop
      const { data: industryProfiles } = await supabase
        .from('industry_profiles')
        .select('slug, name, email_subject_template, email_body_template');

      const { data: leads, error: leadsErr } = await supabase
        .from('leads')
        .select('id, company_name, email, industry, city, website, decision_maker_name')
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

        // 033: resolve industry template; fall back to generic copy when unset or empty
        const industryKey = lead.industry?.toLowerCase() ?? '';
        const profile = industryKey
          ? (industryProfiles ?? []).find(
              (p: { slug: string; name: string; email_subject_template?: string; email_body_template?: string }) =>
                p.name.toLowerCase() === industryKey || p.slug.toLowerCase() === industryKey
            )
          : undefined;
        const firstName = (lead.decision_maker_name ?? '').split(' ')[0] || '[Name]';
        const company = lead.company_name ?? '[Company]';

        const subject = profile?.email_subject_template
          ? `Re: ${profile.email_subject_template.replace('{COMPANY}', company)}`
          : `Following up — ${company}`;

        const bodyHtml = profile?.email_body_template
          ? profile.email_body_template
              .replace(/\{FIRST_NAME\}/g, firstName)
              .replace(/\{COMPANY\}/g, company)
          : `
<p>Hi,</p>
<p>We wanted to follow up on the note we sent last week in case it got buried.</p>
<p>We are Cytarah and Ryan with Ras3ucat. Our offer still stands — we would be happy to provide a complimentary website and competitor review for ${lead.company_name} at no cost to you. We will highlight opportunities to improve your online presence, customer experience, and competitive positioning.</p>
<p>You can simply reply to this email, or book a free Website Audit &amp; Strategy Session at your convenience.</p>
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
