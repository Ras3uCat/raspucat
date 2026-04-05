-- Backfill email_provisioned delivery step for all quotes that already have
-- delivery_progress rows but are missing this step (added after initial deploy).
INSERT INTO delivery_progress (quote_id, step, checked, checked_by)
SELECT DISTINCT quote_id, 'email_provisioned', false, 'admin'
FROM delivery_progress
WHERE quote_id NOT IN (
  SELECT quote_id FROM delivery_progress WHERE step = 'email_provisioned'
)
ON CONFLICT (quote_id, step) DO NOTHING;
