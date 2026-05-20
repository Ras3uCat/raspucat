// Edge Function: admin-get-stats
// Returns KPI stats for the admin dashboard.
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

    const [activeResult, depositResult, mrrResult] = await Promise.all([
      // active_clients: count of fully_paid quotes
      supabase
        .from('quotes')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'fully_paid'),

      // pending_balance_cents: sum of balance_cents for deposit_paid quotes
      supabase
        .from('quotes')
        .select('balance_cents')
        .eq('status', 'deposit_paid'),

      // mrr: billing quotes with active subscriptions (not onetime, not comped)
      supabase
        .from('quotes')
        .select('billing_cycle, management_options(monthly_price, annual_price)')
        .not('subscription_started_at', 'is', null)
        .neq('billing_cycle', 'onetime')
        .eq('is_comped', false),
    ]);

    if (activeResult.error) {
      console.error('Failed to fetch active clients:', activeResult.error);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch stats.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    if (depositResult.error) {
      console.error('Failed to fetch deposit data:', depositResult.error);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch stats.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }
    if (mrrResult.error) {
      console.error('Failed to fetch MRR data:', mrrResult.error);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch stats.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const active_clients = activeResult.count ?? 0;

    const pending_balance_cents = (depositResult.data ?? []).reduce(
      (sum, row) => sum + (row.balance_cents as number ?? 0),
      0,
    );

    const mrr_cents = (mrrResult.data ?? []).reduce((sum, row) => {
      const mgmt = row.management_options as {
        monthly_price: number;
        annual_price: number;
      } | null;
      if (!mgmt) return sum;
      if (row.billing_cycle === 'monthly') return sum + (mgmt.monthly_price ?? 0);
      if (row.billing_cycle === 'annual') return sum + Math.round((mgmt.annual_price ?? 0) / 12);
      return sum;
    }, 0);

    return new Response(
      JSON.stringify({ active_clients, pending_balance_cents, mrr_cents }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-get-stats error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
