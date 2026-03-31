-- Migration: 20260322000003_site_health.sql
-- Adds site health monitoring columns to quotes and creates site_events table.
-- Note: site_url already exists (20260320000003), supabase_project_ref already exists (20260322000001).

ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS uptimerobot_monitor_id TEXT,
  ADD COLUMN IF NOT EXISTS uptime_status TEXT DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS last_uptime_check_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS lighthouse_performance INT,
  ADD COLUMN IF NOT EXISTS lighthouse_accessibility INT,
  ADD COLUMN IF NOT EXISTS lighthouse_best_practices INT,
  ADD COLUMN IF NOT EXISTS lighthouse_seo INT,
  ADD COLUMN IF NOT EXISTS lighthouse_performance_prev INT,
  ADD COLUMN IF NOT EXISTS lighthouse_accessibility_prev INT,
  ADD COLUMN IF NOT EXISTS lighthouse_best_practices_prev INT,
  ADD COLUMN IF NOT EXISTS lighthouse_seo_prev INT,
  ADD COLUMN IF NOT EXISTS last_audited_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS open_issues_count INT DEFAULT 0;

CREATE TABLE IF NOT EXISTS site_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS site_events_quote_id_idx ON site_events (quote_id, created_at DESC);
