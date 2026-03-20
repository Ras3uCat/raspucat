# 011 — Subscription Cancellation Handoff

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
When a client cancels their subscription via the Stripe Customer Portal, they are no longer
covered by the managed service. They need to receive everything they own — files, credentials,
repo links, DNS info, deliverables — so they can self-manage or hand off to another provider.

Currently `customer.subscription.deleted` only clears subscription fields in Supabase. This
feature adds a full handoff flow triggered by that event.

---

## Problem
- Client cancels → Supabase updated, but client receives nothing
- No admin alert to prepare handoff docs
- Client is left without their assets, which is a support/legal risk

---

## Proposed Flow

```
Stripe: customer.subscription.deleted
  ↓
stripe-webhook (enhanced handler)
  ├─ Update quote status → 'cancelled'
  ├─ Log cancellation in quote_events
  ├─ Email admin: "Client X cancelled — handoff needed" (via Resend)
  └─ Email client: handoff package (files, deliverables, next steps)
```

---

## Scope

### Backend (Supabase Edge Functions)
- [ ] Enhance `stripe-webhook`: `customer.subscription.deleted` handler
  - Set `quote.status = 'cancelled'`
  - Insert `quote_events` row: `type='subscription_cancelled'`
  - Fire admin notification email (Resend)
  - Fire client handoff email (Resend)
- [ ] Handoff email content: pull `portal_files` and `portal_deliverables` for that quote
- [ ] Add `cancelled_at` timestamp column to `quotes` table (migration)

### Email Templates (Resend)
- [ ] **Admin alert:** client name, business, cancellation date, link to admin panel quote
- [ ] **Client handoff email:**
  - Thank you / sorry to see you go message
  - List of all their deliverable links from `portal_deliverables`
  - List of all uploaded files from `portal_files`
  - "What to do next" guidance (DNS transfer, repo access, etc.)
  - Support contact for any questions during transition

### Admin Panel (Flutter)
- [ ] Show `cancelled` status badge on quote row
- [ ] Show cancellation date in quote detail drawer
- [ ] Optional: "Send Handoff Email" manual re-trigger button (in case client misses it)

---

## Acceptance Criteria
- [ ] Cancellation via Stripe Portal triggers both emails within 60 seconds
- [ ] Admin email contains client name and link to their quote in admin panel
- [ ] Client email lists all files and deliverables stored for that quote
- [ ] Quote status in Supabase is `cancelled` with a `cancelled_at` timestamp
- [ ] Event is logged in `quote_events` with `type='subscription_cancelled'`
- [ ] No duplicate emails on Stripe webhook retry (idempotency via `processed_webhook_events`)
- [ ] Manual re-trigger button available in admin panel for missed/failed sends

---

## Out of Scope
- Automated PDF generation (use static email template for MVP)
- Re-subscription / win-back flow (future feature)
- Prorated refunds (handled by Stripe Portal config)

---

## Dependencies
- `010_stripe_customer_portal` — cancellation is initiated there
- Existing `stripe-webhook` edge function
- Existing `portal_files` and `portal_deliverables` tables
- Resend email integration already in place

---

## Mode
STUDIO

---

## Notes
- Stripe sends `customer.subscription.deleted` when the subscription period ends (not immediately
  on cancel if `cancel_at_period_end` is set). Confirm portal config — if using period-end
  cancellation, the handoff should fire on `customer.subscription.updated` where
  `cancel_at_period_end=true` for an early warning, and again on `deleted` for the final send.
- Consider whether the client handoff email should be sent immediately on cancel request or at
  period end. Recommendation: send admin alert immediately, send client package at period end.
