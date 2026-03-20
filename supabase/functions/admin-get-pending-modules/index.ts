// Edge Function: admin-get-pending-modules
// Returns pending module data for admin panel.
//   - No quoteId  → { unacknowledged_counts, in_progress_counts }  (for badge on quote rows)
//   - With quoteId → { portal_stage, pending_modules: [...] } (for detail drawer)
//
// "Pending" = live_at IS NULL (shown until admin marks live).
// unacknowledged = acknowledged_at IS NULL AND live_at IS NULL  → gold pill
// in_progress    = acknowledged_at IS NOT NULL AND live_at IS NULL → teal pill

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

  const body = await req.json() as { adminToken: string; quoteId?: string };

  if (!ADMIN_PASSWORD || body.adminToken !== ADMIN_PASSWORD) {
    return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
      status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // ── Detail view (single quote) ────────────────────────────────────────────────
  if (body.quoteId) {
    const [{ data: pending }, { data: quote }] = await Promise.all([
      supabase
        .from('client_modules_pending')
        .select('id, module_id, purchased_at, acknowledged_at, modules(id, name, price)')
        .eq('quote_id', body.quoteId)
        .is('live_at', null)
        .order('purchased_at', { ascending: false }),
      supabase
        .from('quotes')
        .select('portal_stage')
        .eq('id', body.quoteId)
        .maybeSingle(),
    ]);

    const modules = (pending ?? []).map((p: Record<string, unknown>) => {
      const mod = p['modules'] as Record<string, unknown> | null;
      return {
        id: p['id'],
        module_id: p['module_id'],
        module_name: mod?.['name'] ?? p['module_id'],
        module_price: mod?.['price'] ?? 0,
        purchased_at: p['purchased_at'],
        acknowledged_at: p['acknowledged_at'],
      };
    });

    return new Response(JSON.stringify({
      portal_stage: (quote as Record<string, unknown> | null)?.['portal_stage'] ?? 'transmitting',
      pending_modules: modules,
    }), {
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }

  // ── List view (all quotes) ────────────────────────────────────────────────────
  const [{ data: pending }, { data: unreadMsgs }, { data: clientFiles }] = await Promise.all([
    supabase
      .from('client_modules_pending')
      .select('quote_id, acknowledged_at')
      .is('live_at', null),
    supabase
      .from('portal_messages')
      .select('quote_id')
      .eq('sender', 'client')
      .is('read_at', null),
    supabase
      .from('portal_files')
      .select('quote_id')
      .eq('uploaded_by', 'client')
      .is('seen_by_admin_at', null),
  ]);

  const unacknowledgedCounts: Record<string, number> = {};
  const inProgressCounts: Record<string, number> = {};
  const unreadMessageCounts: Record<string, number> = {};
  const newFileCounts: Record<string, number> = {};

  for (const row of pending ?? []) {
    const r = row as Record<string, unknown>;
    const qid = r['quote_id'] as string;
    if (r['acknowledged_at'] === null) {
      unacknowledgedCounts[qid] = (unacknowledgedCounts[qid] ?? 0) + 1;
    } else {
      inProgressCounts[qid] = (inProgressCounts[qid] ?? 0) + 1;
    }
  }

  for (const row of unreadMsgs ?? []) {
    const qid = (row as Record<string, unknown>)['quote_id'] as string;
    unreadMessageCounts[qid] = (unreadMessageCounts[qid] ?? 0) + 1;
  }

  for (const row of clientFiles ?? []) {
    const qid = (row as Record<string, unknown>)['quote_id'] as string;
    newFileCounts[qid] = (newFileCounts[qid] ?? 0) + 1;
  }

  return new Response(JSON.stringify({
    unacknowledged_counts: unacknowledgedCounts,
    in_progress_counts: inProgressCounts,
    unread_message_counts: unreadMessageCounts,
    new_file_counts: newFileCounts,
  }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
});
