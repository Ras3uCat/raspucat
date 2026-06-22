// Edge Function: admin-create-monitor
// Creates a UptimeRobot HTTP monitor for a site URL and stores the monitor_id on the quote.
// Called internally by admin-register-site. Protected by ADMIN_PASSWORD.

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
    const { quoteId, siteUrl, adminToken } = await req.json();

    if (adminToken !== Deno.env.get('ADMIN_PASSWORD')) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!quoteId || !siteUrl) {
      return new Response(JSON.stringify({ error: 'quoteId and siteUrl are required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const apiKey = Deno.env.get('UPTIMEROBOT_API_KEY');
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'UPTIMEROBOT_API_KEY not configured.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Check if monitor already exists for this quote
    const { data: existing } = await supabase
      .from('quotes')
      .select('uptimerobot_monitor_id')
      .eq('id', quoteId)
      .single();

    if (existing?.uptimerobot_monitor_id) {
      return new Response(JSON.stringify({ monitor_id: existing.uptimerobot_monitor_id, existing: true }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Create UptimeRobot monitor (type 1 = HTTP)
    const formData = new URLSearchParams({
      api_key: apiKey,
      format: 'json',
      type: '1', // HTTP
      url: siteUrl,
      friendly_name: `Raspucat: ${siteUrl}`,
    });

    const resp = await fetch('https://api.uptimerobot.com/v2/newMonitor', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData.toString(),
    });

    const json = await resp.json();

    if (json.stat !== 'ok') {
      console.error('UptimeRobot newMonitor error:', JSON.stringify(json));
      return new Response(JSON.stringify({ error: 'UptimeRobot monitor creation failed.', detail: json }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const monitorId = String(json.monitor.id);

    await supabase
      .from('quotes')
      .update({ uptimerobot_monitor_id: monitorId, uptime_status: 'unknown' })
      .eq('id', quoteId);

    return new Response(JSON.stringify({ monitor_id: monitorId }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('admin-create-monitor error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
