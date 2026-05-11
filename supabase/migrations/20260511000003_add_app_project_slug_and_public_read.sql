ALTER TABLE public.app_projects
  ADD COLUMN IF NOT EXISTS slug text UNIQUE;

-- Auto-set web_url from slug when slug is written (belt-and-suspenders alongside the Edge Function)
-- Public landing pages need to read name + status + description by slug — no sensitive data exposed.
CREATE POLICY "public_read" ON public.app_projects
  FOR SELECT USING (true);

-- rollback:
-- DROP POLICY IF EXISTS "public_read" ON public.app_projects;
-- ALTER TABLE public.app_projects DROP COLUMN IF EXISTS slug;
