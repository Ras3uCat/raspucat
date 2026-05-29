// Edge Function: public-unsubscribe
// GET /functions/v1/public-unsubscribe?id={leadId}
// Marks a lead as unsubscribed and returns an HTML confirmation page.
// No auth required — the leadId in the URL is the credential.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

function htmlPage(title: string, body: string): Response {
  return new Response(
    `<!DOCTYPE html><html><head><meta charset="utf-8"><title>${title}</title>
<style>
  body{margin:0;padding:0;background:#000612;font-family:-apple-system,sans-serif;color:#E8FEFF;
    display:flex;align-items:center;justify-content:center;min-height:100vh}
  .card{background:rgba(88,227,239,0.04);border:1px solid rgba(88,227,239,0.12);
    border-radius:8px;padding:40px 32px;max-width:440px;text-align:center}
  h2{color:#58E3EF;margin-bottom:12px}
  p{color:rgba(232,255,255,0.6);line-height:1.6}
</style></head><body>
<div class="card">
  <h2>${title}</h2>
  ${body}
</div></body></html>`,
    { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } },
  );
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const leadId = url.searchParams.get('id');

  if (!leadId) {
    return htmlPage('Invalid Link', '<p>This unsubscribe link is invalid or has expired.</p>');
  }

  const { error } = await supabase
    .from('leads')
    .update({ status: 'unsubscribed' })
    .eq('id', leadId)
    .not('status', 'eq', 'unsubscribed');

  if (error) {
    console.error('unsubscribe error:', error);
    return htmlPage('Something went wrong', '<p>We could not process your request. Please reply to any email from us and we will remove you manually.</p>');
  }

  return htmlPage(
    "You're unsubscribed",
    "<p>You've been removed from our outreach list and won't receive any more emails from us.</p><p>Made a mistake? Reply to any of our emails and we'll add you back.</p>",
  );
});
