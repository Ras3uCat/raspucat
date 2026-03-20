// Edge Function: admin-mark-module-live
// Marks a client-purchased add-on module as live:
//   1. Sets live_at on client_modules_pending
//   2. Inserts into quote_modules (making it an active module for the client)
//   3. Logs a module_activated event to quote_events

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

  const body = await req.json() as { adminToken: string; pendingModuleId: string };

  if (!ADMIN_PASSWORD || body.adminToken !== ADMIN_PASSWORD) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // Fetch the pending record to get quote_id and module_id
  const { data: pending, error: fetchError } = await supabase
    .from('client_modules_pending')
    .select('id, quote_id, module_id, live_at')
    .eq('id', body.pendingModuleId)
    .maybeSingle();

  if (fetchError || !pending) {
    return new Response(JSON.stringify({ error: 'Pending module not found.' }), {
      status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const p = pending as Record<string, unknown>;

  // Guard: already live
  if (p['live_at'] !== null) {
    return new Response(JSON.stringify({ error: 'Module is already live.' }), {
      status: 409, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  const quoteId = p['quote_id'] as string;
  const moduleId = p['module_id'] as string;
  const now = new Date().toISOString();

  // Run all three writes in parallel
  const [liveResult, moduleResult, eventResult] = await Promise.all([
    // 1. Set live_at
    supabase
      .from('client_modules_pending')
      .update({ live_at: now })
      .eq('id', body.pendingModuleId),

    // 2. Insert into quote_modules (upsert to avoid duplicate if somehow already there)
    supabase
      .from('quote_modules')
      .upsert({ quote_id: quoteId, module_id: moduleId }, { onConflict: 'quote_id,module_id' }),

    // 3. Log to quote_events
    supabase
      .from('quote_events')
      .insert({
        quote_id: quoteId,
        event_type: 'module_activated',
        metadata: { module_id: moduleId, pending_module_id: body.pendingModuleId },
      }),
  ]);

  const err = liveResult.error ?? moduleResult.error ?? eventResult.error;
  if (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
