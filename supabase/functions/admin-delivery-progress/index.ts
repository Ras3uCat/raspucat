// Edge Function: admin-delivery-progress
// Manages delivery checklist for a quote.
//
// Actions:
//   list   → returns all step rows for a quote
//   init   → creates all applicable rows based on quote's module_ids
//   upsert → checks/unchecks a single step; handles deliver_sh_complete specially

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

// Step definitions — must stay in sync with Flutter _steps list.
// modules: undefined = always present; string[] = substring-matched against quote.module_ids
const STEPS: Array<{ key: string; modules?: string[] }> = [
  { key: 'discovery_call_complete' },
  { key: 'email_provisioned' },
  { key: 'supabase_account_created' },
  { key: 'client_json_generated' },
  { key: 'deliver_sh_complete' },
  { key: 'stripe_webhooks_registered' },
  { key: 'jwt_hook_registered' },
  { key: 'supabase_auth_urls_set' },
  { key: 'auth_email_templates_customised' },
  { key: 'deployed_to_hosting' },
  { key: 'www_redirect_confirmed' },
  { key: 'stripe_sk_set',                   modules: ['booking'] },
  { key: 'stripe_webhook_secret_set',        modules: ['booking'] },
  { key: 'stripe_live_switchover',           modules: ['booking'] },
  { key: 'stripe_webhook_live',              modules: ['booking'] },
  { key: 'stripe_shop_webhook_secret_set',   modules: ['shop'] },
  { key: 'stripe_events_webhook_secret_set', modules: ['events'] },
  { key: 'favicon_replaced' },
  { key: 'og_image_set' },
  { key: 'master_user_created' },
  { key: 'supabase_2fa_enabled' },
  { key: 'test_data_cleared' },
  { key: 'search_console_verified' },
  { key: 'uptime_robot_active' },
  { key: 'storage_bucket_created',           modules: ['gallery'] },
  { key: 'expire_bookings_cron',             modules: ['booking'] },
  { key: 'send_reminders_cron',              modules: ['booking'] },
  { key: 'send_review_requests_cron',        modules: ['google_reviews'] },
  { key: 'smoke_test_passed' },
  { key: 'qa_booking',                       modules: ['booking'] },
  { key: 'qa_shop',                          modules: ['shop'] },
  { key: 'qa_events',                        modules: ['events'] },
  { key: 'qa_newsletter',                    modules: ['newsletter'] },
  { key: 'handover_email_sent' },
];

function applicableSteps(moduleIds: string[]): string[] {
  return STEPS
    .filter(s => !s.modules || s.modules.some(m => moduleIds.some(id => id.includes(m))))
    .map(s => s.key);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json() as Record<string, unknown>;
    const adminPassword = Deno.env.get('ADMIN_PASSWORD');

    if (!adminPassword || body.adminToken !== adminPassword) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    const quoteId = body.quoteId as string | undefined;
    if (!quoteId) return json({ error: 'quoteId is required.' }, 400);

    const action = (body.action as string) ?? 'list';

    // ── LIST ────────────────────────────────────────────────────────────────
    if (action === 'list') {
      const { data, error } = await supabase
        .from('delivery_progress')
        .select('step, checked, checked_at, checked_by, created_at')
        .eq('quote_id', quoteId)
        .order('created_at', { ascending: true });

      if (error) return json({ error: error.message }, 500);
      return json({ steps: data ?? [] });
    }

    // ── INIT ────────────────────────────────────────────────────────────────
    if (action === 'init') {
      // Fetch module_ids from the quote if not provided
      let moduleIds = (body.moduleIds as string[]) ?? [];
      if (!moduleIds.length) {
        const { data: quote } = await supabase
          .from('quotes')
          .select('module_ids')
          .eq('id', quoteId)
          .single();
        moduleIds = (quote?.module_ids as string[]) ?? [];
      }

      const steps = applicableSteps(moduleIds);
      const rows = steps.map(step => ({
        quote_id: quoteId,
        step,
        checked: false,
        checked_by: 'admin',
      }));

      // Insert all rows; ignore conflicts (idempotent)
      const { error } = await supabase
        .from('delivery_progress')
        .upsert(rows, { onConflict: 'quote_id,step', ignoreDuplicates: true });

      if (error) return json({ error: error.message }, 500);

      // Return the full step list
      const { data } = await supabase
        .from('delivery_progress')
        .select('step, checked, checked_at, checked_by, created_at')
        .eq('quote_id', quoteId)
        .order('created_at', { ascending: true });

      return json({ steps: data ?? [] });
    }

    // ── UPSERT ───────────────────────────────────────────────────────────────
    if (action === 'upsert') {
      const step = body.step as string | undefined;
      if (!step) return json({ error: 'step is required.' }, 400);

      const checked = body.checked !== false; // default true
      const isSystem = (body.checked_by as string | undefined) === 'system';
      const now = new Date().toISOString();

      await supabase
        .from('delivery_progress')
        .upsert(
          {
            quote_id: quoteId,
            step,
            checked,
            checked_at: checked ? now : null,
            checked_by: isSystem ? 'system' : 'admin',
          },
          { onConflict: 'quote_id,step' },
        );

      // deliver_sh_complete → compiling + save template_version + update global current version
      if (step === 'deliver_sh_complete' && checked) {
        const supabaseProjectRef = body.supabase_project_ref as string | undefined;
        const templateVersion = body.template_version as string | undefined;
        const updates: Record<string, unknown> = {
          portal_stage: 'compiling',
          template_delivered_at: now,
        };
        if (supabaseProjectRef) updates.supabase_project_ref = supabaseProjectRef;
        if (templateVersion) updates.template_version = templateVersion;
        await supabase.from('quotes').update(updates).eq('id', quoteId);

        // Auto-update global current_template_version — latest delivery = latest version
        if (templateVersion) {
          await supabase
            .from('app_settings')
            .upsert(
              { key: 'current_template_version', value: templateVersion, updated_at: now },
              { onConflict: 'key' },
            );
        }
      }

      // smoke_test_passed → deployed (QA done, site is live)
      if (step === 'smoke_test_passed' && checked) {
        await supabase.from('quotes').update({ portal_stage: 'deployed' }).eq('id', quoteId);
      }

      return json({ ok: true });
    }

    // ── MARK_UPDATED ─────────────────────────────────────────────────────────
    // Sets quote.template_version to the current global version (manual patch applied).
    if (action === 'mark_updated') {
      const { data: setting } = await supabase
        .from('app_settings')
        .select('value')
        .eq('key', 'current_template_version')
        .single();

      const currentVersion = setting?.value as string | undefined;
      if (!currentVersion) return json({ error: 'No current_template_version set.' }, 400);

      await supabase
        .from('quotes')
        .update({ template_version: currentVersion, template_delivered_at: new Date().toISOString() })
        .eq('id', quoteId);

      return json({ ok: true, template_version: currentVersion });
    }

    return json({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    console.error('admin-delivery-progress error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
