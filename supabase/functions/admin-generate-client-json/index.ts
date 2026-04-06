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

// Module IDs that require Stripe credentials
const STRIPE_MODULE_IDS = new Set(['booking_shop', 'stripe_connect', 'loyalty_referrals']);

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

// Derives HOME_SECTIONS from enabled modules list
function deriveHomeSections(modules: string[]): string {
  const parts = ['hero', 'services'];
  if (modules.includes('team')) parts.push('team');
  if (modules.includes('testimonials')) parts.push('testimonials');
  if (modules.includes('menu') || modules.includes('shop')) parts.push('menu');
  parts.push('cta');
  return parts.join(',');
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
    .select('id, business_name, client_email, plan_id, module_ids, billing_cycle, discovery_data, logo_url, og_image_url')
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

  const needsStripe = moduleIds.some((id) => STRIPE_MODULE_IDS.has(id));

  // Discovery data — merge non-empty values over FILL_IN placeholders
  const d: Record<string, unknown> = (quote.discovery_data as Record<string, unknown>) ?? {};
  const bb = (d['brand_brief'] as Record<string, unknown>) ?? {};

  const clientJson: Record<string, unknown> = {
    // ── Identity ──────────────────────────────────────────────────────────────
    CLIENT_NAME:   quote.business_name,
    BUSINESS_NAME: quote.business_name,
    CLIENT_SLUG:   slug,
    SHORT_NAME:    fill(d['SHORT_NAME']),
    // ── Modules ───────────────────────────────────────────────────────────────
    STRIPE_MODE: flags.STRIPE_MODE,
    MODULES:     modules.join(','),
    _COMMENT_MODULES: 'Optional modules: blog,gallery,testimonials,faq,subscriptions,referrals,shop',
    // ── Native app (conditional) ──────────────────────────────────────────────
    ...(flags.BUNDLE_ID ? { BUNDLE_ID: 'FILL_IN', APPLE_TEAM_ID: 'FILL_IN' } : {}),
    // ── Personality + Layout ──────────────────────────────────────────────────
    PERSONALITY:    fill(d['PERSONALITY']),
    HERO_VARIANT:   fill(d['HERO_VARIANT']),
    NAV_STYLE:      fill(d['NAV_STYLE']),
    HOME_SECTIONS:  deriveHomeSections(modules),
    // ── Colors ────────────────────────────────────────────────────────────────
    COLOR_PRIMARY:    fill(d['COLOR_PRIMARY']),
    COLOR_SECONDARY:  fill(d['COLOR_SECONDARY']),
    COLOR_ACCENT:     fill(d['COLOR_ACCENT']),
    COLOR_SURFACE:    fill(d['COLOR_SURFACE']),
    COLOR_ON_SURFACE: fill(d['COLOR_ON_SURFACE']),
    COLOR_ERROR:      'B3261E',
    // ── Fonts ─────────────────────────────────────────────────────────────────
    FONT_PRIMARY:   fill(d['FONT_PRIMARY']),
    FONT_SECONDARY: fill(d['FONT_SECONDARY']),
    // ── Timezone ──────────────────────────────────────────────────────────────
    TIMEZONE: fill(d['TIMEZONE']),
    // ── Supabase secrets ──────────────────────────────────────────────────────
    SUPABASE_URL:              'FILL_IN',
    SUPABASE_ANON_KEY:         'FILL_IN',
    SUPABASE_SERVICE_ROLE_KEY: 'FILL_IN',
    // ── Stripe secrets (only when order includes a Stripe module) ─────────────
    ...(needsStripe ? {
      STRIPE_PK:                    'FILL_IN',
      STRIPE_SECRET_KEY:            'FILL_IN',
      STRIPE_SHOP_WEBHOOK_SECRET:   'FILL_IN',
      STRIPE_EVENTS_WEBHOOK_SECRET: 'FILL_IN',
    } : {}),
    // ── Email ─────────────────────────────────────────────────────────────────
    RESEND_KEY: 'FILL_IN',
    // ── Site + SEO ────────────────────────────────────────────────────────────
    SITE_URL:        fill(d['SITE_URL']),
    // ── Feature flags — all present, true only when ordered ───────────────────
    GDPR_ENABLED:              'false',
    GOOGLE_AUTH_ENABLED:       'false',
    APPLE_AUTH_ENABLED:        'false',
    SMS_ENABLED:               flags.SMS_ENABLED              ? 'true' : 'false',
    INTAKE_ENABLED:            'false',
    LOYALTY_ENABLED:           flags.LOYALTY_ENABLED          ? 'true' : 'false',
    GIFT_ENABLED:              'false',
    WAITLIST_ENABLED:          'false',
    PACKAGES_ENABLED:          'false',
    REVIEWS_ENABLED:           flags.REVIEWS_ENABLED          ? 'true' : 'false',
    CLIENT_PHOTOS_ENABLED:     'false',
    RECURRING_ENABLED:         'false',
    PWA_NOTIFICATIONS_ENABLED: flags.PWA_NOTIFICATIONS_ENABLED ? 'true' : 'false',
    // ── Raspucat integration ──────────────────────────────────────────────────
    _COMMENT_RASPUCAT: 'Raspucat admin integration — fill in once per client at project start.',
    RASPUCAT_QUOTE_ID:    quote.id,
    RASPUCAT_API:         Deno.env.get('SUPABASE_URL') ?? 'FILL_IN',
    RASPUCAT_ADMIN_TOKEN: 'FILL_IN',
    // ── Social ────────────────────────────────────────────────────────────────
    INSTAGRAM_URL: fill(d['INSTAGRAM_URL']),
    FACEBOOK_URL:  fill(d['FACEBOOK_URL']),
    TIKTOK_URL:    fill(d['TIKTOK_URL']),
    YOUTUBE_URL:   fill(d['YOUTUBE_URL']),
    // ── SEO ───────────────────────────────────────────────────────────────────
    SEO_TITLE:       fill(d['SEO_TITLE']),
    SEO_DESCRIPTION: fill(d['SEO_DESCRIPTION']),
    OG_IMAGE:        (quote as Record<string, unknown>).og_image_url as string ?? fill(d['OG_IMAGE']),
    // ── Brand assets ──────────────────────────────────────────────────────────
    LOGO_URL:      (quote as Record<string, unknown>).logo_url as string ?? 'FILL_IN',
    FROM_EMAIL:    fill(d['FROM_EMAIL']),
    CLIENT_EMAIL:  quote.client_email,
    // ── Brand brief ───────────────────────────────────────────────────────────
    _COMMENT_BRAND_BRIEF: 'Brand brief fields — exported from Raspucat discovery form. Used by /inspo and brand-directives skill to influence site design and Flutter implementation.',
    BRAND_THREE_WORDS:     fill(bb['three_words']),
    BRAND_CELEBRITY:       fill(bb['celebrity']),
    BRAND_TARGET_CUSTOMER: fill(bb['target_customer']),
    BRAND_INSPO_URLS:      fillIf(bb['inspo_urls'], (v) => Array.isArray(v) && (v as unknown[]).length > 0, []),
    // ── Business info ─────────────────────────────────────────────────────────
    PHONE:    fill(d['PHONE']),
    STREET:   fill(d['STREET']),
    CITY:     fill(d['CITY']),
    STATE:    fill(d['STATE']),
    ZIP:      fill(d['ZIP']),
    COUNTRY:  fill(d['COUNTRY']),
    HOURS_JSON: fillIf(d['HOURS_JSON'], (v) => v !== null && v !== undefined && v !== '', 'FILL_IN'),
  };

  if (notes.length > 0) clientJson['_NOTES'] = notes;

  return json({ clientJson: JSON.stringify(clientJson, null, 2) });
});
