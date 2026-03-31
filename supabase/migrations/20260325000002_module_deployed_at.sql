-- 020: Module Add-On Deployment
-- Adds deployed_at to client_modules_pending.
-- acknowledged_at retains its original meaning (admin saw the request).
-- deployed_at is set automatically by admin-mark-module-deployed after add-module.sh runs.

ALTER TABLE public.client_modules_pending
  ADD COLUMN IF NOT EXISTS deployed_at TIMESTAMPTZ;
