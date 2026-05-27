// Edge Function: admin-manage-availability
// Protected by ADMIN_PASSWORD. Manages availability_rules and availability_blocks.
// Body: { adminToken, action, ...payload }
//
// Actions:
//   set-rules    { rules: [{ dayOfWeek, startTime, endTime }] }  — replaces all rules
//   block-time   { blockedFrom, blockedUntil, reason? }
//   unblock-time { blockId }
//   list         —  returns current rules + blocks

import { createClient } from 'jsr:@supabase/supabase-js@2';

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
    const body = await req.json();
    const { adminToken, action } = body;

    const adminPassword = Deno.env.get('ADMIN_PASSWORD');
    if (!adminPassword || adminToken !== adminPassword) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    if (action === 'list') {
      const [rulesResult, blocksResult] = await Promise.all([
        supabase.from('availability_rules').select('*').order('day_of_week').order('start_time'),
        supabase.from('availability_blocks').select('*').order('blocked_from'),
      ]);
      return json({ rules: rulesResult.data ?? [], blocks: blocksResult.data ?? [] });
    }

    if (action === 'set-rules') {
      const { rules } = body as { rules: Array<{ day_of_week: number; start_time: string; end_time: string }> };
      if (!Array.isArray(rules)) return json({ error: 'rules array required.' }, 400);

      // Replace all rules atomically
      await supabase.from('availability_rules').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      if (rules.length > 0) {
        const rows = rules.map((r) => ({
          day_of_week: r.day_of_week,
          start_time: r.start_time,
          end_time: r.end_time,
          is_active: true,
        }));
        const { error } = await supabase.from('availability_rules').insert(rows);
        if (error) {
          console.error('set-rules insert error:', error);
          return json({ error: 'Failed to save rules.' }, 500);
        }
      }
      return json({ success: true, count: rules.length });
    }

    if (action === 'block-time') {
      const { blockedFrom, blockedUntil, reason = null } = body;
      if (!blockedFrom || !blockedUntil) {
        return json({ error: 'blockedFrom and blockedUntil required.' }, 400);
      }
      const { data, error } = await supabase
        .from('availability_blocks')
        .insert({ blocked_from: blockedFrom, blocked_until: blockedUntil, reason })
        .select('id')
        .single();
      if (error) {
        console.error('block-time error:', error);
        return json({ error: 'Failed to create block.' }, 500);
      }
      return json({ success: true, blockId: data.id });
    }

    if (action === 'unblock-time') {
      const { blockId } = body;
      if (!blockId) return json({ error: 'blockId required.' }, 400);
      const { error } = await supabase.from('availability_blocks').delete().eq('id', blockId);
      if (error) {
        console.error('unblock-time error:', error);
        return json({ error: 'Failed to remove block.' }, 500);
      }
      return json({ success: true });
    }

    return json({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    console.error('admin-manage-availability error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
