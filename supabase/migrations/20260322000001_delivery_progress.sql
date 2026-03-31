-- Migration: 20260322000001_delivery_progress.sql
-- Adds delivery_progress checklist table and supabase_project_ref to quotes.

CREATE TABLE delivery_progress (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id   UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  step       TEXT NOT NULL,
  checked    BOOLEAN NOT NULL DEFAULT false,
  checked_at TIMESTAMPTZ,
  checked_by TEXT DEFAULT 'admin',   -- 'admin' | 'system'
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (quote_id, step)            -- enables upsert; prevents duplicates
);

ALTER TABLE quotes ADD COLUMN IF NOT EXISTS supabase_project_ref TEXT;
