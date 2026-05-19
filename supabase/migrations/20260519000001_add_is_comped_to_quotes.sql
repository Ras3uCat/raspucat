-- Extend quotes.status check constraint to include 'active' (site-live gate for comped projects).
-- status is a text column with an inline check — drop and recreate to add the new value.
ALTER TABLE public.quotes DROP CONSTRAINT IF EXISTS quotes_status_check;
ALTER TABLE public.quotes ADD CONSTRAINT quotes_status_check
  CHECK (status IN ('pending', 'deposit_paid', 'fully_paid', 'cancelled', 'active'));

ALTER TABLE public.quotes
  ADD COLUMN is_comped BOOLEAN NOT NULL DEFAULT FALSE;

-- rollback: ALTER TABLE public.quotes DROP COLUMN is_comped;
-- rollback: ALTER TABLE public.quotes DROP CONSTRAINT quotes_status_check;
-- rollback: ALTER TABLE public.quotes ADD CONSTRAINT quotes_status_check CHECK (status IN ('pending', 'deposit_paid', 'fully_paid', 'cancelled'));
