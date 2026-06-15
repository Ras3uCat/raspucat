// Edge Function: admin-lead-discovery
// Protected by ADMIN_PASSWORD (manual trigger) or CRON_SECRET (scheduled).
// Body: { adminToken?, action, industries?, cities? }
//
// Actions:
//   run                — full pipeline: Google Places + Angi + website audit + Apollo + Hunter
//   run-google         — Google Places only
//   run-angi           — Angi only
//   enrich-apollo      — Apollo enrichment for high-score leads missing decision maker
//   audit-websites     — (re)run website audit for existing leads without audit data
//   benchmark-industry — sample 15 real sites for an industry, store aggregate stats

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const GOOGLE_API_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY');
const APOLLO_API_KEY = Deno.env.get('APOLLO_API_KEY');
const HUNTER_API_KEY = Deno.env.get('HUNTER_API_KEY');

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

// ─── Types ───────────────────────────────────────────────────────────────────

type RawLead = {
  company_name: string;
  industry: string;
  city?: string;
  state?: string;
  phone?: string;
  website?: string;
  email?: string;
  google_place_id?: string;
  yelp_id?: string;
  angi_url?: string;
  rating?: number;
  review_count?: number;
  source: string;
};

type WebsiteAudit = {
  platform: string;
  hasHttps: boolean;
  hasViewport: boolean;
  hasBookingCta: boolean;
  pagespeedScore: number | null;
  painPointMatches: string[];
  lastAuditedAt: string;
};

type IndustryBenchmark = {
  sample_size: number;
  avg_pagespeed: number | null;
  pct_with_booking_cta: number;
  pct_diy_platform: number;
  pct_https: number;
  pct_mobile_viewport: number;
  sampled_at: string;
};

type IndustryProfile = {
  slug: string;
  name: string;
  pain_points: string[];
  booking_cta_keywords: string[];
  audit_signals: { seo_keywords?: string[]; red_flags?: string[]; benchmark?: IndustryBenchmark };
};

// ─── Scoring ─────────────────────────────────────────────────────────────────

function calculateScore(
  lead: { email?: string | null; phone?: string | null; website?: string | null; rating?: number | null; review_count?: number | null; sources?: string[] },
  industryProfile: IndustryProfile | null,
  websiteAudit: WebsiteAudit | null,
): number {
  let score = 0;
  const benchmark = industryProfile?.audit_signals?.benchmark;

  // Reachability (max 40)
  if (lead.email) score += 25;
  if (lead.phone) score += 15;

  // Business quality (max 15)
  if ((lead.rating ?? 0) >= 4.0) score += 10;
  if ((lead.review_count ?? 0) > 20) score += 5;

  // ICP fit (max 15)
  score += industryProfile ? 15 : 5;

  // Website opportunity — directly what we sell (max ~35)
  if (websiteAudit) {
    const matches = websiteAudit.painPointMatches.length;
    score += Math.min(matches * 5, 15);

    // DIY platform: worth more when rare in the industry (means they stand out badly)
    const isDiy = ['wix', 'squarespace', 'weebly', 'godaddy'].includes(websiteAudit.platform);
    if (isDiy) {
      score += benchmark ? (benchmark.pct_diy_platform < 0.3 ? 12 : 7) : 10;
    }

    if (!websiteAudit.hasHttps) score += 3;

    // No booking CTA: worth more when most peers have one
    if (!websiteAudit.hasBookingCta) {
      score += benchmark ? (benchmark.pct_with_booking_cta > 0.6 ? 4 : 2) : 2;
    }

    // PageSpeed: relative to benchmark avg when available
    const ps = websiteAudit.pagespeedScore;
    if (ps !== null) {
      if (benchmark?.avg_pagespeed != null) {
        if (ps < benchmark.avg_pagespeed - 10) score += 7;
        else if (ps < benchmark.avg_pagespeed) score += 3;
      } else {
        if (ps < 50) score += 7;
        else if (ps < 70) score += 3;
      }
    }
  } else if (lead.website) {
    score += 5;
  }

  // Cross-reference confidence (max 10)
  const n = lead.sources?.length ?? 0;
  if (n >= 4) score += 10;
  else if (n === 3) score += 7;
  else if (n === 2) score += 5;

  return Math.min(score, 100);
}

// ─── Deduplication ───────────────────────────────────────────────────────────

function normPhone(p: string): string {
  return p.replace(/\D/g, '').slice(-10);
}

function normDomain(url: string): string {
  return url.replace(/^https?:\/\/(www\.)?/, '').replace(/\/$/, '').toLowerCase();
}

function normName(name: string): string {
  return name.toLowerCase().replace(/\b(llc|inc|co|corp|ltd|the)\b\.?/g, '').replace(/\s+/g, ' ').trim();
}

async function findExisting(lead: RawLead): Promise<{ id: string; sources: string[]; [key: string]: unknown } | null> {
  // 1. google_place_id
  if (lead.google_place_id) {
    const { data } = await supabase.from('leads').select('*').eq('google_place_id', lead.google_place_id).single();
    if (data) return data as { id: string; sources: string[]; [key: string]: unknown };
  }
  // 2. yelp_id
  if (lead.yelp_id) {
    const { data } = await supabase.from('leads').select('*').eq('yelp_id', lead.yelp_id).single();
    if (data) return data as { id: string; sources: string[]; [key: string]: unknown };
  }
  // 3. phone — fetch only id+phone for rows in same city to keep the scan small
  if (lead.phone) {
    const norm = normPhone(lead.phone);
    if (norm.length === 10) {
      const { data: rows } = await supabase.from('leads')
        .select('id, phone, sources, company_name, industry, city, state, website, email, rating, review_count, google_place_id, yelp_id, angi_url, website_audit, score, decision_maker_name, decision_maker_title')
        .eq('city', lead.city ?? '')
        .not('phone', 'is', null);
      const match = rows?.find((r) => r.phone && normPhone(r.phone) === norm);
      if (match) return match as { id: string; sources: string[]; [key: string]: unknown };
    }
  }
  // 4. website domain — scope to city to avoid full-table scan
  if (lead.website) {
    const dom = normDomain(lead.website);
    const { data: rows } = await supabase.from('leads')
      .select('id, website, sources, company_name, industry, city, state, phone, email, rating, review_count, google_place_id, yelp_id, angi_url, website_audit, score, decision_maker_name, decision_maker_title')
      .eq('city', lead.city ?? '')
      .not('website', 'is', null);
    const match = rows?.find((r) => r.website && normDomain(r.website) === dom);
    if (match) return match as { id: string; sources: string[]; [key: string]: unknown };
  }
  // 5. name + city
  const normN = normName(lead.company_name);
  const { data: rows } = await supabase.from('leads')
    .select('id, company_name, sources, industry, city, state, phone, website, email, rating, review_count, google_place_id, yelp_id, angi_url, website_audit, score, decision_maker_name, decision_maker_title')
    .eq('city', lead.city ?? '')
    .not('company_name', 'is', null);
  const match = rows?.find((r) => r.company_name && normName(r.company_name) === normN);
  if (match) return match as { id: string; sources: string[]; [key: string]: unknown };

  return null;
}

// ─── Website Audit ────────────────────────────────────────────────────────────

const DIY_PLATFORMS: Record<string, string> = {
  'wixsite.com': 'wix',
  'wix.com': 'wix',
  'squarespace.com': 'squarespace',
  'weebly.com': 'weebly',
  'godaddysites.com': 'godaddy',
  'godaddy.com': 'godaddy',
};

const DIY_SIGNATURES: Record<string, string> = {
  'wix-code': 'wix',
  'X-Wix-': 'wix',
  'squarespace': 'squarespace',
  'weebly': 'weebly',
  'GoDaddy': 'godaddy',
};

const GENERIC_BOOKING_KEYWORDS = ['schedule', 'book', 'appointment', 'quote', 'estimate', 'contact us', 'get started'];

async function auditWebsite(
  website: string,
  industryProfile: IndustryProfile | null,
): Promise<WebsiteAudit> {
  const audit: WebsiteAudit = {
    platform: 'unknown',
    hasHttps: website.startsWith('https://'),
    hasViewport: false,
    hasBookingCta: false,
    pagespeedScore: null,
    painPointMatches: [],
    lastAuditedAt: new Date().toISOString(),
  };

  // Detect DIY platform from domain
  const domain = normDomain(website);
  for (const [pat, platform] of Object.entries(DIY_PLATFORMS)) {
    if (domain.includes(pat)) {
      audit.platform = platform;
      break;
    }
  }

  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 5000);
    const res = await fetch(website, {
      signal: controller.signal,
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; RaspucatBot/1.0)' },
    });
    clearTimeout(timer);

    if (res.ok) {
      const html = await res.text();
      const lower = html.toLowerCase();

      // Platform from HTML if not already detected
      if (audit.platform === 'unknown') {
        for (const [sig, platform] of Object.entries(DIY_SIGNATURES)) {
          if (lower.includes(sig.toLowerCase())) {
            audit.platform = platform;
            break;
          }
        }
        if (audit.platform === 'unknown' && lower.includes('wp-content')) {
          audit.platform = 'wordpress';
        }
      }

      audit.hasViewport = lower.includes('name="viewport"');

      const bookingKeywords = industryProfile?.booking_cta_keywords?.length
        ? industryProfile.booking_cta_keywords
        : GENERIC_BOOKING_KEYWORDS;
      audit.hasBookingCta = bookingKeywords.some((kw) => lower.includes(kw.toLowerCase()));
    }
  } catch {
    // Network error or timeout — use what we have from domain/https checks
  }

  // PageSpeed Insights (reuses GOOGLE_PLACES_API_KEY)
  if (GOOGLE_API_KEY) {
    try {
      const psRes = await fetch(
        `https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=${encodeURIComponent(website)}&key=${GOOGLE_API_KEY}&strategy=mobile`,
      );
      if (psRes.ok) {
        const psData = await psRes.json() as { lighthouseResult?: { categories?: { performance?: { score?: number } } } };
        const score = psData.lighthouseResult?.categories?.performance?.score;
        if (score !== undefined) audit.pagespeedScore = Math.round(score * 100);
      }
    } catch {
      // PageSpeed failure is non-fatal
    }
  }

  // Compute pain point matches
  if (industryProfile) {
    const painPoints = industryProfile.pain_points;
    if (painPoints.includes('no_booking_cta') && !audit.hasBookingCta) audit.painPointMatches.push('no_booking_cta');
    if (painPoints.includes('no_ssl') && !audit.hasHttps) audit.painPointMatches.push('no_ssl');
    if (painPoints.includes('poor_mobile') && !audit.hasViewport) audit.painPointMatches.push('poor_mobile');
    if (painPoints.includes('slow_site') && audit.pagespeedScore !== null && audit.pagespeedScore < 50) audit.painPointMatches.push('slow_site');
    if (painPoints.includes('mediocre_speed') && audit.pagespeedScore !== null && audit.pagespeedScore >= 50 && audit.pagespeedScore < 70) audit.painPointMatches.push('mediocre_speed');
    if (painPoints.includes('diy_platform') && ['wix', 'squarespace', 'weebly', 'godaddy'].includes(audit.platform)) audit.painPointMatches.push('diy_platform');
  }

  return audit;
}

// ─── Google Places ────────────────────────────────────────────────────────────

async function fetchGooglePlaces(industry: string, city: string): Promise<RawLead[]> {
  if (!GOOGLE_API_KEY) return [];
  const res = await fetch('https://places.googleapis.com/v1/places:searchText', {
    method: 'POST',
    headers: {
      'X-Goog-Api-Key': GOOGLE_API_KEY,
      'X-Goog-FieldMask': 'places.id,places.displayName,places.nationalPhoneNumber,places.websiteUri,places.formattedAddress,places.rating,places.userRatingCount',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ textQuery: `${industry} in ${city}`, maxResultCount: 20 }),
  });
  if (!res.ok) {
    console.error('Google Places error:', res.status, await res.text());
    return [];
  }
  const data = await res.json() as { places?: Array<{ id?: string; displayName?: { text?: string }; nationalPhoneNumber?: string; websiteUri?: string; formattedAddress?: string; rating?: number; userRatingCount?: number }> };
  return (data.places ?? []).map((p) => {
    const addrParts = (p.formattedAddress ?? '').split(',');
    return {
      company_name: p.displayName?.text ?? '',
      industry,
      city: addrParts[1]?.trim(),
      state: addrParts[2]?.trim()?.split(' ')[0],
      phone: p.nationalPhoneNumber,
      website: p.websiteUri,
      google_place_id: p.id,
      rating: p.rating,
      review_count: p.userRatingCount,
      source: 'google',
    };
  }).filter((l) => l.company_name);
}

// ─── Angi (best-effort scrape) ────────────────────────────────────────────────

async function fetchAngi(industry: string, city: string, state: string): Promise<RawLead[]> {
  const slug = industry.toLowerCase().replace(/\s+/g, '-');
  const citySlug = city.toLowerCase().replace(/\s+/g, '-');
  const stateSlug = state.toLowerCase();
  const url = `https://www.angi.com/companylist/us/${stateSlug}/${citySlug}/${slug}.htm`;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    const res = await fetch(url, {
      signal: controller.signal,
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; RaspucatBot/1.0)' },
    });
    clearTimeout(timer);
    if (!res.ok) return [];

    const html = await res.text();
    const leads: RawLead[] = [];
    // Extract company names from common Angi HTML patterns
    const nameMatches = html.matchAll(/data-company-name="([^"]+)"/g);
    const phoneMatches = [...html.matchAll(/\(?(\d{3})\)?[\s.\-](\d{3})[\s.\-](\d{4})/g)];
    let phoneIdx = 0;
    for (const m of nameMatches) {
      leads.push({
        company_name: m[1],
        industry,
        city,
        state,
        angi_url: url,
        phone: phoneMatches[phoneIdx] ? `(${phoneMatches[phoneIdx][1]}) ${phoneMatches[phoneIdx][2]}-${phoneMatches[phoneIdx][3]}` : undefined,
        source: 'angi',
      });
      phoneIdx++;
    }
    return leads;
  } catch {
    console.warn(`Angi scrape skipped for ${industry} in ${city} — parse error or timeout`);
    return [];
  }
}

// ─── Apollo enrichment ────────────────────────────────────────────────────────

type ApolloOrg = {
  name?: string;
  estimated_num_employees?: number;
  annual_revenue?: number;
  primary_domain?: string;
  technologies?: Array<{ name?: string; uid?: string }>;
  linkedin_url?: string;
};

const DIY_TECH_NAMES = ['wix', 'squarespace', 'weebly', 'godaddy website builder', 'godaddy'];

async function enrichWithApollo(
  leadId: string,
  website: string,
  existingAudit: WebsiteAudit | null,
): Promise<void> {
  if (!APOLLO_API_KEY) return;
  const domain = normDomain(website);
  if (!domain) return;
  try {
    const url = `https://api.apollo.io/api/v1/organizations/enrich?domain=${encodeURIComponent(domain)}`;
    const enrichRes = await fetch(url, {
      headers: {
        'Cache-Control': 'no-cache',
        'x-api-key': APOLLO_API_KEY,
      },
    });
    if (!enrichRes.ok) return;
    const data = await enrichRes.json() as { organization?: ApolloOrg };
    const org = data.organization;
    if (!org) return;

    // Detect DIY platform from Apollo tech stack
    const techNames = (org.technologies ?? []).map((t) => (t.name ?? '').toLowerCase());
    let apolloPlatform: string | null = null;
    for (const diy of DIY_TECH_NAMES) {
      if (techNames.some((t) => t.includes(diy))) {
        apolloPlatform = diy.split(' ')[0]; // 'wix', 'squarespace', etc.
        break;
      }
    }

    const updatedAudit: WebsiteAudit | null = existingAudit
      ? {
          ...existingAudit,
          platform: apolloPlatform ?? existingAudit.platform,
        }
      : null;

    const updates: Record<string, unknown> = {};
    if (updatedAudit) updates.website_audit = updatedAudit;
    if (apolloPlatform && (!existingAudit || !['wix','squarespace','weebly','godaddy'].includes(existingAudit.platform))) {
      // Recompute pain point matches if platform changed
      if (updatedAudit && !updatedAudit.painPointMatches.includes('diy_platform')) {
        updatedAudit.painPointMatches = [...updatedAudit.painPointMatches, 'diy_platform'];
        updates.website_audit = updatedAudit;
      }
    }

    if (Object.keys(updates).length > 0) {
      await supabase.from('leads').update(updates).eq('id', leadId);
    }
  } catch {
    // Apollo failure is non-fatal
  }
}

// ─── Hunter.io — decision maker lookup by domain ──────────────────────────────

async function enrichWithHunter(leadId: string, website: string): Promise<void> {
  if (!HUNTER_API_KEY) return;
  const domain = normDomain(website);
  if (!domain) return;
  try {
    const url = `https://api.hunter.io/v2/domain-search?domain=${encodeURIComponent(domain)}&limit=5&api_key=${HUNTER_API_KEY}`;
    const res = await fetch(url);
    if (!res.ok) return;
    const data = await res.json() as {
      data?: {
        emails?: Array<{ first_name?: string; last_name?: string; position?: string; type?: string }>;
      };
    };
    const emails = data.data?.emails ?? [];
    // Prefer owner/founder/president/ceo — fall back to first result
    const ownerTitles = ['owner', 'founder', 'ceo', 'president', 'principal', 'director'];
    const person = emails.find((e) =>
      ownerTitles.some((t) => (e.position ?? '').toLowerCase().includes(t))
    ) ?? emails[0];
    if (!person?.first_name) return;
    const name = [person.first_name, person.last_name].filter(Boolean).join(' ');
    await supabase.from('leads').update({
      decision_maker_name: name,
      decision_maker_title: person.position ?? null,
    }).eq('id', leadId).is('decision_maker_name', null); // don't overwrite Apollo result
  } catch {
    // Hunter failure is non-fatal
  }
}

// ─── Upsert lead ──────────────────────────────────────────────────────────────

async function upsertLead(
  raw: RawLead,
  industryProfiles: Map<string, IndustryProfile>,
): Promise<{ id: string; isNew: boolean }> {
  const existing = await findExisting(raw);

  if (existing) {
    const sources = Array.from(new Set([...(existing.sources ?? []), raw.source]));
    const merged = {
      sources,
      phone: existing.phone ?? raw.phone ?? null,
      website: existing.website ?? raw.website ?? null,
      email: existing.email ?? raw.email ?? null,
      rating: raw.rating ?? existing.rating ?? null,
      review_count: raw.review_count ?? existing.review_count ?? null,
      yelp_id: raw.yelp_id ?? existing.yelp_id ?? null,
      angi_url: raw.angi_url ?? existing.angi_url ?? null,
      google_place_id: raw.google_place_id ?? existing.google_place_id ?? null,
    };

    // Recalculate score with merged data
    const profile = findProfile(existing.industry as string, industryProfiles);
    merged.score = calculateScore({ ...existing, ...merged }, profile, existing.website_audit as WebsiteAudit | null);

    await supabase.from('leads').update(merged).eq('id', existing.id);
    return { id: existing.id as string, isNew: false };
  }

  const profile = findProfile(raw.industry, industryProfiles);
  const score = calculateScore({ ...raw, sources: [raw.source] }, profile, null);
  const { data } = await supabase.from('leads').insert({
    company_name: raw.company_name,
    industry: raw.industry,
    city: raw.city ?? null,
    state: raw.state ?? null,
    phone: raw.phone ?? null,
    website: raw.website ?? null,
    email: raw.email ?? null,
    google_place_id: raw.google_place_id ?? null,
    yelp_id: raw.yelp_id ?? null,
    angi_url: raw.angi_url ?? null,
    rating: raw.rating ?? null,
    review_count: raw.review_count ?? null,
    sources: [raw.source],
    source: raw.source,
    score,
  }).select('id').single();
  return { id: data!.id as string, isNew: true };
}

function findProfile(industry: string, profiles: Map<string, IndustryProfile>): IndustryProfile | null {
  const lower = industry.toLowerCase();
  for (const [slug, profile] of profiles) {
    if (lower.includes(slug.replace(/-/g, ' ')) || lower.includes(profile.name.toLowerCase())) {
      return profile;
    }
  }
  return null;
}

// ─── Industry Benchmarking ────────────────────────────────────────────────────

async function benchmarkIndustry(
  slug: string,
  citiesOverride?: string[],
  limit = 5,
): Promise<IndustryBenchmark> {
  const { data: profileRow } = await supabase
    .from('industry_profiles')
    .select('*')
    .eq('slug', slug)
    .single();
  if (!profileRow) throw new Error(`No industry profile for slug: ${slug}`);

  const profile = profileRow as IndustryProfile;
  const sampleCities = citiesOverride?.length
    ? citiesOverride
    : ['Austin, TX', 'Phoenix, AZ', 'Charlotte, NC'];

  // Collect up to `limit` unique website URLs from Google Places
  const websites: string[] = [];
  for (const city of sampleCities) {
    const places = await fetchGooglePlaces(profile.name, city);
    for (const p of places) {
      if (p.website && !websites.includes(p.website) && websites.length < limit) {
        websites.push(p.website);
      }
    }
    if (websites.length >= limit) break;
  }

  // Audit each site
  const audits: WebsiteAudit[] = [];
  for (const url of websites) {
    audits.push(await auditWebsite(url, profile));
  }

  const withSpeed = audits.filter((a) => a.pagespeedScore !== null);
  const benchmark: IndustryBenchmark = {
    sample_size: audits.length,
    avg_pagespeed: withSpeed.length
      ? Math.round(withSpeed.reduce((s, a) => s + a.pagespeedScore!, 0) / withSpeed.length)
      : null,
    pct_with_booking_cta: audits.length
      ? audits.filter((a) => a.hasBookingCta).length / audits.length
      : 0,
    pct_diy_platform: audits.length
      ? audits.filter((a) => ['wix', 'squarespace', 'weebly', 'godaddy'].includes(a.platform)).length / audits.length
      : 0,
    pct_https: audits.length
      ? audits.filter((a) => a.hasHttps).length / audits.length
      : 0,
    pct_mobile_viewport: audits.length
      ? audits.filter((a) => a.hasViewport).length / audits.length
      : 0,
    sampled_at: new Date().toISOString().slice(0, 10),
  };

  // Persist back to audit_signals
  const existingSignals = (profile.audit_signals ?? {}) as Record<string, unknown>;
  await supabase.from('industry_profiles').update({
    audit_signals: { ...existingSignals, benchmark },
    updated_at: new Date().toISOString(),
  }).eq('slug', slug);

  return benchmark;
}

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json();
    const { action } = body;

    // Auth: adminToken (manual) or CRON_SECRET (scheduled)
    const adminPassword = Deno.env.get('ADMIN_PASSWORD');
    const cronSecret = Deno.env.get('CRON_SECRET');
    const authHeader = req.headers.get('Authorization');
    const isCron = cronSecret && authHeader === `Bearer ${cronSecret}`;
    const isAdmin = adminPassword && body.adminToken === adminPassword;
    if (!isCron && !isAdmin) return json({ error: 'Unauthorized.' }, 401);

    // Load all industry profiles for scoring
    const { data: profileRows } = await supabase
      .from('industry_profiles')
      .select('slug, name, pain_points, booking_cta_keywords, audit_signals');
    const industryProfiles = new Map<string, IndustryProfile>();
    for (const p of profileRows ?? []) industryProfiles.set(p.slug, p as IndustryProfile);

    // Load settings if industries/cities not supplied
    let { industries, cities } = body as { industries?: string[]; cities?: string[] };
    if (!industries?.length || !cities?.length) {
      const { data: settings } = await supabase.from('outreach_settings').select('*').limit(1).single();
      industries = industries?.length ? industries : (settings?.target_industries ?? []);
      cities = cities?.length ? cities : (settings?.target_cities ?? []);
    }

    if (action === 'enrich-apollo') {
      const { data: leads } = await supabase
        .from('leads')
        .select('id, website, website_audit, score')
        .not('website', 'is', null)
        .gte('score', 60)
        .order('score', { ascending: false })
        .limit(50);

      let enriched = 0;
      for (const lead of leads ?? []) {
        if (lead.website) {
          await enrichWithApollo(lead.id, lead.website, lead.website_audit as WebsiteAudit | null);
          await enrichWithHunter(lead.id, lead.website);
          enriched++;
        }
      }
      return json({ enriched });
    }

    if (action === 'benchmark-industry') {
      const { slug, cities, limit } = body as { slug?: string; cities?: string[]; limit?: number };
      if (!slug) return json({ error: 'slug is required.' }, 400);
      const benchmark = await benchmarkIndustry(slug, cities, limit ?? 5);
      return json({ slug, benchmark });
    }

    if (action === 'audit-websites') {
      const { data: leads } = await supabase
        .from('leads')
        .select('id, website, industry')
        .not('website', 'is', null)
        .is('website_audit', null)
        .limit(50);

      let audited = 0;
      for (const lead of leads ?? []) {
        const profile = findProfile(lead.industry, industryProfiles);
        const audit = await auditWebsite(lead.website, profile);
        const { data: full } = await supabase.from('leads').select('*').eq('id', lead.id).single();
        if (full) {
          const score = calculateScore(
            { ...full, sources: full.sources ?? [] },
            profile,
            audit,
          );
          await supabase.from('leads').update({ website_audit: audit, score }).eq('id', lead.id);
          audited++;
        }
      }
      return json({ audited });
    }

    // Determine which sources to run
    const runGoogle = action === 'run' || action === 'run-google';
    const runAngi = action === 'run' || action === 'run-angi';

    if (!runGoogle && !runAngi) {
      return json({ error: `Unknown action: ${action}` }, 400);
    }

    // Respect admin panel schedule: skip if paused (= 0) or not yet due
    if (isCron) {
      const { data: cronSettings } = await supabase.from('outreach_settings').select('discovery_runs_per_week, next_discovery_run_at').limit(1).single();
      if ((cronSettings?.discovery_runs_per_week ?? 2) === 0) {
        return json({ skipped: true, reason: 'Discovery paused (runs_per_week = 0).' });
      }
      if (cronSettings?.next_discovery_run_at && new Date(cronSettings.next_discovery_run_at) > new Date()) {
        return json({ skipped: true, reason: 'Not due yet.', nextRun: cronSettings.next_discovery_run_at });
      }
    }

    if (!industries.length || !cities.length) {
      return json({ error: 'No target industries or cities configured.' }, 400);
    }

    // Reject if any configured industry has no synced profile.
    // Run /industry-download in Claude Code first to research the industry.
    const missingProfiles = industries.filter((ind: string) => {
      const slug = ind.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
      return !industryProfiles.has(slug);
    });
    if (missingProfiles.length > 0) {
      return json({
        error: `No industry profile for: ${missingProfiles.join(', ')}. Run /industry-download in Claude Code first.`,
      }, 400);
    }

    let inserted = 0;
    let updated = 0;
    const upsertedIds: string[] = [];

    for (const industry of industries) {
      for (const city of cities) {
        const [cityName, stateAbbr = ''] = city.split(',').map((s: string) => s.trim());
        const batch: RawLead[] = [];

        if (runGoogle) batch.push(...await fetchGooglePlaces(industry, city));
        if (runAngi && stateAbbr) batch.push(...await fetchAngi(industry, cityName, stateAbbr));

        for (const raw of batch) {
          const { id, isNew } = await upsertLead(raw, industryProfiles);
          upsertedIds.push(id);
          if (isNew) inserted++; else updated++;
        }
      }
    }

    // Audit up to 5 new leads per run to stay within memory limits.
    // The cron's audit-websites action handles the remainder on subsequent runs.
    let audited = 0;
    const { data: toAudit } = await supabase
      .from('leads')
      .select('id, website, industry, email, phone, rating, review_count, sources')
      .in('id', upsertedIds)
      .not('website', 'is', null)
      .limit(5);

    for (const lead of toAudit ?? []) {
      const profile = findProfile(lead.industry, industryProfiles);
      const audit = await auditWebsite(lead.website, profile);
      const score = calculateScore(
        { email: lead.email, phone: lead.phone, website: lead.website, rating: lead.rating, review_count: lead.review_count, sources: lead.sources ?? [] },
        profile,
        audit,
      );
      await supabase.from('leads').update({ website_audit: audit, score }).eq('id', lead.id);
      audited++;
    }

    // Skip inline Apollo/Hunter enrichment — the audit-websites + enrich-apollo
    // actions handle this in separate passes to avoid memory limits.

    // Update settings
    const now = new Date().toISOString();
    const { data: settings } = await supabase.from('outreach_settings').select('*').limit(1).single();
    const runsPerWeek = settings?.discovery_runs_per_week ?? 2;
    const daysUntilNext = runsPerWeek > 0 ? Math.round(7 / runsPerWeek) : 7;
    const nextRun = new Date(Date.now() + daysUntilNext * 24 * 60 * 60 * 1000).toISOString();

    if (settings?.id) {
      await supabase.from('outreach_settings').update({
        last_discovery_at: now,
        last_discovery_count: inserted,
        next_discovery_run_at: nextRun,
      }).eq('id', settings.id);
    }

    return json({ inserted, updated, audited, total: upsertedIds.length });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error('admin-lead-discovery error:', msg);
    return json({ error: msg }, 500);
  }
});
