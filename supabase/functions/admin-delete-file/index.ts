// Edge Function: admin-delete-file
// Deletes a file from storage and the portal_files table.

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

  const body = await req.json() as {
    adminToken: string;
    fileId: string;
    storagePath: string;
  };

  if (!ADMIN_PASSWORD || body.adminToken !== ADMIN_PASSWORD) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  if (!body.fileId || !body.storagePath) {
    return new Response(JSON.stringify({ error: 'fileId and storagePath are required.' }), {
      status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const [{ error: storageError }, { error: dbError }] = await Promise.all([
    supabase.storage.from('portal-files').remove([body.storagePath]),
    supabase.from('portal_files').delete().eq('id', body.fileId),
  ]);

  if (storageError || dbError) {
    return new Response(
      JSON.stringify({ error: storageError?.message ?? dbError?.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
