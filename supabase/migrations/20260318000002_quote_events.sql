-- ============================================================
-- Migration: 20260318000002_quote_events.sql
-- Activity log for per-quote lifecycle events
-- ============================================================

create table if not exists public.quote_events (
  id         uuid primary key default gen_random_uuid(),
  quote_id   uuid not null references public.quotes(id) on delete cascade,
  event_type text not null,
  metadata   jsonb,
  created_at timestamptz not null default now()
);

-- Required for per-quote log queries
create index on public.quote_events (quote_id);

-- --------------------------------------------------------
-- RLS — Edge Functions use service role (bypasses RLS)
-- --------------------------------------------------------
alter table public.quote_events enable row level security;

create policy "No public access to quote_events"
  on public.quote_events for all using (false);
