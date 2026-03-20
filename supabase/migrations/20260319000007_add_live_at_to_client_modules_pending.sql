-- Add live_at to track when admin marks a client-purchased add-on as live.
-- When live_at is set, the module is inserted into quote_modules by the
-- admin-mark-module-live edge function. Pill clears from admin dashboard only
-- after live_at is set (not after acknowledged_at).

ALTER TABLE client_modules_pending
  ADD COLUMN IF NOT EXISTS live_at TIMESTAMPTZ;
