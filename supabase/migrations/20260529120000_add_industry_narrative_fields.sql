ALTER TABLE public.industry_profiles
  ADD COLUMN IF NOT EXISTS ride_along_md   text,
  ADD COLUMN IF NOT EXISTS money_map_md    text,
  ADD COLUMN IF NOT EXISTS client_locator_md text;

-- rollback:
-- ALTER TABLE public.industry_profiles
--   DROP COLUMN IF EXISTS ride_along_md,
--   DROP COLUMN IF EXISTS money_map_md,
--   DROP COLUMN IF EXISTS client_locator_md;
