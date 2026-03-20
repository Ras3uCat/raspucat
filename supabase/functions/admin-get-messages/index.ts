// Edge Function: admin-get-messages
// Fetches the full message thread for a quote and marks all client messages as read.

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

  const body = await req.json() as { adminToken: string; quoteId: string };

  if (!ADMIN_PASSWORD || body.adminToken !== ADMIN_PASSWORD) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  if (!body.quoteId) {
    return new Response(JSON.stringify({ error: 'quoteId is required.' }), {
      status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const now = new Date().toISOString();

  const [{ data: messages, error }, _] = await Promise.all([
    supabase
      .from('portal_messages')
      .select('*')
      .eq('quote_id', body.quoteId)
      .order('created_at', { ascending: true }),
    // Mark all unread client messages as read
    supabase
      .from('portal_messages')
      .update({ read_at: now })
      .eq('quote_id', body.quoteId)
      .eq('sender', 'client')
      .is('read_at', null),
  ]);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  return new Response(JSON.stringify({ messages: messages ?? [] }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
