ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS blueprint_md        text,
  ADD COLUMN IF NOT EXISTS brand_brief_html    text,
  ADD COLUMN IF NOT EXISTS competitor_html     text,
  ADD COLUMN IF NOT EXISTS brand_alignment_html text,
  ADD COLUMN IF NOT EXISTS custom_plan_md      text;

-- rollback:
-- ALTER TABLE public.leads
--   DROP COLUMN IF EXISTS blueprint_md,
--   DROP COLUMN IF EXISTS brand_brief_html,
--   DROP COLUMN IF EXISTS competitor_html,
--   DROP COLUMN IF EXISTS brand_alignment_html,
--   DROP COLUMN IF EXISTS custom_plan_md;
