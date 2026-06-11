-- Update plans.monthly_price to match new Standard Management rate ($179/mo)
-- Previously 14900 ($149) which was the old Standard price — now display hint reflects new pricing.
UPDATE public.plans
SET monthly_price = 17900
WHERE monthly_price = 14900;

-- rollback: UPDATE public.plans SET monthly_price = 14900 WHERE monthly_price = 17900;
