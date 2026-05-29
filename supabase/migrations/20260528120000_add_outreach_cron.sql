-- Enable extensions required for cron + HTTP calls from the database
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Both cron jobs authenticate via CRON_SECRET (Bearer token).
-- Before applying this migration, insert the secret into app_settings:
--
--   INSERT INTO app_settings (key, value)
--   VALUES ('CRON_SECRET', 'your-cron-secret-here')
--   ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
--
-- The same value must be set as the CRON_SECRET env var on both
-- admin-outreach-email and admin-lead-discovery Edge Functions.

-- Auto-draft follow-up emails daily at 10:00 AM UTC
select cron.schedule(
  'outreach-auto-draft-followups',
  '0 10 * * *',
  $$
  select net.http_post(
    url     := 'https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-outreach-email',
    body    := '{"action":"auto-draft-followups"}'::jsonb,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || (select value from app_settings where key = 'CRON_SECRET')
               )
  )
  $$
);

-- Run lead discovery daily at 10:05 AM UTC (staggered after follow-up draft job)
-- Skips automatically when discovery_runs_per_week = 0.
select cron.schedule(
  'outreach-lead-discovery',
  '5 10 * * *',
  $$
  select net.http_post(
    url     := 'https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-lead-discovery',
    body    := '{"action":"run"}'::jsonb,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || (select value from app_settings where key = 'CRON_SECRET')
               )
  )
  $$
);

-- rollback:
-- select cron.unschedule('outreach-auto-draft-followups');
-- select cron.unschedule('outreach-lead-discovery');
