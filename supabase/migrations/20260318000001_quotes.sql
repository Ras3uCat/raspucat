-- ============================================================
-- Migration: 20260318000001_quotes.sql
-- Stripe payment flow — quotes + webhook idempotency
-- ============================================================

-- ------------------------------------------------------------
-- QUOTES
-- Created by create-payment-intent Edge Function (status=pending).
-- Updated by stripe-webhook on payment_intent.succeeded.
-- ------------------------------------------------------------
create table if not exists public.quotes (
  id                        uuid primary key default gen_random_uuid(),
  created_at                timestamptz not null default now(),

  -- Client details (collected in Step 3)
  client_name               text not null,
  client_email              text not null,
  business_name             text not null,

  -- Configuration snapshot
  plan_id                   text not null references public.plans(id),
  module_ids                text[] not null default '{}',
  management_option_id      text references public.management_options(id),
  billing_cycle             text check (billing_cycle in ('monthly', 'annual', 'onetime')),

  -- Pricing (all USD cents)
  setup_total_cents         integer not null,
  deposit_cents             integer not null,   -- floor(setup_total / 2); full amount for handover
  balance_cents             integer not null,   -- setup_total - deposit; 0 for handover

  -- Stripe references
  stripe_customer_id        text,
  stripe_payment_intent_id  text,
  stripe_payment_method_id  text,              -- saved for off-session balance + subscription charges
  stripe_subscription_id    text,

  -- Lifecycle
  status                    text not null default 'pending'
                              check (status in ('pending', 'deposit_paid', 'fully_paid', 'cancelled')),
  subscription_started_at   timestamptz
);

-- ------------------------------------------------------------
-- WEBHOOK IDEMPOTENCY
-- Prevents duplicate processing on Stripe retry deliveries.
-- evt_id is the Stripe event ID (e.g. evt_1abc...).
-- ------------------------------------------------------------
create table if not exists public.processed_webhook_events (
  evt_id        text primary key,
  processed_at  timestamptz not null default now()
);

-- ------------------------------------------------------------
-- RLS
-- Quotes are never readable from the client.
-- All writes go through Edge Functions using the service role key.
-- ------------------------------------------------------------
alter table public.quotes                    enable row level security;
alter table public.processed_webhook_events  enable row level security;

-- Deny all direct client access — Edge Functions use service role (bypasses RLS)
create policy "No public access to quotes"
  on public.quotes for all using (false);

create policy "No public access to webhook events"
  on public.processed_webhook_events for all using (false);
