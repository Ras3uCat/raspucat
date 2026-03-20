// Edge Function: admin-mark-files-seen
// Marks all client-uploaded files for a quote as seen by the admin.
// Protected by ADMIN_PASSWORD env var.

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

  try {
    const { adminToken, quoteId } = await req.json();

    if (!ADMIN_PASSWORD || adminToken !== ADMIN_PASSWORD) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!quoteId) {
      return new Response(JSON.stringify({ error: 'quoteId is required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    await supabase
      .from('portal_files')
      .update({ seen_by_admin_at: new Date().toISOString() })
      .eq('quote_id', quoteId)
      .eq('uploaded_by', 'client')
      .is('seen_by_admin_at', null);

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('admin-mark-files-seen error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
