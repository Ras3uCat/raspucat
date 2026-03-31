// Edge Function: admin-mark-module-deployed
// Handles two actions for the module add-on status flow:
//
//   action: 'in_progress' — called by add-module.sh after deliver.sh --skip-build succeeds.
//     Sets in_progress_at, appends moduleId to quotes.module_ids + quotes.modules.
//     Module is live in Supabase but pending QA/testing.
//
//   action: 'deployed'    — called by admin panel "Mark Live" button after QA sign-off.
//     Sets deployed_at only. quotes arrays already updated at in_progress stage.
//
// Protected by ADMIN_PASSWORD.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// moduleId → site feature slug for quotes.modules
const MODULE_SLUG_MAP: Record<string, string> = {
  newsletter: 'newsletter',
  testimonials: 'testimonials',
  faq: 'faq',
  crm: 'crm',
  referrals: 'referrals',
  gallery: 'gallery',
  blog: 'blog',
  shop: 'shop',
  booking: 'booking',
  events: 'events',
  subscriptions: 'subscriptions',
  courses: 'courses',
  gift: 'gift',
  loyalty: 'loyalty',
  reviews: 'reviews',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { quoteId, moduleId, action = 'in_progress', adminToken } = await req.json();

    if (adminToken !== Deno.env.get('ADMIN_PASSWORD')) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!quoteId || !moduleId) {
      return new Response(JSON.stringify({ error: 'quoteId and moduleId are required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action !== 'in_progress' && action !== 'deployed') {
      return new Response(JSON.stringify({ error: "action must be 'in_progress' or 'deployed'." }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const now = new Date().toISOString();

    if (action === 'in_progress') {
      // Set in_progress_at on the pending module row
      await supabase
        .from('client_modules_pending')
        .update({ in_progress_at: now })
        .eq('quote_id', quoteId)
        .eq('module_id', moduleId)
        .is('in_progress_at', null);

      // Fetch current quote arrays
      const { data: quote } = await supabase
        .from('quotes')
        .select('module_ids, modules')
        .eq('id', quoteId)
        .single();

      if (quote) {
        const currentIds = (quote.module_ids as string[]) ?? [];
        if (!currentIds.includes(moduleId)) {
          await supabase
            .from('quotes')
            .update({ module_ids: [...currentIds, moduleId] })
            .eq('id', quoteId);
        }

        const slug = MODULE_SLUG_MAP[moduleId] ?? moduleId;
        const currentModules = (quote.modules as string[]) ?? [];
        if (!currentModules.includes(slug)) {
          await supabase
            .from('quotes')
            .update({ modules: [...currentModules, slug] })
            .eq('id', quoteId);
        }
      }

      console.log(`admin-mark-module-deployed: ${moduleId} in_progress for quote ${quoteId}`);
      return new Response(
        JSON.stringify({ success: true, action: 'in_progress', inProgressAt: now }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // action === 'deployed' — QA sign-off
    await supabase
      .from('client_modules_pending')
      .update({ deployed_at: now })
      .eq('quote_id', quoteId)
      .eq('module_id', moduleId)
      .is('deployed_at', null);

    console.log(`admin-mark-module-deployed: ${moduleId} deployed for quote ${quoteId}`);
    return new Response(
      JSON.stringify({ success: true, action: 'deployed', deployedAt: now }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-mark-module-deployed error:', err);
    return new Response(JSON.stringify({ error: (err as Error).message ?? 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
