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
      WHERE uptimerobot_monitor_id IS NOT NULL
    )
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_public_stats() TO anon;

-- rollback: DROP FUNCTION public.get_public_stats();
