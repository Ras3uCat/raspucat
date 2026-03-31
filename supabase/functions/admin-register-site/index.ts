// Edge Function: admin-register-site
// Called by deliver.sh after deploy, or when admin manually saves site_url.
// 1. Writes site_url to the quote (idempotent)
// 2. Calls admin-create-monitor to start UptimeRobot monitoring
// 3. Auto-populates portal_deliverables based on quote modules
// 4. Auto-checks site_registered + uptime_robot_active delivery steps
// Protected by ADMIN_PASSWORD.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function callInternalFn(fnName: string, body: Record<string, unknown>): Promise<void> {
  try {
    await fetch(`${SUPABASE_URL}/functions/v1/${fnName}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
  } catch (err) {
    console.error(`admin-register-site: call to ${fnName} failed:`, err);
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { quoteId, siteUrl, clientSlug, modules: siteModules, adminToken } = await req.json();

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

    // Validate https:// format
    if (!siteUrl.startsWith('https://')) {
      return new Response(JSON.stringify({ error: 'siteUrl must start with https://' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Fetch the quote to get modules and supabase_project_ref
    const { data: quote, error: fetchErr } = await supabase
      .from('quotes')
      .select('id, site_url, supabase_project_ref, modules')
      .eq('id', quoteId)
      .single();

    if (fetchErr || !quote) {
      return new Response(JSON.stringify({ error: 'Quote not found.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Write site_url, modules, and client_slug (idempotent)
    const updatePayload: Record<string, unknown> = { site_url: siteUrl };
    if (Array.isArray(siteModules)) updatePayload.modules = siteModules;
    if (clientSlug) updatePayload.client_slug = clientSlug;
    await supabase.from('quotes').update(updatePayload).eq('id', quoteId);

    // Create UptimeRobot monitor (fire-and-forget internally but we await for the monitor_id)
    let monitorCreated = false;
    try {
      const monitorResp = await fetch(`${SUPABASE_URL}/functions/v1/admin-create-monitor`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ quoteId, siteUrl, adminToken }),
      });
      const monitorJson = await monitorResp.json();
      monitorCreated = !!monitorJson.monitor_id;
    } catch (err) {
      console.error('admin-register-site: admin-create-monitor failed:', err);
    }

    // Auto-populate portal_deliverables
    const modules: string[] = quote.modules ?? [];
    const deliverables: Array<{ quote_id: string; label: string; value: string; type: string }> = [
      { quote_id: quoteId, label: 'Live site', value: siteUrl, type: 'url' },
      { quote_id: quoteId, label: 'Admin panel', value: `${siteUrl}/auth`, type: 'url' },
    ];

    if (quote.supabase_project_ref) {
      deliverables.push({
        quote_id: quoteId,
        label: 'Supabase project',
        value: `https://supabase.com/dashboard/project/${quote.supabase_project_ref}`,
        type: 'url',
      });
    }

    if (modules.includes('booking')) {
      deliverables.push({ quote_id: quoteId, label: 'Booking admin', value: `${siteUrl}/admin/bookings`, type: 'url' });
    }
    if (modules.includes('shop')) {
      deliverables.push({ quote_id: quoteId, label: 'Shop admin', value: `${siteUrl}/admin/shop`, type: 'url' });
    }
    if (modules.includes('events')) {
      deliverables.push({ quote_id: quoteId, label: 'Events admin', value: `${siteUrl}/admin/events`, type: 'url' });
    }

    // Upsert deliverables (on conflict label + quote_id, update value)
    await supabase
      .from('portal_deliverables')
      .upsert(deliverables, { onConflict: 'quote_id,label', ignoreDuplicates: false });

    // Auto-check site_registered delivery step
    await callInternalFn('admin-delivery-progress', {
      adminToken,
      quoteId,
      action: 'upsert',
      step: 'site_registered',
      checked: true,
      checked_by: 'system',
    });

    // Auto-check uptime_robot_active if monitor was created
    if (monitorCreated) {
      await callInternalFn('admin-delivery-progress', {
        adminToken,
        quoteId,
        action: 'upsert',
        step: 'uptime_robot_active',
        checked: true,
        checked_by: 'system',
      });
    }

    return new Response(
      JSON.stringify({ success: true, monitorCreated, deliverablesAdded: deliverables.length }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-register-site error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
