-- ============================================================
-- Migration: 20260319000001_portal_auth.sql
-- Client Portal — auth columns on quotes + portal stage
-- ============================================================

-- ------------------------------------------------------------
-- Add user_id to quotes
-- Populated when the client first claims their magic link.
-- Nullable — quotes exist before a portal user is created.
-- ------------------------------------------------------------
alter table public.quotes
  add column if not exists user_id uuid references auth.users(id) on delete set null;

-- ------------------------------------------------------------
-- Add portal_stage to quotes
-- Manually set by admin. Defaults to 'transmitting' on deposit.
-- ------------------------------------------------------------
alter table public.quotes
  add column if not exists portal_stage text not null default 'transmitting'
    check (portal_stage in ('transmitting', 'compiling', 'deployed'));

-- ------------------------------------------------------------
-- RLS — allow portal clients to SELECT their own quote
--
-- The existing "No public access to quotes" policy (FOR ALL,
-- USING false) remains in place for INSERT/UPDATE/DELETE.
-- This new permissive SELECT policy is OR'd with it, granting
-- read access only when user_id matches the authenticated uid.
-- ------------------------------------------------------------
create policy "Portal client reads own quote"
  on public.quotes
  for select
  to authenticated
  using (user_id = auth.uid());
