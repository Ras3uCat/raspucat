-- 020: Module Add-On Deployment — status refinement
-- Adds in_progress_at to client_modules_pending.
-- Status flow: acknowledged_at → in_progress_at (set by add-module.sh) → deployed_at (manual QA sign-off)

ALTER TABLE public.client_modules_pending
  ADD COLUMN IF NOT EXISTS in_progress_at TIMESTAMPTZ;
