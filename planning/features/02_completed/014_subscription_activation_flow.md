# 014 — Subscription Activation Flow

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

---

## Overview

The client lifecycle has three financial stages. Stages 1 and 3 already have edge functions
and emails in place. This feature automates the handoff between stages 2 and 3 — currently
two separate manual admin button clicks.

---

## Current 3-Stage Flow

```
Stage 1 — Deposit (already automated)
  Client purchases plan + add-ons + management on Raspucat site
  └─ 50% deposit charged
  └─ stripe-webhook: payment_intent.succeeded
       ├─ Quote status → 'deposit_paid'
       ├─ Email client: "Deposit Received. Countdown to Launch."  ← existing
       └─ Email owner: deposit notification  ← existing

Stage 2 — Site goes live (manual today)
  Admin deploys site → deliver.sh → admin-register-site
  └─ site_url written to quote
  └─ UptimeRobot monitor created
  └─ portal_deliverables auto-populated  ← feature 007
  └─ Admin manually clicks "Charge Balance" in admin panel
       └─ charge-balance edge function creates Stripe invoice for remaining 50%
       └─ Client pays invoice
       └─ invoice.paid fires
            ├─ Email client: "Final payment confirmed — your site is fully funded"  ← existing
            └─ *** THIS IS WHERE AUTOMATION STOPS TODAY ***

Stage 3 — Subscription starts (manual today — to be automated)
  Admin manually clicks "Start Subscription" in admin panel
  └─ start-subscription edge function creates Stripe subscription
  └─ Email client: "Your site is live — subscription active"  ← existing
  └─ Email owner: subscription started notification  ← existing
```

---

## Problem
- After the balance invoice is paid, admin must remember to click "Start Subscription"
- If admin forgets or delays, client is live but not on a subscription — billing gap
- Quote status is not updated automatically when subscription starts

---

## Proposed Change — Automate Stage 2 → Stage 3

The balance charge uses a **Stripe Payment Intent** (not an invoice), tagged with
`metadata.is_balance = 'true'`. This event currently fires `payment_intent.succeeded`
but is explicitly filtered out at the top of `handleDepositPaid` (line 203). That
filtered path is exactly where the automation goes.

`invoice.payment_succeeded` already skips `billing_reason === 'subscription_create'`
(line 472), so the first subscription invoice is intentionally swallowed — no
double-email risk.

```
payment_intent.succeeded (stripe-webhook)
  └─ metadata.is_balance === 'true'  [currently filtered out — now handled here]
       ├─ [existing, keep] Email owner: balance received notification
       ├─ [REMOVE] Email client: "Final payment confirmed" — merged into launch email below
       ├─ [NEW] Call start-subscription logic:
       │    ├─ Create Stripe subscription
       │    ├─ Set quote.status = 'active', write activated_at
       │    └─ Insert quote_events: type='subscription_activated'
       └─ [NEW — merged email] Email client: "Your site is fully funded and live"
            covers both final payment confirmation AND subscription activation
```

invoice.payment_succeeded with billing_reason === 'subscription_create'
  └─ Already skipped (line 472) — no action needed, merged email above covers it

---

## Scope

### Backend (Supabase Edge Functions)
- [ ] Update `stripe-webhook` `payment_intent.succeeded` handler:
  - Add a new branch: if `metadata.is_balance === 'true'` (currently falls through to return)
  - Look up quote by `metadata.quote_id`
  - Guard: if `quote.activated_at` already set, skip (idempotency)
  - Extract `start-subscription` logic into a shared internal helper and call it:
    - Create Stripe subscription via Stripe API
    - Set `quote.status = 'active'`, write `activated_at`
    - Insert `quote_events` row: `type='subscription_activated'`
  - Send owner balance notification (keep existing)
  - Send merged client launch email (new — replaces two separate emails)
- [ ] Update `charge-balance` edge function:
  - Suppress the client-facing "Final payment confirmed" email — merged into launch email above
  - Keep the owner notification email (you still need to know money came in)
- [ ] `start-subscription` edge function:
  - Extract subscription creation logic into a shared helper callable from the webhook
  - Button in admin panel remains as a manual fallback — no other changes needed
- [ ] Add column to `quotes` table if not already present (migration):
  - `activated_at TIMESTAMPTZ`

### Email Templates (Resend)
- [ ] **New merged launch email** (client only) — replaces both existing client emails:
  - Subject: `"Your site is live — you're all set, {client_name}."`
  - Content: final payment confirmed + subscription active + site URL + admin panel link
  - Use existing `themedEmail()` wrapper and design system
  - Owner still receives the separate balance notification from `charge-balance` (unchanged)

### Admin Panel (Flutter)
- [ ] "Start Subscription" button retained as manual fallback — disable/hide once `activated_at` is set
- [ ] Show `active` status badge on quote row when subscription activates
- [ ] Show `activated_at` in quote detail drawer

---

## Acceptance Criteria
- [ ] `payment_intent.succeeded` with `metadata.is_balance === 'true'` triggers subscription creation
- [ ] `quote.status = 'active'` and `activated_at` written within 60 seconds of balance payment
- [ ] `quote_events` row inserted: `type='subscription_activated'`
- [ ] Merged client launch email fires once — not the old two separate emails
- [ ] `charge-balance` client email suppressed (owner email kept)
- [ ] `invoice.payment_succeeded` with `billing_reason === 'subscription_create'` remains skipped — no double email
- [ ] Idempotent: if `activated_at` already set, skip subscription creation on webhook retry
- [ ] Manual "Start Subscription" button still works as a fallback and is hidden once `activated_at` is set

---

## Out of Scope
- Changing the deposit or balance payment amounts
- In-app onboarding walkthrough

---

## Dependencies
- Existing `charge-balance` edge function
- Existing `start-subscription` edge function
- Existing `stripe-webhook` edge function
- Feature 007 (`admin-register-site`) — site must be deployed before balance is charged

---

## Mode
FLOW

---

## Notes
- Balance charge uses a Payment Intent (not an invoice) tagged with `is_balance: 'true'` —
  confirmed from `stripe-webhook/index.ts` line 203. Trigger is `payment_intent.succeeded`,
  not `invoice.paid`.
- `invoice.payment_succeeded` already skips `billing_reason === 'subscription_create'`
  (line 472) — this was intentional and remains correct. The merged launch email covers it.
- `start-subscription` logic must be extracted into a shared helper to avoid duplicating
  Stripe API calls between the webhook handler and the admin button fallback.
- The deposit email (line 317–323) already tells the client their subscription "begins
  automatically at launch" — the merged launch email fulfils that promise cleanly.
