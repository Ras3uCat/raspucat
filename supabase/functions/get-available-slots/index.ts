// Edge Function: get-available-slots
// Public. Returns available 30-min slot start times (UTC) for a given calendar date.
// Query params: ?date=YYYY-MM-DD
// Response: { slots: string[] }  (ISO 8601 UTC strings)

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { getAvailableSlots } from '../_shared/booking-slots.ts';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const url = new URL(req.url);
    const date = url.searchParams.get('date');

    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return json({ error: 'date query param required (YYYY-MM-DD).' }, 400);
    }

    const slots = await getAvailableSlots(supabase, date);
    return json({ slots: slots.map((s) => s.toISOString()) });
  } catch (err) {
    console.error('get-available-slots error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
