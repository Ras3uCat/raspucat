# 017 — Stripe Webhook Auto-Registration

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

## Mode
FLOW

---

## Overview

Registering Stripe webhooks is the most error-prone manual step in the modular_project
delivery pipeline. For each enabled payment module (booking, shop, events, subscriptions),
you must:
1. Go to the Stripe dashboard
2. Add an endpoint URL
3. Select the correct events
4. Copy the signing secret
5. Set it in Supabase secrets

deliver.sh already knows the Supabase project ref, the site URL, and which modules need
webhooks. It can call the Stripe API to register the endpoints and push the secrets to
Supabase automatically.

---

## Problem
- Stripe webhook registration is manual, multi-step, and easy to get wrong
- Most common mistake: registering the webhook but forgetting to copy the secret to Supabase
  → webhook receives events but 400s on every one (signature mismatch)
- Must be done twice per booking/shop client: test mode and live mode
- 4 separate webhooks possible if booking + shop + events + subscriptions all enabled

---

## Proposed Flow

```
deliver.sh (after Flutter build + deploy)
  └─ For each payment module in MODULES:
       ├─ Call Stripe API: create webhook endpoint
       │    URL: {SUPABASE_URL}/functions/v1/{module}-webhook
       │    Events: module-specific event list (see below)
       ├─ Capture returned signing secret (whsec_...)
       └─ Push signing secret to Supabase secrets via Supabase Management API
            STRIPE_WEBHOOK_SECRET, STRIPE_SHOP_WEBHOOK_SECRET, etc.
```

---

## Webhook Endpoints Per Module

| Module | Edge Function URL | Events | Secret Name |
|---|---|---|---|
| `booking` | `.../stripe-webhook` | `checkout.session.completed` | `STRIPE_WEBHOOK_SECRET` |
| `shop` | `.../shop-webhook` | `checkout.session.completed`, `payment_intent.succeeded` | `STRIPE_SHOP_WEBHOOK_SECRET` |
| `events` | `.../event-webhook` | `checkout.session.completed` | `STRIPE_EVENTS_WEBHOOK_SECRET` |
| `subscriptions` | `.../subscription-webhook` | `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_succeeded`, `invoice.payment_failed` | `STRIPE_SUBSCRIPTION_WEBHOOK_SECRET` |

---

## Scope

### deliver.sh additions
- [ ] Add `--register-webhooks` flag (or auto-run if `STRIPE_SK` is set and non-empty)
- [ ] For each payment module in `MODULES`:
  - Call `stripe.webhookEndpoints.create()` via Stripe API
  - Capture `signing_secret` from response
  - Call Supabase Management API to set the secret:
    `PATCH /v1/projects/{ref}/secrets`
- [ ] On success: print registered URL + secret name (not the value) to console
- [ ] On failure: print clear error + fall back to manual instructions
- [ ] Skip if endpoint already exists for that URL (idempotent — check before creating)

### Stripe API calls (shell, using curl)
```bash
# Create webhook endpoint
WEBHOOK_RESPONSE=$(curl -s -X POST https://api.stripe.com/v1/webhook_endpoints \
  -u "${STRIPE_SK}:" \
  -d "url=${SUPABASE_URL}/functions/v1/stripe-webhook" \
  -d "enabled_events[]=checkout.session.completed")

SIGNING_SECRET=$(echo $WEBHOOK_RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['secret'])")

# Push to Supabase secrets
curl -s -X PATCH "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/secrets" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "[{\"name\":\"STRIPE_WEBHOOK_SECRET\",\"value\":\"${SIGNING_SECRET}\"}]"
```

### New client.json field
```jsonc
"SUPABASE_ACCESS_TOKEN": "",  // Personal access token from supabase.com/dashboard/account/tokens
                               // Only needed for --register-webhooks flag. Never committed.
```

### Raspucat delivery checklist integration (feature 016)
- [ ] After successful webhook registration, deliver.sh POSTs step completion to
  `admin-delivery-progress` for each registered webhook

---

## Acceptance Criteria
- [ ] Running deliver.sh with `STRIPE_SK` set + `--register-webhooks` registers all needed webhooks
- [ ] Signing secrets are pushed to Supabase secrets automatically — no manual copy/paste
- [ ] Idempotent: re-running does not create duplicate webhook endpoints
- [ ] Works for all 4 webhook types based on active modules
- [ ] Failure in webhook registration prints actionable error but does not fail the build
- [ ] Raspucat delivery checklist Stripe webhook steps auto-checked on success

---

## Out of Scope
- Live mode key switchover (still manual — intentional, as going live should be deliberate)
- Automatic deletion of test webhooks when switching to live

---

## Dependencies
- `STRIPE_SK` must be in `client.json` (it already is)
- `SUPABASE_ACCESS_TOKEN` — new field needed in `client.json`
- Feature 016 (delivery progress) — for auto-checking the webhook steps

---

## Notes
- `SUPABASE_ACCESS_TOKEN` is a personal token scoped to your Supabase account, not the
  client project. It can be the same token across all clients. Store it in your global
  shell environment (`~/.zshrc` or `~/.bashrc`) as `SUPABASE_ACCESS_TOKEN` and deliver.sh
  can read it from the environment without needing it in client.json at all.
- Stripe API: `stripe.webhookEndpoints.list()` can be used to check for existing endpoints
  before creating, preventing duplicates on re-run.
- The live key switchover (6.2 in the delivery guide) intentionally stays manual — going
  live with real money should be a deliberate decision, not an automated side effect.
