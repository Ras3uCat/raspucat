-- Both lead-scoring edge functions (admin-lead-discovery, admin-leads) previously
-- awarded +25 points when a lead had an email on file. A missing email is easy to
-- source manually and shouldn't drag a lead's score down, so that term was removed
-- from calculateScore() in both functions. Backfill existing rows to match: leads
-- that had an email keep whatever bonus points came from other factors, minus the
-- 25 they no longer earn from email presence.
UPDATE public.leads
SET score = GREATEST(score - 25, 0)
WHERE email IS NOT NULL AND email <> '';

-- rollback:
-- UPDATE public.leads
-- SET score = LEAST(score + 25, 100)
-- WHERE email IS NOT NULL AND email <> '';
