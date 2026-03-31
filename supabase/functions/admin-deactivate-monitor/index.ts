// Edge Function: admin-deactivate-monitor
// Pauses/deletes the UptimeRobot monitor for a quote and clears uptimerobot_monitor_id.
// Called by admin-cancel-subscription on cancellation. Protected by ADMIN_PASSWORD.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { quoteId, adminToken } = await req.json();

    if (adminToken !== Deno.env.get('ADMIN_PASSWORD')) {
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

    const { data: quote } = await supabase
      .from('quotes')
      .select('uptimerobot_monitor_id')
      .eq('id', quoteId)
      .single();

    const monitorId = quote?.uptimerobot_monitor_id;

    if (monitorId) {
      const apiKey = Deno.env.get('UPTIMEROBOT_API_KEY');
      if (apiKey) {
        const formData = new URLSearchParams({
          api_key: apiKey,
          format: 'json',
          id: monitorId,
        });

        const resp = await fetch('https://api.uptimerobot.com/v2/deleteMonitor', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: formData.toString(),
        });

        const json = await resp.json();
        if (json.stat !== 'ok') {
          console.error('UptimeRobot deleteMonitor error:', JSON.stringify(json));
          // Non-fatal — still clear the DB field
        }
      }
    }

    await supabase
      .from('quotes')
      .update({ uptimerobot_monitor_id: null, uptime_status: 'unknown' })
      .eq('id', quoteId);

    return new Response(JSON.stringify({ success: true, cleared: !!monitorId }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('admin-deactivate-monitor error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
