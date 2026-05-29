// Edge Function: admin-leads
// Protected by ADMIN_PASSWORD. CRUD on the leads table with score calculation.
// Body: { adminToken, action, ...payload }
//
// Actions:
//   list              { status?, limit?, offset? }
//   create            { companyName, industry, city?, state?, website?, phone?, email?, notes?, source? }
//   update            { leadId, ...fields }
//   delete            { leadId }
//   sync-industry     { slug, name, painPoints, bookingCtaKeywords, auditSignals, researchedAt }
//   list-industries   {}

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

function calculateScore(fields: {
  email?: string | null;
  website?: string | null;
  phone?: string | null;
  industry?: string | null;
  targetIndustries?: string[];
}): number {
  const { email, website, phone, industry, targetIndustries = [] } = fields;
  let score = 0;
  if (email) score += 25;
  if (website) score += 15;
  if (phone) score += 10;
  const inIcp = targetIndustries.length === 0 ||
    (industry && targetIndustries.some((t) => industry.toLowerCase().includes(t.toLowerCase())));
  score += inIcp ? 20 : 5;
  // Base score for having company info — bumped to 50 minimum for actionable leads
  return Math.min(score, 100);
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
      const { status, limit = 100, offset = 0 } = body;
      let query = supabase
        .from('leads')
        .select('*', { count: 'exact' })
        .order('score', { ascending: false })
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      if (status) query = query.eq('status', status);

      const { data, error, count } = await query;
      if (error) {
        console.error('list error:', error);
        return json({ error: 'Failed to list leads.' }, 500);
      }
      return json({ leads: data ?? [], total: count ?? 0 });
    }

    if (action === 'create') {
      const { companyName, industry, city, state, website, phone, email, notes, source } = body;
      if (!companyName || !industry) {
        return json({ error: 'companyName and industry are required.' }, 400);
      }
      const score = calculateScore({ email, website, phone, industry });
      const { data, error } = await supabase
        .from('leads')
        .insert({
          company_name: companyName,
          industry,
          city: city ?? null,
          state: state ?? null,
          website: website ?? null,
          phone: phone ?? null,
          email: email ?? null,
          notes: notes ?? null,
          source: source ?? 'manual',
          score,
        })
        .select('*')
        .single();
      if (error) {
        console.error('create error:', error);
        return json({ error: 'Failed to create lead.' }, 500);
      }
      return json({ lead: data });
    }

    if (action === 'update') {
      const { leadId, ...fields } = body;
      if (!leadId) return json({ error: 'leadId required.' }, 400);

      const { adminToken: _t, action: _a, ...rest } = fields;
      void _t; void _a;

      // Map camelCase keys to snake_case for DB
      const mapped: Record<string, unknown> = {};
      const keyMap: Record<string, string> = {
        companyName: 'company_name',
        emailSource: 'email_source',
        googlePlaceId: 'google_place_id',
        lastContactedAt: 'last_contacted_at',
        nextFollowupAt: 'next_followup_at',
      };
      for (const [k, v] of Object.entries(rest)) {
        mapped[keyMap[k] ?? k] = v;
      }

      // Recalculate score if contact fields changed
      if (mapped.email !== undefined || mapped.website !== undefined || mapped.phone !== undefined) {
        const { data: existing } = await supabase
          .from('leads')
          .select('email, website, phone, industry')
          .eq('id', leadId)
          .single();
        if (existing) {
          mapped.score = calculateScore({
            email: (mapped.email ?? existing.email) as string,
            website: (mapped.website ?? existing.website) as string,
            phone: (mapped.phone ?? existing.phone) as string,
            industry: existing.industry as string,
          });
        }
      }

      const { data, error } = await supabase
        .from('leads')
        .update(mapped)
        .eq('id', leadId)
        .select('*')
        .single();
      if (error) {
        console.error('update error:', error);
        return json({ error: 'Failed to update lead.' }, 500);
      }
      return json({ lead: data });
    }

    if (action === 'delete') {
      const { leadId } = body;
      if (!leadId) return json({ error: 'leadId required.' }, 400);
      const { error } = await supabase.from('leads').delete().eq('id', leadId);
      if (error) {
        console.error('delete error:', error);
        return json({ error: 'Failed to delete lead.' }, 500);
      }
      return json({ success: true });
    }

    if (action === 'sync-industry') {
      const { slug, name, painPoints, bookingCtaKeywords, auditSignals, researchedAt, overviewMd, rideAlongMd, moneyMapMd, clientLocatorMd } = body;
      if (!slug || !name) return json({ error: 'slug and name required.' }, 400);

      // Preserve existing benchmark if the incoming auditSignals doesn't include one
      const { data: existing } = await supabase
        .from('industry_profiles')
        .select('audit_signals')
        .eq('slug', slug)
        .single();
      const existingBenchmark = (existing?.audit_signals as Record<string, unknown> | null)?.benchmark;
      const mergedSignals = {
        ...(auditSignals ?? {}),
        ...(existingBenchmark && !(auditSignals as Record<string, unknown>)?.benchmark
          ? { benchmark: existingBenchmark }
          : {}),
      };

      const { data, error } = await supabase
        .from('industry_profiles')
        .upsert({
          slug,
          name,
          pain_points: painPoints ?? [],
          booking_cta_keywords: bookingCtaKeywords ?? [],
          audit_signals: mergedSignals,
          researched_at: researchedAt ?? new Date().toISOString(),
          updated_at: new Date().toISOString(),
          ...(overviewMd !== undefined && { overview_md: overviewMd }),
          ...(rideAlongMd !== undefined && { ride_along_md: rideAlongMd }),
          ...(moneyMapMd !== undefined && { money_map_md: moneyMapMd }),
          ...(clientLocatorMd !== undefined && { client_locator_md: clientLocatorMd }),
        }, { onConflict: 'slug' })
        .select('*')
        .single();

      if (error) {
        console.error('sync-industry error:', error);
        return json({ error: 'Failed to sync industry profile.' }, 500);
      }
      return json({ profile: data });
    }

    if (action === 'list-industries') {
      const { data, error } = await supabase
        .from('industry_profiles')
        .select('slug, name, pain_points, booking_cta_keywords, audit_signals, researched_at, overview_md, ride_along_md, money_map_md, client_locator_md')
        .order('name', { ascending: true });

      if (error) {
        console.error('list-industries error:', error);
        return json({ error: 'Failed to list industry profiles.' }, 500);
      }
      return json({ profiles: data ?? [] });
    }

    return json({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    console.error('admin-leads error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
