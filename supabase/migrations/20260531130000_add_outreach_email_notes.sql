ALTER TABLE public.outreach_emails ADD COLUMN IF NOT EXISTS notes text;
-- rollback: ALTER TABLE public.outreach_emails DROP COLUMN IF EXISTS notes;
