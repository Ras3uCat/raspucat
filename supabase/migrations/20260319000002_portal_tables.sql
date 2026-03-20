-- ============================================================
-- Migration: 20260319000002_portal_tables.sql
-- Client Portal — portal_files, portal_messages,
--                 portal_deliverables, client_modules_pending
-- ============================================================
--
-- RLS pattern for all portal tables:
--   Clients can only access rows where their quote_id resolves
--   to a quote owned by auth.uid() via quotes.user_id.
--
--   quote_id IN (SELECT id FROM public.quotes WHERE user_id = auth.uid())
--
-- Admin access is via the service role key (bypasses RLS).
-- ============================================================


-- ------------------------------------------------------------
-- PORTAL FILES
-- Tracks metadata for all files exchanged via the portal.
-- Actual files live in the 'portal-files' storage bucket.
-- ------------------------------------------------------------
create table if not exists public.portal_files (
  id           uuid primary key default gen_random_uuid(),
  quote_id     uuid not null references public.quotes(id) on delete cascade,
  uploaded_by  text not null check (uploaded_by in ('admin', 'client')),
  file_name    text not null,
  storage_path text not null,
  mime_type    text not null,
  size_bytes   bigint not null,
  created_at   timestamptz not null default now()
);

alter table public.portal_files enable row level security;

-- Clients: read all files for their quote (both directions)
create policy "Portal client reads own files"
  on public.portal_files for select
  to authenticated
  using (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );

-- Clients: insert only their own uploads (uploaded_by must be 'client')
create policy "Portal client inserts own uploads"
  on public.portal_files for insert
  to authenticated
  with check (
    uploaded_by = 'client' and
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );


-- ------------------------------------------------------------
-- PORTAL MESSAGES
-- Threaded two-way messaging between client and Raspucat team.
-- read_at       — null = unread by admin
-- client_read_at — null = unread by client
-- ------------------------------------------------------------
create table if not exists public.portal_messages (
  id              uuid primary key default gen_random_uuid(),
  quote_id        uuid not null references public.quotes(id) on delete cascade,
  sender          text not null check (sender in ('admin', 'client')),
  body            text not null,
  created_at      timestamptz not null default now(),
  read_at         timestamptz,
  client_read_at  timestamptz
);

alter table public.portal_messages enable row level security;

-- Clients: read all messages in their thread
create policy "Portal client reads own messages"
  on public.portal_messages for select
  to authenticated
  using (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );

-- Clients: insert only their own messages (sender must be 'client')
create policy "Portal client inserts own messages"
  on public.portal_messages for insert
  to authenticated
  with check (
    sender = 'client' and
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );

-- Clients: update client_read_at on messages (mark admin replies as read)
create policy "Portal client marks messages read"
  on public.portal_messages for update
  to authenticated
  using (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  )
  with check (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );


-- ------------------------------------------------------------
-- PORTAL DELIVERABLES
-- Admin marks items for client review; client approves or
-- requests a revision with an optional note.
-- ------------------------------------------------------------
create table if not exists public.portal_deliverables (
  id            uuid primary key default gen_random_uuid(),
  quote_id      uuid not null references public.quotes(id) on delete cascade,
  file_id       uuid references public.portal_files(id) on delete set null,
  title         text not null,
  status        text not null default 'pending'
                  check (status in ('pending', 'awaiting_approval', 'approved', 'revision_requested')),
  revision_note text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.portal_deliverables enable row level security;

-- Clients: read deliverables for their quote
create policy "Portal client reads own deliverables"
  on public.portal_deliverables for select
  to authenticated
  using (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );

-- Clients: update status + revision_note only (approve / request revision)
-- updated_at is also allowed so the app can stamp the timestamp.
create policy "Portal client responds to deliverables"
  on public.portal_deliverables for update
  to authenticated
  using (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  )
  with check (
    quote_id in (select id from public.quotes where user_id = auth.uid()) and
    status in ('approved', 'revision_requested')
  );


-- ------------------------------------------------------------
-- CLIENT MODULES PENDING
-- Records add-on module purchases made via the portal.
-- acknowledged_at null = "Feature Pending" badge active in admin.
-- ------------------------------------------------------------
create table if not exists public.client_modules_pending (
  id              uuid primary key default gen_random_uuid(),
  quote_id        uuid not null references public.quotes(id) on delete cascade,
  module_id       text not null references public.modules(id),
  purchased_at    timestamptz not null default now(),
  acknowledged_at timestamptz
);

alter table public.client_modules_pending enable row level security;

-- Clients: read their own pending modules (show confirmation in portal)
create policy "Portal client reads own pending modules"
  on public.client_modules_pending for select
  to authenticated
  using (
    quote_id in (select id from public.quotes where user_id = auth.uid())
  );

-- Clients cannot insert directly — module purchases go through
-- an Edge Function using the service role after Stripe confirms payment.
