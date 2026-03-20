// Edge Function: admin-send-message
// Sends a message as admin and marks all unread client messages as read.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const ADMIN_PASSWORD = Deno.env.get('ADMIN_PASSWORD');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const body = await req.json() as { adminToken: string; quoteId: string; messageBody: string };

  if (!ADMIN_PASSWORD || body.adminToken !== ADMIN_PASSWORD) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  if (!body.quoteId || !body.messageBody?.trim()) {
    return new Response(JSON.stringify({ error: 'quoteId and messageBody are required.' }), {
      status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const now = new Date().toISOString();

  const [{ error: insertError }, _] = await Promise.all([
    supabase.from('portal_messages').insert({
      quote_id: body.quoteId,
      sender: 'admin',
      body: body.messageBody.trim(),
    }),
    // Mark any unread client messages as read when admin replies
    supabase
      .from('portal_messages')
      .update({ read_at: now })
      .eq('quote_id', body.quoteId)
      .eq('sender', 'client')
      .is('read_at', null),
  ]);

  if (insertError) {
    return new Response(JSON.stringify({ error: insertError.message }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
