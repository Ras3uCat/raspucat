import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

// Raspucat module_id → modular_project expansions
const MODULE_MAP: Record<string, { modules?: string[]; flags?: Record<string, unknown>; note?: string }> = {
  blog_gallery:       { modules: ['blog', 'gallery'] },
  booking_shop:       { modules: ['booking', 'shop'] },
  stripe_connect:     { flags: { STRIPE_MODE: 'connect_multi_staff' } },
  pwa_notifications:  { flags: { PWA_NOTIFICATIONS_ENABLED: true } },
  sms_reminders:      { flags: { SMS_ENABLED: true } },
  loyalty_referrals:  { modules: ['referrals'], flags: { LOYALTY_ENABLED: true } },
  google_reviews:     { flags: { REVIEWS_ENABLED: true } },
  native_apps:        { flags: { BUNDLE_ID: 'FILL_IN', APPLE_TEAM_ID: 'FILL_IN' } },
  // Not yet in modular_project
  ai_chatbot_lite:    { note: 'ai_chatbot_lite: not in modular_project — build separately.' },
  ai_chatbot_full:    { note: 'ai_chatbot_full: not in modular_project — build separately.' },
  pdf_invoices:       { note: 'pdf_invoices: not in modular_project — build separately.' },
  multi_location:     { note: 'multi_location: not in modular_project — build separately.' },
  custom_menu:        { note: 'custom_menu: not in modular_project — build separately.' },
  gated_content:      { note: 'gated_content: not in modular_project — build separately.' },
};

// Returns value if non-empty string, otherwise 'FILL_IN'
function fill(value: unknown): string {
  if (typeof value === 'string' && value.trim().length > 0) return value.trim();
  return 'FILL_IN';
}

// Returns value if it passes the predicate, otherwise fallback
function fillIf<T>(value: unknown, predicate: (v: unknown) => boolean, fallback: T): unknown {
  return predicate(value) ? value : fallback;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const { adminToken, quoteId } = await req.json();

  const adminPassword = Deno.env.get('ADMIN_PASSWORD');
  if (!adminPassword || adminToken !== adminPassword) {
    return json({ error: 'Unauthorized.' }, 401);
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: quote, error } = await supabase
    .from('quotes')
    .select('id, business_name, client_email, plan_id, module_ids, billing_cycle, discovery_data')
    .eq('id', quoteId)
    .single();

  if (error || !quote) return json({ error: 'Quote not found.' }, 404);

  // Derive slug: lowercase, spaces/specials → hyphens
  const slug = (quote.business_name as string)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

  const moduleIds: string[] = quote.module_ids ?? [];
  const modules: string[] = [];
  const flags: Record<string, unknown> = { STRIPE_MODE: 'standard' };
  const notes: string[] = [];

  for (const id of moduleIds) {
    const mapping = MODULE_MAP[id];
    if (!mapping) continue;
    if (mapping.modules) modules.push(...mapping.modules);
    if (mapping.flags) Object.assign(flags, mapping.flags);
    if (mapping.note) notes.push(mapping.note);
  }

  // Discovery data — merge non-empty values over FILL_IN placeholders
  const d: Record<string, unknown> = (quote.discovery_data as Record<string, unknown>) ?? {};

  const clientJson: Record<string, unknown> = {
    // ── Pre-filled from quote ─────────────────────────────────────────────────
    CLIENT_NAME:         quote.business_name,
    CLIENT_SLUG:         slug,
    CLIENT_EMAIL:        quote.client_email,
    RASPUCAT_QUOTE_ID:   quote.id,
    RASPUCAT_API:        Deno.env.get('SUPABASE_URL') ?? 'FILL_IN',
    RASPUCAT_ADMIN_TOKEN: 'FILL_IN',
    PLAN_ID:             quote.plan_id,
    BILLING_CYCLE:       quote.billing_cycle,
    STRIPE_MODE:         flags.STRIPE_MODE,
    MODULES:             modules,
    // ── Optional feature flags (from modules) ─────────────────────────────────
    ...(flags.PWA_NOTIFICATIONS_ENABLED ? { PWA_NOTIFICATIONS_ENABLED: true } : {}),
    ...(flags.SMS_ENABLED    ? { SMS_ENABLED: true }    : {}),
    ...(flags.LOYALTY_ENABLED ? { LOYALTY_ENABLED: true } : {}),
    ...(flags.REVIEWS_ENABLED ? { REVIEWS_ENABLED: true } : {}),
    ...(flags.BUNDLE_ID      ? { BUNDLE_ID: 'FILL_IN', APPLE_TEAM_ID: 'FILL_IN' } : {}),
    // ── Secrets — always FILL_IN ──────────────────────────────────────────────
    SUPABASE_URL:            'FILL_IN',
    SUPABASE_ANON_KEY:       'FILL_IN',
    SUPABASE_SERVICE_ROLE_KEY: 'FILL_IN',
    STRIPE_SECRET_KEY:       'FILL_IN',
    STRIPE_WEBHOOK_SECRET:   'FILL_IN',
    SMTP_HOST:               'FILL_IN',
    SMTP_USER:               'FILL_IN',
    SMTP_PASS:               'FILL_IN',
    // ── Branding (merged from discovery_data) ─────────────────────────────────
    PERSONALITY:   fill(d['PERSONALITY']),
    SHORT_NAME:    fill(d['SHORT_NAME']),
    LOGO_URL:      'FILL_IN',
    COLOR_PRIMARY:    fill(d['COLOR_PRIMARY']),
    COLOR_SECONDARY:  fill(d['COLOR_SECONDARY']),
    COLOR_ACCENT:     fill(d['COLOR_ACCENT']),
    COLOR_SURFACE:    fill(d['COLOR_SURFACE']),
    COLOR_ON_SURFACE: fill(d['COLOR_ON_SURFACE']),
    FONT_PRIMARY:   fill(d['FONT_PRIMARY']),
    FONT_SECONDARY: fill(d['FONT_SECONDARY']),
    // ── Layout ────────────────────────────────────────────────────────────────
    HERO_VARIANT: fill(d['HERO_VARIANT']),
    NAV_STYLE:    fill(d['NAV_STYLE']),
    // ── Site + SEO ────────────────────────────────────────────────────────────
    SITE_URL:        fill(d['SITE_URL']),
    SEO_TITLE:       fill(d['SEO_TITLE']),
    SEO_DESCRIPTION: fill(d['SEO_DESCRIPTION']),
    OG_IMAGE:        fill(d['OG_IMAGE']),
    // ── Business info ─────────────────────────────────────────────────────────
    PHONE:    fill(d['PHONE']),
    STREET:   fill(d['STREET']),
    CITY:     fill(d['CITY']),
    STATE:    fill(d['STATE']),
    ZIP:      fill(d['ZIP']),
    COUNTRY:  fill(d['COUNTRY']),
    TIMEZONE: fill(d['TIMEZONE']),
    HOURS_JSON: fillIf(d['HOURS_JSON'], (v) => v !== null && v !== undefined && v !== '', 'FILL_IN'),
  };

  if (notes.length > 0) clientJson['_NOTES'] = notes;

  return json({ clientJson: JSON.stringify(clientJson, null, 2) });
});
