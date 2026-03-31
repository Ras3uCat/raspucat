-- Track when a quote's subscription was automatically activated via webhook.
-- Separate from subscription_started_at (which may be set by the admin button fallback).
-- activated_at = null means auto-activation hasn't fired yet (admin button still visible).
alter table quotes add column if not exists activated_at timestamptz;
