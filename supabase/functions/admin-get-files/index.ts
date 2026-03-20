// Edge Function: admin-get-files
// Lists all portal_files for a quote and returns signed download URLs.

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

  const { data: files, error } = await supabase
    .from('portal_files')
    .select('*')
    .eq('quote_id', body.quoteId)
    .order('created_at', { ascending: false });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // Generate signed URLs for each file (1-hour TTL)
  const withUrls = await Promise.all(
    (files ?? []).map(async (f) => {
      const { data: urlData } = await supabase.storage
        .from('portal-files')
        .createSignedUrl(f.storage_path, 3600);
      return { ...f, signed_url: urlData?.signedUrl ?? null };
    }),
  );

  return new Response(JSON.stringify({ files: withUrls }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
