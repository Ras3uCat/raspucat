// Edge Function: portal-upload-asset
// Uploads a logo or social share image for the authenticated portal user.
//
// Body: { quoteId, field: 'logo' | 'og_image', fileBase64, mimeType, fileName }
// Auth: Bearer JWT (portal user session)

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
    // Verify user session
    const authHeader = req.headers.get('Authorization') ?? '';
    const { data: { user }, error: authErr } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', ''),
    );
    if (authErr || !user) return json({ error: 'Unauthorized.' }, 401);

    const body = await req.json() as Record<string, unknown>;
    const quoteId  = body.quoteId  as string | undefined;
    const field    = body.field    as string | undefined;
    const b64      = body.fileBase64 as string | undefined;
    const mimeType = body.mimeType as string | undefined;
    const fileName = body.fileName as string | undefined;

    if (!quoteId || !field || !b64 || !mimeType || !fileName) {
      return json({ error: 'quoteId, field, fileBase64, mimeType, fileName are required.' }, 400);
    }
    if (field !== 'logo' && field !== 'og_image') {
      return json({ error: 'field must be logo or og_image.' }, 400);
    }

    // Verify the quote belongs to this user
    const { data: quote, error: quoteErr } = await supabase
      .from('quotes')
      .select('id, discovery_data')
      .eq('id', quoteId)
      .eq('user_id', user.id)
      .single();

    if (quoteErr || !quote) return json({ error: 'Quote not found.' }, 404);

    // Decode and upload
    const binary = atob(b64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);

    const folder = field === 'logo' ? 'logos' : 'og';
    const storagePath = `portal/${folder}/${quoteId}/${fileName}`;

    const { error: uploadError } = await supabase.storage
      .from('admin-assets')
      .upload(storagePath, bytes, { contentType: mimeType, upsert: true });

    if (uploadError) return json({ error: uploadError.message }, 500);

    const { data: { publicUrl } } = supabase.storage
      .from('admin-assets')
      .getPublicUrl(storagePath);

    // Patch discovery_data with the new URL
    const dataKey = field === 'logo' ? 'LOGO_URL' : 'OG_IMAGE';
    const updated = { ...(quote.discovery_data ?? {}), [dataKey]: publicUrl };

    const { error: dbError } = await supabase
      .from('quotes')
      .update({ discovery_data: updated })
      .eq('id', quoteId);

    if (dbError) return json({ error: dbError.message }, 500);

    return json({ url: publicUrl });
  } catch (err) {
    console.error('portal-upload-asset error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
