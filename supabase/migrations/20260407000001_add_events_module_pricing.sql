-- ============================================================
-- Migration: 20260407000001_add_events_module_pricing.sql
-- Adds missing pricing entry for the events module
-- ============================================================

insert into public.modules (id, name, description, price, price_note, upgrade_of, sort_order)
values (
  'events',
  'Events & Ticketing',
  'Sell tickets to public events directly from your site with branded event pages and Stripe-powered checkout.',
  80000,
  null,
  null,
  18
)
on conflict (id) do nothing;
