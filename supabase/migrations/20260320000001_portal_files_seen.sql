-- Migration: 20260320000001_portal_files_seen.sql
-- Adds seen_by_admin_at / seen_by_client_at to portal_files so that
-- file notification badges clear after the respective party views them.

alter table public.portal_files
  add column if not exists seen_by_admin_at  timestamptz,
  add column if not exists seen_by_client_at timestamptz;

-- Clients: allow updating seen_by_client_at (mark admin uploads as viewed)
create policy "Portal client marks files seen"
  on public.portal_files for update
  to authenticated
  using (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  )
  with check (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );
