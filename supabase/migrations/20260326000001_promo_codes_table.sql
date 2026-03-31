-- Custom promo code table — supports three modes:
--   'setup'        → discounts setup fee only
--   'subscription' → discounts subscription only
--   'both'         → discounts setup fee AND subscription (can use different Stripe promo codes for each)
--
-- validate-promo-code and create-payment-intent check this table first before falling
-- back to raw Stripe promotion code lookup.

CREATE TABLE IF NOT EXISTS public.promo_codes (
  id                                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at                         TIMESTAMPTZ DEFAULT now(),
  code                               TEXT        NOT NULL,
  applies_to                         TEXT        NOT NULL DEFAULT 'both'
                                                   CHECK (applies_to IN ('setup', 'subscription', 'both')),
  stripe_setup_promo_code_id         TEXT,        -- Stripe promotion code ID for setup discount
  stripe_subscription_promo_code_id  TEXT,        -- Stripe promotion code ID for subscription discount
  description                        TEXT,        -- Human-readable label shown to client
  active                             BOOLEAN     NOT NULL DEFAULT true,
  CONSTRAINT promo_codes_code_unique UNIQUE (code)
);

-- Drop existing migration that added subscription_promotion_code_id
-- (already applied in 20260325000005) — column already exists, no action needed.

-- Remove old single-column approach on quotes (keep for now — start-subscription reads it)
-- will be superseded by the table-driven approach but backwards compatible.
