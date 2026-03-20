-- ============================================================
-- Migration: 20260319000003_portal_storage.sql
-- Client Portal — 'portal-files' storage bucket + RLS
-- ============================================================
--
-- Bucket layout:
--   portal-files/{quote_id}/client/   ← client uploads
--   portal-files/{quote_id}/admin/    ← admin deliverables
--
-- Admin access is via the service role key (bypasses RLS).
-- Client access is scoped strictly to their own quote_id folder.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('portal-files', 'portal-files', false)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- Clients: read all objects in their quote folder (both /client
-- and /admin subfolders — needed to download deliverables)
-- ------------------------------------------------------------
create policy "Portal client reads own folder"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'portal-files' and
    (storage.foldername(name))[1]::uuid in (
      select id from public.quotes where user_id = auth.uid()
    )
  );

-- ------------------------------------------------------------
-- Clients: upload only into their own /client subfolder
-- ------------------------------------------------------------
create policy "Portal client uploads to client subfolder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'portal-files' and
    (storage.foldername(name))[1]::uuid in (
      select id from public.quotes where user_id = auth.uid()
    ) and
    (storage.foldername(name))[2] = 'client'
  );

-- ------------------------------------------------------------
-- Clients: delete their own uploads (client subfolder only)
-- ------------------------------------------------------------
create policy "Portal client deletes own uploads"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'portal-files' and
    (storage.foldername(name))[1]::uuid in (
      select id from public.quotes where user_id = auth.uid()
    ) and
    (storage.foldername(name))[2] = 'client'
  );
