-- Expand portal_stage check constraint to include 'awaiting_discovery'.
-- The webhook sets this stage immediately after deposit is paid, before the
-- discovery form is submitted.

-- rollback:
-- ALTER TABLE public.quotes DROP CONSTRAINT IF EXISTS quotes_portal_stage_check;
-- ALTER TABLE public.quotes ADD CONSTRAINT quotes_portal_stage_check
--   CHECK (portal_stage IN ('transmitting', 'compiling', 'deployed'));

ALTER TABLE public.quotes DROP CONSTRAINT IF EXISTS quotes_portal_stage_check;

ALTER TABLE public.quotes ADD CONSTRAINT quotes_portal_stage_check
  CHECK (portal_stage IN ('awaiting_discovery', 'transmitting', 'compiling', 'deployed'));
