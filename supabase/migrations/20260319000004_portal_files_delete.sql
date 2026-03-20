-- ============================================================
-- Migration: 20260319000004_portal_files_delete.sql
-- Allow clients to delete their own uploaded files from the
-- portal_files metadata table (storage DELETE already exists).
-- ============================================================

create policy "Portal client deletes own uploads"
  on public.portal_files for delete
  to authenticated
  using (
    uploaded_by = 'client' and
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );
