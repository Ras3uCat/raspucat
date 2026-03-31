-- Migration: 20260322000002_template_version.sql
-- Adds template version tracking to quotes and a general app_settings table.

ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS template_version TEXT,
  ADD COLUMN IF NOT EXISTS template_delivered_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS app_settings (
  key   TEXT PRIMARY KEY,
  value TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO app_settings (key, value)
  VALUES ('current_template_version', '')
  ON CONFLICT (key) DO NOTHING;
