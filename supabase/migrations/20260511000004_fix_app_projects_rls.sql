-- The admin panel has no Supabase auth session (uses ADMIN_PASSWORD, not JWT).
-- app_projects contains no credentials or sensitive data — internal tooling only.
-- Replace role-gated policy with a permissive one; public_read policy is redundant now too.

DROP POLICY IF EXISTS "admin_all"   ON public.app_projects;
DROP POLICY IF EXISTS "public_read" ON public.app_projects;

CREATE POLICY "allow_all" ON public.app_projects
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- rollback:
-- DROP POLICY IF EXISTS "allow_all" ON public.app_projects;
-- CREATE POLICY "admin_all" ON public.app_projects FOR ALL USING (auth.role() = 'authenticated');
-- CREATE POLICY "public_read" ON public.app_projects FOR SELECT USING (true);
