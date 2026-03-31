// Edge Function: admin-save-discovery
// Admin-only update of discovery_data.
// Does NOT change portal_stage or discovery_submitted_at — admin edits never retrigger client emails.

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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { adminToken, quote_id, discovery_data } = await req.json();

    const adminPassword = Deno.env.get('ADMIN_PASSWORD');
    if (!adminPassword || adminToken !== adminPassword) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    if (!quote_id || !discovery_data || typeof discovery_data !== 'object') {
      return json({ error: 'Missing required fields.' }, 400);
    }

    const { error } = await supabase
      .from('quotes')
      .update({ discovery_data })
      .eq('id', quote_id);

    if (error) {
      console.error('admin-save-discovery error:', error);
      return json({ error: 'Failed to update.' }, 500);
    }

    return json({ ok: true });
  } catch (err) {
    console.error('admin-save-discovery error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
