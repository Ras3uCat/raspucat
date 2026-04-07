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
const STRIPE_MODULE_IDS = new Set(['stripe', 'booking_shop', 'stripe_connect', 'loyalty_referrals', 'events', 'gated_content']);

// Raspucat module_id → modular_project expansions
const MODULE_MAP: Record<string, { modules?: string[]; flags?: Record<string, unknown> }> = {
  blog_gallery: { modules: ['blog', 'gallery'] },
  booking_shop: { modules: ['booking', 'shop'] },
  stripe: { flags: {} },
  stripe_connect: { flags: { STRIPE_MODE: 'connect_multi_staff' } },
  pwa_notifications: { flags: { PWA_NOTIFICATIONS_ENABLED: true } },
  sms_reminders: { flags: { SMS_ENABLED: true } },
  loyalty_referrals: { modules: ['referrals', 'loyalty'], flags: { LOYALTY_ENABLED: true } },
  google_reviews: { flags: { GOOGLE_REVIEWS_ENABLED: true } },
  native_apps: { flags: { BUNDLE_ID: 'FILL_IN', APPLE_TEAM_ID: 'FILL_IN' } },
  events: { modules: ['events'] },
  ai_chatbot_lite: { flags: { CHATBOT_ENABLED: true } },
  ai_chatbot_full: { flags: { CHATBOT_ENABLED: true, CHATBOT_FULL: true } },
  pdf_invoices: { flags: { PDF_INVOICES_ENABLED: true } },
  multi_location: { modules: ['location'], flags: { MULTI_LOCATION_ENABLED: true } },
  custom_menu: { modules: ['menu'] },
  gated_content: { modules: ['courses'] },
  tip_gratuity: { flags: { TIP_ENABLED: true } },
  stats_digest: { flags: { DIGEST_ENABLED: true } },
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

// Derives HOME_SECTIONS from enabled modules list.
// Valid section IDs: hero, services, team, testimonials, gallery, faq, cta
function deriveHomeSections(modules: string[]): string {
  const parts = ['hero', 'services'];
  if (modules.includes('team')) parts.push('team');
  if (modules.includes('testimonials')) parts.push('testimonials');
  if (modules.includes('gallery')) parts.push('gallery');
  if (modules.includes('faq')) parts.push('faq');
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
  const modules: string[] = ['home', 'contact', 'auth', 'faq', 'testimonials', 'crm', 'newsletter'];
  const flags: Record<string, unknown> = { STRIPE_MODE: 'standard' };

  for (const id of moduleIds) {
    const mapping = MODULE_MAP[id];
    if (!mapping) continue;
    if (mapping.modules) modules.push(...mapping.modules);
    if (mapping.flags) Object.assign(flags, mapping.flags);
  }

  const needsStripe = moduleIds.some((id) => STRIPE_MODULE_IDS.has(id));

  // Discovery data — merge non-empty values over FILL_IN placeholders
  const d: Record<string, unknown> = (quote.discovery_data as Record<string, unknown>) ?? {};
  const bb = (d['brand_brief'] as Record<string, unknown>) ?? {};

  const clientJson: Record<string, unknown> = {
    // ── Identity ──────────────────────────────────────────────────────────────
    CLIENT_NAME: quote.business_name,
    BUSINESS_NAME: quote.business_name,
    CLIENT_SLUG: slug,
    SHORT_NAME: fill(d['SHORT_NAME']),
    // ── Modules ───────────────────────────────────────────────────────────────
    STRIPE_MODE: flags.STRIPE_MODE,
    MODULES: modules.join(','),
    _COMMENT_MODULES: 'Optional modules: booking,shop,blog,gallery,testimonials,faq,subscriptions,referrals,events,courses,menu,location',
    // ── Native app (conditional) ──────────────────────────────────────────────
    ...(flags.BUNDLE_ID ? { BUNDLE_ID: 'FILL_IN', APPLE_TEAM_ID: 'FILL_IN' } : {}),
    // ── Personality + Layout ──────────────────────────────────────────────────
    PERSONALITY: fill(d['PERSONALITY']),
    HERO_VARIANT: fill(d['HERO_VARIANT']),
    NAV_STYLE: fill(d['NAV_STYLE']),
    HOME_SECTIONS: deriveHomeSections(modules),
    // ── Colors ────────────────────────────────────────────────────────────────
    COLOR_PRIMARY: fill(d['COLOR_PRIMARY']),
    COLOR_SECONDARY: fill(d['COLOR_SECONDARY']),
    COLOR_ACCENT: fill(d['COLOR_ACCENT']),
    COLOR_SURFACE: fill(d['COLOR_SURFACE']),
    COLOR_ON_SURFACE: fill(d['COLOR_ON_SURFACE']),
    COLOR_ERROR: 'B3261E',
    // ── Fonts ─────────────────────────────────────────────────────────────────
    FONT_PRIMARY: fill(d['FONT_PRIMARY']),
    FONT_SECONDARY: fill(d['FONT_SECONDARY']),
    // ── Timezone ──────────────────────────────────────────────────────────────
    TIMEZONE: fill(d['TIMEZONE']),
    // ── Supabase secrets ──────────────────────────────────────────────────────
    SUPABASE_URL: 'FILL_IN',
    SUPABASE_ANON_KEY: 'FILL_IN',
    SUPABASE_SERVICE_ROLE_KEY: 'FILL_IN',
    // ── Stripe secrets (only when order includes a Stripe module) ─────────────
    ...(needsStripe ? {
      STRIPE_PK:         'FILL_IN',
      STRIPE_SECRET_KEY: 'FILL_IN',
      _COMMENT_WEBHOOKS: 'Leave empty until site is live. Register each endpoint in Stripe dashboard, copy the whsec_ signing secret, paste here, then run ./deliver.sh --skip-db --skip-build to push to Supabase.',
      STRIPE_WEBHOOK_SECRET:              '',
      STRIPE_SHOP_WEBHOOK_SECRET:         '',
      STRIPE_EVENTS_WEBHOOK_SECRET:       '',
      STRIPE_SUBSCRIPTION_WEBHOOK_SECRET: '',
    } : {}),
    // ── Email ─────────────────────────────────────────────────────────────────
    RESEND_KEY: 'FILL_IN',
    // ── Conditional integration credentials ───────────────────────────────────
    ...(moduleIds.some(id => ['ai_chatbot_lite', 'ai_chatbot_full'].includes(id)) ? {
      ANTHROPIC_API_KEY: 'FILL_IN',
    } : {}),
    ...(moduleIds.includes('google_reviews') ? {
      GOOGLE_PLACES_ID: 'FILL_IN',
    } : {}),
    ...(moduleIds.includes('pwa_notifications') ? {
      VAPID_PUBLIC_KEY: 'FILL_IN',
    } : {}),
    // ── Site + SEO ────────────────────────────────────────────────────────────
    SITE_URL: fill(d['SITE_URL']),
    // ── Feature flags — all present, true only when ordered ───────────────────
    GDPR_ENABLED: 'false',
    GOOGLE_AUTH_ENABLED: 'false',
    APPLE_AUTH_ENABLED: 'false',
    SMS_ENABLED: flags.SMS_ENABLED ? 'true' : 'false',
    INTAKE_ENABLED: 'false',
    LOYALTY_ENABLED: flags.LOYALTY_ENABLED ? 'true' : 'false',
    GIFT_ENABLED: 'false',
    WAITLIST_ENABLED: 'false',
    PACKAGES_ENABLED: 'false',
    REVIEWS_ENABLED: 'false',
    CLIENT_PHOTOS_ENABLED: 'false',
    RECURRING_ENABLED: 'false',
    PWA_NOTIFICATIONS_ENABLED: flags.PWA_NOTIFICATIONS_ENABLED ? 'true' : 'false',
    CHATBOT_ENABLED: flags.CHATBOT_ENABLED ? 'true' : 'false',
    CHATBOT_FULL: flags.CHATBOT_FULL ? 'true' : 'false',
    PDF_INVOICES_ENABLED: flags.PDF_INVOICES_ENABLED ? 'true' : 'false',
    MULTI_LOCATION_ENABLED: flags.MULTI_LOCATION_ENABLED ? 'true' : 'false',
    GOOGLE_REVIEWS_ENABLED: flags.GOOGLE_REVIEWS_ENABLED ? 'true' : 'false',
    TIP_ENABLED: flags.TIP_ENABLED ? 'true' : 'false',
    DIGEST_ENABLED: flags.DIGEST_ENABLED ? 'true' : 'false',
    // ── Raspucat integration ──────────────────────────────────────────────────
    _COMMENT_RASPUCAT: 'Raspucat admin integration — fill in once per client at project start.',
    RASPUCAT_QUOTE_ID: quote.id,
    RASPUCAT_API: Deno.env.get('SUPABASE_URL') ?? 'FILL_IN',
    RASPUCAT_ADMIN_TOKEN: 'FILL_IN',
    // ── Social ────────────────────────────────────────────────────────────────
    INSTAGRAM_URL: fill(d['INSTAGRAM_URL']),
    FACEBOOK_URL: fill(d['FACEBOOK_URL']),
    TIKTOK_URL: fill(d['TIKTOK_URL']),
    YOUTUBE_URL: fill(d['YOUTUBE_URL']),
    // ── SEO ───────────────────────────────────────────────────────────────────
    SEO_TITLE: fill(d['SEO_TITLE']),
    SEO_DESCRIPTION: fill(d['SEO_DESCRIPTION']),
    OG_IMAGE: (quote as Record<string, unknown>).og_image_url as string ?? fill(d['OG_IMAGE']),
    // ── Brand assets ──────────────────────────────────────────────────────────
    LOGO_URL: (quote as Record<string, unknown>).logo_url as string ?? 'FILL_IN',
    FROM_EMAIL: fill(d['FROM_EMAIL']),
    // ── Brand brief ───────────────────────────────────────────────────────────
    _COMMENT_BRAND_BRIEF: 'Brand brief fields — exported from Raspucat discovery form. Used by /inspo and brand-directives skill to influence site design and Flutter implementation.',
    BRAND_THREE_WORDS: fill(bb['three_words']),
    BRAND_CELEBRITY: fill(bb['celebrity']),
    BRAND_TARGET_CUSTOMER: fill(bb['target_customer']),
    BRAND_INSPO_URLS: (() => {
      const raw = bb['inspo_urls'];
      if (Array.isArray(raw) && raw.length > 0) return raw;
      if (typeof raw === 'string' && raw.trim().length > 0) {
        return raw.split(/[\n,]+/).map((u: string) => u.trim()).filter((u: string) => u.length > 0);
      }
      return [];
    })(),
    // ── Business info ─────────────────────────────────────────────────────────
    PHONE: fill(d['PHONE']),
    STREET: fill(d['STREET']),
    CITY: fill(d['CITY']),
    STATE: fill(d['STATE']),
    ZIP: fill(d['ZIP']),
    COUNTRY: fill(d['COUNTRY']),
    HOURS_JSON: fillIf(d['HOURS_JSON'], (v) => v !== null && v !== undefined && v !== '', 'FILL_IN'),
  };

  return json({ clientJson: JSON.stringify(clientJson, null, 2) });
});
