# Payments Development Skill (Stripe)
**Scope:** `execution/backend/payments/` | **Authority:** High (Financial Safety)

## Stripe Architecture
- **Source of Truth:** All subscription states must be derived from Stripe Webhooks.
- **Backend Flow:** Client -> Create Checkout Session -> Stripe -> Webhook -> Supabase.
- **Polling:** Flutter clients must listen to the `profiles` table in Supabase for status updates post-payment.

## Implementation Rules (Non-Negotiable)
- **Signature Verification:** All incoming webhooks MUST verify the `Stripe-Signature` header.
- **Idempotency:** Handle `evt_id` to prevent double-processing of events.
- **No Client Authority:** The Flutter app NEVER updates its own `is_premium` flag; it only reads what the backend provides.
- **Environment:** Use `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` from protected env vars only.

## Event Mapping
- `checkout.session.completed`: Provisions initial access.
- `customer.subscription.deleted`: Revokes access immediately.
- `invoice.payment_failed`: Triggers "payment required" UI state.

## Security Check
Before any merge:
1. Verify no Stripe Secret Keys are hardcoded or in logs.
2. Ensure the webhook endpoint is public but protected by Stripe signature checks.