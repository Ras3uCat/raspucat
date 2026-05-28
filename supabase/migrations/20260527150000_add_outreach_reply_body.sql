-- Migration: add reply body columns to outreach_emails
-- Captured by the Cloudflare Email Worker when a prospect replies to an outreach email.

ALTER TABLE public.outreach_emails
  ADD COLUMN IF NOT EXISTS reply_body text,
  ADD COLUMN IF NOT EXISTS reply_html text,
  ADD COLUMN IF NOT EXISTS reply_from text;

-- rollback:
-- ALTER TABLE public.outreach_emails
--   DROP COLUMN IF EXISTS reply_body,
--   DROP COLUMN IF EXISTS reply_html,
--   DROP COLUMN IF EXISTS reply_from;
