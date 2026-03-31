-- ============================================================
-- Migration: 20260320000003_site_url_and_deliverable_url.sql
-- Adds site_url to quotes (set by admin-register-site on deploy)
-- Adds url to portal_deliverables (for link-type deliverables)
-- ============================================================

-- quotes: client's live site URL — written by admin-register-site after deploy
alter table public.quotes
  add column if not exists site_url text;

-- portal_deliverables: optional URL for link-type deliverables (admin panel links, etc.)
alter table public.portal_deliverables
  add column if not exists url text;
