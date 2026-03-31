-- ============================================================
-- Migration: 20260323000002_quotes_modules_slug.sql
-- Adds site feature tracking columns to quotes:
--   modules    — modular project feature slugs (booking, shop, newsletter, …)
--               written by admin-register-site on every deliver.sh run
--   client_slug — slugified business name, used in Supabase transfer note
--                 of the handoff email (e.g. "coffeeco@raspucat.com")
-- ============================================================

alter table public.quotes
  add column if not exists modules     text[] not null default '{}',
  add column if not exists client_slug text;
