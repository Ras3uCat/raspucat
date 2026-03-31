-- ============================================================
-- Migration: 20260323000001_cancellation_handoff.sql
-- Cancellation handoff — adds columns to quotes for tracking
-- the cancellation flow and handoff package delivery.
-- ============================================================

alter table public.quotes
  add column if not exists cancelled_at           timestamptz,
  add column if not exists delivery_email         text,
  add column if not exists handoff_fee_cents       int default 0,
  add column if not exists handoff_invoice_id      text,
  add column if not exists handoff_package_ready   boolean default false,
  add column if not exists subscription_cancel_at  timestamptz;
-- subscription_cancel_at: set when cancel_at_period_end=true so the portal
-- can show "Your service ends on <date>" without a Stripe API call.
