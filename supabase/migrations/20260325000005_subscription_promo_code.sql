-- Store the Stripe promotion code ID on the quote so start-subscription
-- can apply it to the subscription creation (discounts the recurring billing).
-- The same code discounts both setup fee (computed locally) and subscription (applied by Stripe).

ALTER TABLE public.quotes
  ADD COLUMN IF NOT EXISTS subscription_promotion_code_id TEXT;
