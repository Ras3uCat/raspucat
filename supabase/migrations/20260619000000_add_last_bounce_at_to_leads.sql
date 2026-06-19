ALTER TABLE public.leads ADD COLUMN last_bounce_at timestamptz;

-- rollback: ALTER TABLE public.leads DROP COLUMN last_bounce_at;
