// Edge Function: admin-settings
// Get or set app-level settings (stored in app_settings table).
//
// Actions:
//   get → returns { key, value } for a given key
//   set → upserts { key, value } and returns { ok: true }

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
    const body = await req.json() as Record<string, unknown>;
    const adminPassword = Deno.env.get('ADMIN_PASSWORD');

    if (!adminPassword || body.adminToken !== adminPassword) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    const action = body.action as string;
    const key = body.key as string | undefined;
    if (!key) return json({ error: 'key is required.' }, 400);

    if (action === 'get') {
      const { data, error } = await supabase
        .from('app_settings')
        .select('key, value')
        .eq('key', key)
        .single();

      if (error) return json({ key, value: '' });
      return json({ key: data.key, value: data.value ?? '' });
    }

    if (action === 'set') {
      const value = (body.value as string | undefined) ?? '';
      const { error } = await supabase
        .from('app_settings')
        .upsert({ key, value, updated_at: new Date().toISOString() }, { onConflict: 'key' });

      if (error) return json({ error: error.message }, 500);
      return json({ ok: true });
    }

    return json({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    console.error('admin-settings error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
