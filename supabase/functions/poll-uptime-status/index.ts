// Edge Function: poll-uptime-status
// Scheduled cron: calls UptimeRobot getMonitors API and updates uptime_status on quotes.
// Handles pagination so it works for any number of monitors (free tier: 50, Pro: 1000+).
// Logs downtime_start / downtime_end events to site_events on status transitions.
// Run on a schedule (e.g. every 30 min: "*/30 * * * *").

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// UptimeRobot status codes → our uptime_status values
function resolveStatus(statusCode: number): string {
  switch (statusCode) {
    case 2:  return 'up';
    case 8:  return 'degraded'; // "Seems down" — verifying from multiple locations
    case 9:  return 'down';
    case 0:  return 'unknown';  // paused
    default: return 'unknown';
  }
}

async function fetchMonitorPage(
  apiKey: string,
  offset: number,
  limit: number,
): Promise<{ monitors: Array<{ id: number; status: number }>; total: number }> {
  const resp = await fetch('https://api.uptimerobot.com/v2/getMonitors', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      api_key: apiKey,
      format: 'json',
      limit: String(limit),
      offset: String(offset),
    }).toString(),
  });

  const json = await resp.json();
  if (json.stat !== 'ok') {
    throw new Error(`UptimeRobot API error: ${JSON.stringify(json)}`);
  }

  return {
    monitors: json.monitors ?? [],
    total: json.pagination?.total ?? json.monitors?.length ?? 0,
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const apiKey = Deno.env.get('UPTIMEROBOT_API_KEY');
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'UPTIMEROBOT_API_KEY not configured.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Fetch all quotes that have a monitor ID
    const { data: quotes, error: quotesErr } = await supabase
      .from('quotes')
      .select('id, uptimerobot_monitor_id, uptime_status')
      .not('uptimerobot_monitor_id', 'is', null);

    if (quotesErr) throw quotesErr;
    if (!quotes || quotes.length === 0) {
      return new Response(JSON.stringify({ updated: 0, message: 'No monitored quotes.' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Build a lookup: monitorId (string) → quote
    const quoteByMonitorId = new Map<string, typeof quotes[0]>();
    for (const q of quotes) {
      quoteByMonitorId.set(String(q.uptimerobot_monitor_id), q);
    }

    // Paginate through all monitors (50 per page — UptimeRobot free tier max)
    const PAGE_SIZE = 50;
    let offset = 0;
    let total = Infinity;
    const allMonitors: Array<{ id: number; status: number }> = [];

    while (offset < total) {
      const page = await fetchMonitorPage(apiKey, offset, PAGE_SIZE);
      allMonitors.push(...page.monitors);
      total = page.total;
      offset += page.monitors.length;
      if (page.monitors.length === 0) break; // safety guard
    }

    const now = new Date().toISOString();
    let updated = 0;
    let eventsLogged = 0;

    for (const monitor of allMonitors) {
      const monitorId = String(monitor.id);
      const quote = quoteByMonitorId.get(monitorId);
      if (!quote) continue; // monitor exists in UptimeRobot but not in our DB — skip

      const newStatus = resolveStatus(monitor.status);
      const prevStatus = quote.uptime_status as string ?? 'unknown';

      // Always update timestamp; only write status if it changed (avoids noisy DB writes)
      await supabase
        .from('quotes')
        .update({ uptime_status: newStatus, last_uptime_check_at: now })
        .eq('id', quote.id);

      updated++;

      // Log transition events
      if (prevStatus !== newStatus) {
        let eventType: string | null = null;
        if (newStatus === 'down' && prevStatus !== 'down') eventType = 'downtime_start';
        else if (newStatus === 'up' && prevStatus === 'down') eventType = 'downtime_end';

        if (eventType) {
          await supabase.from('site_events').insert({
            quote_id: quote.id,
            event_type: eventType,
            payload: {
              monitor_id: monitorId,
              prev_status: prevStatus,
              new_status: newStatus,
              source: 'poll',
            },
          });
          eventsLogged++;
        }
      }
    }

    return new Response(
      JSON.stringify({ updated, eventsLogged, monitorsScanned: allMonitors.length }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('poll-uptime-status error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
