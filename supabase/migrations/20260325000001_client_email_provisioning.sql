-- 013: Client Email Provisioning (Cloudflare Email Routing)
-- Adds columns for the provisioned @raspucat.com infrastructure email per client.
-- NOTE: quotes.client_email (NOT NULL) is the client's personal account email — do NOT confuse.
-- NOTE: quotes.client_slug already exists from 20260323000002_quotes_modules_slug.sql

ALTER TABLE public.quotes
  ADD COLUMN IF NOT EXISTS provisioned_email            TEXT,
  ADD COLUMN IF NOT EXISTS cloudflare_routing_rule_id   TEXT,
  ADD COLUMN IF NOT EXISTS client_email_provisioned_at  TIMESTAMPTZ;
