-- Schedule recurring site health jobs.
-- Requires pg_cron + pg_net (already enabled via add_outreach_cron migration).

-- Poll UptimeRobot every 30 minutes and update uptime_status on quotes.
select cron.schedule(
  'poll-uptime-status',
  '*/30 * * * *',
  $$
  select net.http_post(
    url     := 'https://gegwqywgbgzahnftppda.supabase.co/functions/v1/poll-uptime-status',
    body    := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json')
  )
  $$
);

-- Run Lighthouse/PageSpeed audits every Sunday at 03:00 UTC.
select cron.schedule(
  'run-lighthouse-audits',
  '0 3 * * 0',
  $$
  select net.http_post(
    url     := 'https://gegwqywgbgzahnftppda.supabase.co/functions/v1/run-lighthouse-audits',
    body    := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json')
  )
  $$
);

-- rollback:
-- select cron.unschedule('poll-uptime-status');
-- select cron.unschedule('run-lighthouse-audits');
