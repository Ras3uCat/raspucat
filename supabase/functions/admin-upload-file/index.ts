// Edge Function: admin-upload-file
// Accepts a base64-encoded file from admin and stores it in portal-files/{quoteId}/admin/.

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
    quoteId: string;
    fileName: string;
    mimeType: string;
    fileBase64: string;
  };

  if (!ADMIN_PASSWORD || body.adminToken !== ADMIN_PASSWORD) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  if (!body.quoteId || !body.fileName || !body.fileBase64) {
    return new Response(JSON.stringify({ error: 'quoteId, fileName, and fileBase64 are required.' }), {
      status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const ts = Date.now();
  const safeName = body.fileName.replace(/[^\w.\-]/g, '_');
  const storagePath = `${body.quoteId}/admin/${ts}_${safeName}`;

  // Decode base64 → Uint8Array
  const binaryStr = atob(body.fileBase64);
  const bytes = new Uint8Array(binaryStr.length);
  for (let i = 0; i < binaryStr.length; i++) bytes[i] = binaryStr.charCodeAt(i);

  const { error: uploadError } = await supabase.storage
    .from('portal-files')
    .upload(storagePath, bytes, {
      contentType: body.mimeType || 'application/octet-stream',
      upsert: false,
    });

  if (uploadError) {
    return new Response(JSON.stringify({ error: uploadError.message }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const { data: row, error: dbError } = await supabase
    .from('portal_files')
    .insert({
      quote_id: body.quoteId,
      uploaded_by: 'admin',
      file_name: body.fileName,
      storage_path: storagePath,
      mime_type: body.mimeType || 'application/octet-stream',
      size_bytes: bytes.length,
    })
    .select()
    .single();

  if (dbError) {
    return new Response(JSON.stringify({ error: dbError.message }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // Return with signed URL
  const { data: urlData } = await supabase.storage
    .from('portal-files')
    .createSignedUrl(storagePath, 3600);

  return new Response(JSON.stringify({ file: { ...row, signed_url: urlData?.signedUrl ?? null } }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
