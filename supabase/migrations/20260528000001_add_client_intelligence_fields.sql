-- Add client intelligence fields to quotes for feature 032 (Unified Client Intelligence).
-- Supports both acquisition paths: outreach-converted leads and direct website signups.

ALTER TABLE public.quotes
  ADD COLUMN IF NOT EXISTS outreach_lead_id  uuid REFERENCES public.leads(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS business_website  text,
  ADD COLUMN IF NOT EXISTS business_type     text,
  ADD COLUMN IF NOT EXISTS industry          text,
  ADD COLUMN IF NOT EXISTS pain_points       text[],
  ADD COLUMN IF NOT EXISTS website_audit     jsonb,
  ADD COLUMN IF NOT EXISTS decision_maker_name  text,
  ADD COLUMN IF NOT EXISTS decision_maker_title text,
  ADD COLUMN IF NOT EXISTS discovery_prefill jsonb,
  ADD COLUMN IF NOT EXISTS discovery_changes jsonb,
  ADD COLUMN IF NOT EXISTS reports_status    jsonb,
  ADD COLUMN IF NOT EXISTS stripe_checkout_url text;

-- Expand portal_stage to include the new awaiting_deposit stage (before awaiting_discovery).
ALTER TABLE public.quotes DROP CONSTRAINT IF EXISTS quotes_portal_stage_check;

ALTER TABLE public.quotes ADD CONSTRAINT quotes_portal_stage_check
  CHECK (portal_stage IN ('awaiting_deposit', 'awaiting_discovery', 'transmitting', 'compiling', 'deployed'));

-- rollback:
-- ALTER TABLE public.quotes DROP CONSTRAINT IF EXISTS quotes_portal_stage_check;
-- ALTER TABLE public.quotes ADD CONSTRAINT quotes_portal_stage_check
--   CHECK (portal_stage IN ('awaiting_discovery', 'transmitting', 'compiling', 'deployed'));
-- ALTER TABLE public.quotes
--   DROP COLUMN IF EXISTS stripe_checkout_url,
--   DROP COLUMN IF EXISTS outreach_lead_id,
--   DROP COLUMN IF EXISTS business_website,
--   DROP COLUMN IF EXISTS business_type,
--   DROP COLUMN IF EXISTS industry,
--   DROP COLUMN IF EXISTS pain_points,
--   DROP COLUMN IF EXISTS website_audit,
--   DROP COLUMN IF EXISTS decision_maker_name,
--   DROP COLUMN IF EXISTS decision_maker_title,
--   DROP COLUMN IF EXISTS discovery_prefill,
--   DROP COLUMN IF EXISTS discovery_changes,
--   DROP COLUMN IF EXISTS reports_status;
