// Edge Function: poll-uptime-status
// Scheduled cron: pings each active site_url directly and updates uptime_status on quotes.
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

const TIMEOUT_MS = 10_000;

async function pingUrl(url: string): Promise<'up' | 'degraded' | 'down'> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    let resp = await fetch(url, {
      method: 'HEAD',
      signal: controller.signal,
      redirect: 'follow',
    });

    // Some servers don't support HEAD — fall back to GET
    if (resp.status === 405) {
      resp = await fetch(url, {
        method: 'GET',
        signal: controller.signal,
        redirect: 'follow',
      });
    }

    if (resp.status >= 200 && resp.status < 400) return 'up';
    if (resp.status >= 500) return 'down';
    return 'degraded'; // 4xx — reachable but returning client errors
  } catch {
    return 'down'; // timeout or connection refused
  } finally {
    clearTimeout(timer);
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { data: quotes, error: quotesErr } = await supabase
      .from('quotes')
      .select('id, site_url, uptime_status')
      .not('site_url', 'is', null);

    if (quotesErr) throw quotesErr;
    if (!quotes || quotes.length === 0) {
      return new Response(JSON.stringify({ updated: 0, message: 'No sites to ping.' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const now = new Date().toISOString();
    let updated = 0;
    let eventsLogged = 0;

    for (const quote of quotes) {
      const newStatus = await pingUrl(quote.site_url as string);
      const prevStatus = (quote.uptime_status as string) ?? 'unknown';

      await supabase
        .from('quotes')
        .update({ uptime_status: newStatus, last_uptime_check_at: now })
        .eq('id', quote.id);

      updated++;

      if (prevStatus !== newStatus) {
        let eventType: string | null = null;
        if (newStatus === 'down' && prevStatus !== 'down') eventType = 'downtime_start';
        else if (newStatus === 'up' && prevStatus === 'down') eventType = 'downtime_end';

        if (eventType) {
          await supabase.from('site_events').insert({
            quote_id: quote.id,
            event_type: eventType,
            payload: {
              url: quote.site_url,
              prev_status: prevStatus,
              new_status: newStatus,
              source: 'self-ping',
            },
          });
          eventsLogged++;
        }
      }
    }

    return new Response(
      JSON.stringify({ updated, eventsLogged, sitesChecked: quotes.length }),
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
