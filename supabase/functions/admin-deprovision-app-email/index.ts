// Edge Function: admin-deprovision-app-email
// Deletes the Cloudflare Email Routing rule for an app project and clears alias_email columns.
// Protected by ADMIN_PASSWORD or SERVICE_ROLE_KEY.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function isAuthorized(req: Request, body: Record<string, unknown>): boolean {
  const authHeader = req.headers.get('Authorization') ?? '';
  const bearer = authHeader.replace('Bearer ', '');
  return (
    bearer === Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ||
    body.adminToken === Deno.env.get('ADMIN_PASSWORD')
  );
}

async function deleteCloudflareRule(ruleId: string): Promise<void> {
  const zoneId = Deno.env.get('CLOUDFLARE_ZONE_ID')!;
  const token = Deno.env.get('CLOUDFLARE_API_TOKEN')!;

  const resp = await fetch(
    `https://api.cloudflare.com/client/v4/zones/${zoneId}/email/routing/rules/${ruleId}`,
    {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  if (!resp.ok) {
    const json = await resp.json().catch(() => ({}));
    throw new Error(json.errors?.[0]?.message ?? `Cloudflare DELETE failed: ${resp.status}`);
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json();

    if (!isAuthorized(req, body)) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { projectId } = body;
    if (!projectId) {
      return new Response(JSON.stringify({ error: 'projectId is required.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: project, error: fetchErr } = await supabase
      .from('app_projects')
      .select('id, alias_email, cloudflare_routing_rule_id')
      .eq('id', projectId)
      .single();

    if (fetchErr || !project) {
      return new Response(JSON.stringify({ error: 'Project not found.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!project.cloudflare_routing_rule_id) {
      return new Response(
        JSON.stringify({ success: true, message: 'No routing rule to deprovision.' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    await deleteCloudflareRule(project.cloudflare_routing_rule_id as string);

    await supabase
      .from('app_projects')
      .update({
        alias_email: null,
        cloudflare_routing_rule_id: null,
        email_provisioned_at: null,
      })
      .eq('id', projectId);

    console.log(`Deprovisioned email for app project ${projectId}: ${project.alias_email}`);

    return new Response(
      JSON.stringify({ success: true, deprovisioned_email: project.alias_email }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('admin-deprovision-app-email error:', err);
    return new Response(
      JSON.stringify({ error: (err as Error).message ?? 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
