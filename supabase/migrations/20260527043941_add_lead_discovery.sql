-- Additional columns on leads for multi-source enrichment
ALTER TABLE public.leads
  ADD COLUMN sources text[] NOT NULL DEFAULT '{}',
  ADD COLUMN decision_maker_name text,
  ADD COLUMN decision_maker_title text,
  ADD COLUMN yelp_id text,
  ADD COLUMN angi_url text,
  ADD COLUMN rating numeric(3,1),
  ADD COLUMN review_count int,
  ADD COLUMN website_audit jsonb;
  -- website_audit shape: { platform, hasHttps, hasViewport, hasBookingCta,
  --   pagespeedScore, painPointMatches: string[], lastAuditedAt }

CREATE INDEX leads_yelp_idx ON public.leads (yelp_id) WHERE yelp_id IS NOT NULL;

-- Industry profiles: synced from planning/industries/*.md via /industry-download skill
CREATE TABLE public.industry_profiles (
  slug text PRIMARY KEY,
  name text NOT NULL,
  pain_points text[] DEFAULT '{}',
  booking_cta_keywords text[] DEFAULT '{}',
  audit_signals jsonb DEFAULT '{}',
  researched_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.industry_profiles ENABLE ROW LEVEL SECURITY;
-- No client-facing policies needed; accessed only via service role in Edge Functions.

-- Discovery run tracking on outreach_settings
ALTER TABLE public.outreach_settings
  ADD COLUMN discovery_runs_per_week int NOT NULL DEFAULT 2,
  ADD COLUMN next_discovery_run_at timestamptz,
  ADD COLUMN last_discovery_at timestamptz,
  ADD COLUMN last_discovery_count int NOT NULL DEFAULT 0;

-- rollback:
-- ALTER TABLE public.leads DROP COLUMN IF EXISTS sources, decision_maker_name, decision_maker_title,
--   yelp_id, angi_url, rating, review_count, website_audit;
-- DROP TABLE IF EXISTS public.industry_profiles;
-- ALTER TABLE public.outreach_settings DROP COLUMN IF EXISTS discovery_runs_per_week,
--   next_discovery_run_at, last_discovery_at, last_discovery_count;
