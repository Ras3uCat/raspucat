-- Feature 024: Discovery Form → Auto-Populate client.json
-- Adds discovery form data storage to quotes.

ALTER TABLE public.quotes
  ADD COLUMN discovery_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN discovery_submitted_at timestamptz;

-- rollback: ALTER TABLE public.quotes DROP COLUMN discovery_data, DROP COLUMN discovery_submitted_at;
