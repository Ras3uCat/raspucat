---
id: "025"
title: Reset Test Client Data
mode: FLOW
status: backlog
---

# Reset Test Client Data

## Context

When reusing an email address to re-test the full client onboarding flow, all prior data must be removed from Supabase, Stripe, and related services so the email is treated as completely new.

This is not a code change — it's a manual ops runbook.

---

## Step 1 — Gather the Quote Record

Run in Supabase SQL Editor:

```sql
SELECT
  id,
  client_email,
  user_id,
  stripe_customer_id,
  stripe_subscription_id,
  stripe_payment_intent_id,
  cloudflare_routing_rule_id,
  uptimerobot_monitor_id,
  provisioned_email
FROM quotes
WHERE client_email = 'YOUR_EMAIL_HERE';
```

Save the values — needed for subsequent steps.

---

## Step 2 — Delete Stripe Customer

In the Stripe Dashboard (test mode), find the customer by email or `stripe_customer_id` and delete.

Deleting the customer cascades in Stripe to all subscriptions, payment intents, and payment methods.

---

## Step 3 — Delete Auth User

In Supabase Dashboard > Authentication > Users, find by email and delete.

Or via SQL:
```sql
DELETE FROM auth.users WHERE email = 'YOUR_EMAIL_HERE';
```

---

## Step 4 — Delete Quote Row

```sql
DELETE FROM quotes WHERE client_email = 'YOUR_EMAIL_HERE';
```

Cascades automatically to: `quote_events`, `portal_files` (metadata), `portal_messages`, `portal_deliverables`, `client_modules_pending`, `delivery_progress`, `site_events`.

---

## Step 5 — Delete Storage Files

In Supabase Dashboard > Storage > `portal-files` bucket:
- Find the folder named after the `quote_id` from Step 1
- Delete the entire folder

---

## Step 6 — Optional (delivery-stage clients only)

Only needed if the quote reached deployed/active stage:

- **Cloudflare email routing**: Admin panel > Deprovision Client Email, or use `cloudflare_routing_rule_id`
- **UptimeRobot monitor**: Delete monitor using `uptimerobot_monitor_id`

---

## Verification

```sql
SELECT * FROM quotes WHERE client_email = 'YOUR_EMAIL_HERE';       -- 0 rows
SELECT * FROM auth.users WHERE email = 'YOUR_EMAIL_HERE';          -- 0 rows
```

Confirm Stripe customer is gone. Re-register with the email — should onboard as a brand new client.

---

## Notes

- **Order matters**: Stripe first (IDs from DB), then auth.users, then quote row
- Steps 2 and 6 are skippable if the quote never reached payment
