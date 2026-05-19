// Edge Function: admin-list-quotes
// Returns all quotes (including pending) for the admin dashboard.
// Protected by ADMIN_PASSWORD env var.

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
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { adminToken } = await req.json();
    const adminPassword = Deno.env.get('ADMIN_PASSWORD');

    if (!adminPassword || adminToken !== adminPassword) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const { data: rows, error } = await supabase
      .from('quotes')
      .select('*, management_options(name, monthly_price, annual_price, onetime_price), plans(name)')
      .in('status', ['pending', 'deposit_paid', 'fully_paid', 'active'])
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Failed to fetch quotes:', error);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch quotes.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const allIds = (rows ?? []).map(q => q.id);

    // Batch-fetch deposit_paid timestamps
    const depositPaidIds = (rows ?? []).filter(q => q.status === 'deposit_paid').map(q => q.id);
    let depositPaidAtMap: Record<string, string> = {};
    if (depositPaidIds.length > 0) {
      const { data: dpEvents } = await supabase
        .from('quote_events')
        .select('quote_id, created_at')
        .eq('event_type', 'deposit_paid')
        .in('quote_id', depositPaidIds);
      for (const e of dpEvents ?? []) {
        depositPaidAtMap[e.quote_id] = e.created_at;
      }
    }

    // Batch-fetch pending plan change flags (any subscription_plan_changed event in last 90 days)
    const pendingPlanChangeSet = new Set<string>();
    if (allIds.length > 0) {
      const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
      const { data: planEvents } = await supabase
        .from('quote_events')
        .select('quote_id')
        .eq('event_type', 'subscription_plan_changed')
        .gte('created_at', cutoff)
        .in('quote_id', allIds);
      for (const e of planEvents ?? []) {
        pendingPlanChangeSet.add(e.quote_id);
      }
    }

    const quotes = (rows ?? []).map((row) => {
      const mgmt = row.management_options as {
        name: string;
        monthly_price: number;
        annual_price: number;
        onetime_price: number;
      } | null;
      const plan = row.plans as { name: string } | null;

      const management_option_name: string | null = mgmt?.name ?? null;
      const plan_name: string | null = plan?.name ?? null;

      let subscription_amount_cents = 0;
      if (mgmt) {
        switch (row.billing_cycle) {
          case 'monthly':
            subscription_amount_cents = mgmt.monthly_price ?? 0;
            break;
          case 'annual':
            subscription_amount_cents = mgmt.annual_price ?? 0;
            break;
          case 'onetime':
            subscription_amount_cents = mgmt.onetime_price ?? 0;
            break;
        }
      }

      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { management_options: _stripped, plans: _plan, ...flat } = row;

      return {
        ...flat,
        management_option_name,
        plan_name,
        subscription_amount_cents,
        deposit_paid_at: depositPaidAtMap[row.id] ?? null,
        has_pending_plan_change: pendingPlanChangeSet.has(row.id),
      };
    });

    return new Response(
      JSON.stringify({ quotes }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-list-quotes error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
