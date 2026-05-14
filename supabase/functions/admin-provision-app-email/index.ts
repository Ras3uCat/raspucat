// Edge Function: admin-provision-app-email
// 1. Derives a slug from the app name (lowercased, alphanumeric only, max 50 chars)
// 2. Checks app_projects.alias_email for collisions — appends numeric suffix if taken
// 3. POSTs to Cloudflare Email Routing API to create a forwarding rule
// 4. Writes alias_email, cloudflare_routing_rule_id, email_provisioned_at to app_projects
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

function deriveSlug(name: string): string {
  return name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]/g, '')
    .slice(0, 50);
}

async function resolveUniqueSlug(baseSlug: string, excludeProjectId?: string): Promise<string> {
  let candidate = baseSlug;
  let suffix = 2;

  while (true) {
    const expectedEmail = `${candidate}@raspucat.com`;

    const emailQuery = supabase.from('app_projects').select('id').eq('alias_email', expectedEmail);
    if (excludeProjectId) emailQuery.neq('id', excludeProjectId);
    const { data: emailRow } = await emailQuery.maybeSingle();

    const slugQuery = supabase.from('app_projects').select('id').eq('slug', candidate);
    if (excludeProjectId) slugQuery.neq('id', excludeProjectId);
    const { data: slugRow } = await slugQuery.maybeSingle();

    if (!emailRow && !slugRow) return candidate;

    candidate = `${baseSlug}${suffix}`;
    suffix++;
  }
}

async function fetchExistingCloudflareRuleId(slug: string): Promise<string | null> {
  const zoneId = Deno.env.get('CLOUDFLARE_ZONE_ID')!;
  const token = Deno.env.get('CLOUDFLARE_API_TOKEN')!;
  const email = `${slug}@raspucat.com`;

  const resp = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/email/routing/rules`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  const json = await resp.json();
  const rules: Array<{ id: string; matchers: Array<{ value: string }> }> = json.result ?? [];
  const existing = rules.find((r) => r.matchers?.some((m) => m.value === email));
  return existing?.id ?? null;
}

async function createCloudflareRule(
  slug: string,
  appName: string,
): Promise<{ ruleId: string; email: string }> {
  const zoneId = Deno.env.get('CLOUDFLARE_ZONE_ID')!;
  const token = Deno.env.get('CLOUDFLARE_API_TOKEN')!;
  const forwardTo = Deno.env.get('CLOUDFLARE_FORWARD_TO')!;
  const email = `${slug}@raspucat.com`;

  const resp = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/email/routing/rules`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: `App: ${appName}`,
        enabled: true,
        matchers: [{ type: 'literal', field: 'to', value: email }],
        actions: [{ type: 'forward', value: [forwardTo] }],
      }),
    },
  );

  const json = await resp.json();

  if (!resp.ok || !json.result?.id) {
    // If Cloudflare rejects as duplicate, adopt the existing rule rather than failing.
    const isDuplicate = json.errors?.some((e: { code: number }) => e.code === 10044);
    if (isDuplicate) {
      const existingId = await fetchExistingCloudflareRuleId(slug);
      if (existingId) return { ruleId: existingId, email };
    }
    console.error('Cloudflare API error:', JSON.stringify(json));
    throw new Error(json.errors?.[0]?.message ?? 'Cloudflare API error');
  }

  return { ruleId: json.result.id as string, email };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { projectId, appName, slugOverride, adminToken } = await req.json();

    if (adminToken !== Deno.env.get('ADMIN_PASSWORD')) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!projectId || !appName) {
      return new Response(JSON.stringify({ error: 'projectId and appName are required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: project, error: fetchErr } = await supabase
      .from('app_projects')
      .select('id, alias_email, cloudflare_routing_rule_id, name')
      .eq('id', projectId)
      .single();

    if (fetchErr || !project) {
      return new Response(JSON.stringify({ error: 'Project not found.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (project.alias_email && project.cloudflare_routing_rule_id) {
      return new Response(
        JSON.stringify({ error: 'Email already provisioned.', alias_email: project.alias_email }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const baseSlug = slugOverride ? deriveSlug(slugOverride) : deriveSlug(appName as string);
    if (!baseSlug) {
      return new Response(
        JSON.stringify({ error: 'Could not derive a valid slug from app name.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const slug = await resolveUniqueSlug(baseSlug, projectId);
    const { ruleId, email } = await createCloudflareRule(slug, appName as string);

    const webUrl = `https://raspucat.com/${slug}`;

    const { error: updateErr } = await supabase
      .from('app_projects')
      .update({
        slug,
        alias_email: email,
        web_url: webUrl,
        cloudflare_routing_rule_id: ruleId,
        email_provisioned_at: new Date().toISOString(),
      })
      .eq('id', projectId);

    if (updateErr) {
      console.error('Failed to persist provisioned email:', updateErr);
      return new Response(
        JSON.stringify({ error: 'Cloudflare rule created but DB write failed.', email, ruleId }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ success: true, slug, alias_email: email, web_url: webUrl, rule_id: ruleId }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-provision-app-email error:', err);
    return new Response(
      JSON.stringify({ error: (err as Error).message ?? 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
