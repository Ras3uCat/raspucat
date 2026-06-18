-- Disambiguate pre-call draft from post-call confirmed plan
-- custom_plan_draft_md = internal estimate from prepare-lead (never sent)
-- custom_plan_md       = confirmed plan from prepare-reply (feeds closer-deck)
-- proposal_html        = full written scope of work from prepare-reply

ALTER TABLE public.leads
  RENAME COLUMN custom_plan_md TO custom_plan_draft_md;

ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS custom_plan_md TEXT,
  ADD COLUMN IF NOT EXISTS proposal_html TEXT;

-- rollback:
-- ALTER TABLE public.leads DROP COLUMN IF EXISTS custom_plan_md;
-- ALTER TABLE public.leads DROP COLUMN IF EXISTS proposal_html;
-- ALTER TABLE public.leads RENAME COLUMN custom_plan_draft_md TO custom_plan_md;
