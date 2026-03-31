-- Add promo code columns to quotes table
ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS promo_code text,
  ADD COLUMN IF NOT EXISTS discount_amount_cents integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS original_setup_total_cents integer;
