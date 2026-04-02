-- Enable RLS on tables that were missing it (flagged by Supabase security advisor)
-- All four tables are admin-only; Edge Functions access them via service_role (bypasses RLS).
-- Direct client access is denied on all.

-- rollback:
-- ALTER TABLE public.delivery_progress DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.app_settings DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.site_events DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.promo_codes DISABLE ROW LEVEL SECURITY;
-- DROP POLICY IF EXISTS "no_direct_access" ON public.delivery_progress;
-- DROP POLICY IF EXISTS "no_direct_access" ON public.app_settings;
-- DROP POLICY IF EXISTS "no_direct_access" ON public.site_events;
-- DROP POLICY IF EXISTS "no_direct_access" ON public.promo_codes;

ALTER TABLE public.delivery_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "no_direct_access" ON public.delivery_progress
  FOR ALL TO authenticated, anon USING (false);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "no_direct_access" ON public.app_settings
  FOR ALL TO authenticated, anon USING (false);

ALTER TABLE public.site_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "no_direct_access" ON public.site_events
  FOR ALL TO authenticated, anon USING (false);

ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "no_direct_access" ON public.promo_codes
  FOR ALL TO authenticated, anon USING (false);
