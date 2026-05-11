ALTER TABLE public.app_projects
  ADD COLUMN IF NOT EXISTS cloudflare_routing_rule_id text,
  ADD COLUMN IF NOT EXISTS email_provisioned_at        timestamptz;

-- rollback:
-- ALTER TABLE public.app_projects
--   DROP COLUMN IF EXISTS cloudflare_routing_rule_id,
--   DROP COLUMN IF EXISTS email_provisioned_at;
