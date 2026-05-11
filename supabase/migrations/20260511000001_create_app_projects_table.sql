CREATE TABLE public.app_projects (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                 text NOT NULL,
  description          text,
  status               text NOT NULL DEFAULT 'development',
  tech_stack           text[] DEFAULT '{}',
  alias_email          text,
  supabase_url         text,
  repo_url             text,
  web_url              text,
  app_store_url        text,
  play_store_url       text,
  stripe_dashboard_url text,
  crash_report_url     text,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.app_projects ENABLE ROW LEVEL SECURITY;

-- Admin-only: any authenticated user (Raspucat has a single admin account)
CREATE POLICY "admin_all" ON public.app_projects
  FOR ALL USING (auth.role() = 'authenticated');

-- rollback: DROP TABLE public.app_projects;
