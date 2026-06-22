-- Remove UptimeRobot: replaced by direct ping crons (poll-uptime-status).
-- uptime_status and last_uptime_check_at remain — populated by direct pings.

ALTER TABLE public.quotes DROP COLUMN IF EXISTS uptimerobot_monitor_id;

CREATE OR REPLACE FUNCTION public.get_public_stats()
RETURNS json
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT json_build_object(
    'projects_deployed', (
      SELECT (
        SELECT COUNT(*) FROM public.quotes WHERE portal_stage = 'deployed'
      ) + (
        SELECT COUNT(*) FROM public.app_projects
      )
    ),
    'active_clients', (
      SELECT COUNT(*) FROM public.quotes
      WHERE status IN ('deposit_paid', 'fully_paid')
    ),
    'uptime_pct', (
      SELECT COALESCE(
        ROUND(100.0 * COUNT(*) FILTER (WHERE uptime_status = 'up')
          / NULLIF(COUNT(*), 0)),
        100
      )
      FROM public.quotes
      WHERE site_url IS NOT NULL
    )
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_public_stats() TO anon;

-- rollback: ALTER TABLE public.quotes ADD COLUMN uptimerobot_monitor_id text;
