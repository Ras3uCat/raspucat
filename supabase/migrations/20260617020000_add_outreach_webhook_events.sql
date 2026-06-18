create table public.outreach_webhook_events (
  id uuid primary key default gen_random_uuid(),
  svix_id text not null unique,
  event_type text not null,
  created_at timestamptz not null default now()
);

alter table public.outreach_webhook_events enable row level security;
-- No client-facing RLS policies needed — service role only via edge function

-- rollback:
-- drop table if exists public.outreach_webhook_events;
