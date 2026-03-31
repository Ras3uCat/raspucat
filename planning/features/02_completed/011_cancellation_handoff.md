# 011 — Subscription Cancellation Handoff

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

---

## Overview
When a client cancels their subscription, they are no longer covered by the managed service.
They need to receive everything they own — files, credentials, repo links, DNS info,
deliverables — so they can self-manage or hand off to another provider.

Cancellation is initiated from within the **Raspucat client portal** (not the Stripe Customer
Portal directly). This allows a cancellation dialog to collect a delivery email address before
the cancellation is submitted to Stripe. The handoff package is then sent to that address.

Currently `customer.subscription.deleted` only clears subscription fields in Supabase. This
feature adds the full cancellation dialog and handoff flow.

---

## Problem
- Client cancels → Supabase updated, but client receives nothing
- No admin alert to prepare handoff docs
- Client is left without their assets, which is a support/legal risk
- Stripe Customer Portal is a hosted UI — custom dialogs cannot be injected into it
- Cancellation via Stripe Portal is disabled in Stripe settings, so `delivery_email` will always be present when the webhook fires

---

## Architecture: Two Cancellation Paths

Both paths must trigger the handoff. The handoff email content (`portal_files`,
`portal_deliverables`) lives in **Raspucat's** database. Stripe billing events fire on
**Raspucat's Stripe account**, so they route to Raspucat's existing `stripe-webhook`.

**Solution:** `admin-send-handoff` (Raspucat) owns all handoff email logic.
Both paths call it with `{ quoteId, action }`.

```
PATH A — Client-initiated (cancel_at_period_end)
─────────────────────────────────────────────────
Client portal → portal-cancel-subscription (Raspucat)
  ├─ Writes delivery_email + subscription_cancel_at to quotes
  ├─ Stripe: subscription.update({ cancel_at_period_end: true })
  └─ Returns period_end to portal

Stripe → customer.subscription.updated (cancel_at_period_end=true)
  └─ stripe-webhook (Raspucat — existing webhook, invoice.paid event added)
       ├─ POST admin-send-handoff — admin alert immediately
       └─ If handoff_fee_cents > 0: create Stripe invoice for handoff fee
          Else: POST admin-send-handoff — client package immediately

Stripe → invoice.paid (metadata.type == 'handoff')
  └─ stripe-webhook (Raspucat)
       └─ POST admin-send-handoff — fire client handoff package

Stripe → customer.subscription.deleted
  └─ stripe-webhook (Raspucat)
       ├─ Set quote.status = 'cancelled', write cancelled_at
       ├─ Insert quote_events: type='subscription_cancelled'
       └─ If handoff_package_ready still false: POST admin-send-handoff (fallback)


PATH B — Admin-initiated (immediate cancel)
───────────────────────────────────────────
Admin panel → admin-cancel-subscription (Raspucat)
  ├─ Stripe: subscriptions.cancel() (immediate)
  ├─ Sets status = 'cancelled', cancelled_at
  ├─ Logs quote_events: type='subscription_cancelled'
  └─ POST admin-send-handoff — admin alert + client handoff package immediately
```

> **Implementation note:** All webhook handling lives in the existing Raspucat `stripe-webhook`
> function (already registered at `stripe-webhook` endpoint). The `invoice.paid` event was
> added to that webhook's event list in Stripe Dashboard. No separate webhook endpoint needed.

---

## Scope

### Stripe Configuration (one-time, no code)
- [ ] Stripe Dashboard → Settings → Customer Portal → disable "Cancel subscription" option
  - Clients can still manage billing, update cards, and view invoices via the portal
  - Cancellation is only possible through the Raspucat client portal

### Client Portal (Flutter)
- [ ] Keep existing "Manage Subscription" button (opens Stripe Customer Portal for billing)
- [ ] Add a separate **Cancel Subscription** button below it
- [ ] Cancellation dialog:
  - Warning copy: "Your service will end on [current period end date]"
  - Email input field pre-filled with the client's account email, fully editable
  - Label: "Where should we send your files and deliverables?"
  - Confirm button (disabled until email is valid)
  - Back button to dismiss without action
- [ ] On confirm: call `client-cancel-subscription` edge function with `{ delivery_email }`
- [ ] On success: show "Cancellation confirmed" state in portal (subscription shows end date, cancel button hidden)
- [ ] Validate email format client-side before enabling confirm button

### Backend — Raspucat (portal + webhook)
- [x] New edge function `portal-cancel-subscription` (Raspucat — JWT auth from portal user):
  - Auth: must be called by the authenticated portal user (JWT — can only cancel their own quote)
  - Validate `delivery_email` is a well-formed email
  - Write `delivery_email` + `subscription_cancel_at` to `quotes` row
  - Call Stripe API: `stripe.subscriptions.update(sub_id, { cancel_at_period_end: true })`
  - Return `{ period_end: timestamp }` so the portal can display the end date
- [x] Enhanced existing `stripe-webhook` (Raspucat) to handle:
  1. `customer.subscription.updated` where `cancel_at_period_end=true`:
     - POST `admin-send-handoff` with `{ quoteId, action: 'admin_alert' }`
     - If `quotes.handoff_fee_cents > 0`: create Stripe one-time invoice (metadata: `type=handoff, quote_id=...`), write `handoff_invoice_id` to quotes
     - If `handoff_fee_cents == 0`: POST `admin-send-handoff` with `{ quoteId, action: 'client_package' }`
  2. `invoice.paid` where `metadata.type == 'handoff'`:
     - POST `admin-send-handoff` with `{ quoteId, action: 'client_package' }`
  3. `customer.subscription.deleted`:
     - Set `quote.status = 'cancelled'`, write `cancelled_at`
     - Insert `quote_events` row: `type='subscription_cancelled'`
     - If `handoff_package_ready` is false: POST `admin-send-handoff` with `{ quoteId, action: 'client_package' }` (fallback)
  - Idempotency: check `quote.handoff_package_ready` before firing client package email — skip if already true

### Backend — Raspucat (admin system)
- [ ] New edge function `admin-send-handoff`:
  - Accepts `{ quoteId, action: 'admin_alert' | 'client_package', adminToken? }`
  - `admin_alert`: sends admin alert email — client name, business, `delivery_email`, link to quote
  - `client_package`: fetches `portal_files` + `portal_deliverables` for the quote, builds and sends handoff email to `delivery_email`, sets `handoff_package_ready = true` on quote
  - Idempotency for `client_package`: check `handoff_package_ready` before sending — skip if already true
  - Can also be called directly by `admin-cancel-subscription` (Path B)
- [ ] Update `admin-cancel-subscription` (Raspucat):
  - After cancelling Stripe subscription + clearing fields: POST to `admin-send-handoff` with `{ quoteId, action: 'admin_alert' }` and `{ quoteId, action: 'client_package' }` (both, since admin cancel is immediate)
- [ ] Migration — add columns to `quotes` table:
  - `cancelled_at TIMESTAMPTZ`
  - `delivery_email TEXT`
  - `handoff_fee_cents INT DEFAULT 0` — set per client at quote creation; 0 = no fee
  - `handoff_invoice_id TEXT` — Stripe invoice ID for idempotency
  - `handoff_package_ready BOOLEAN DEFAULT false`

### Email Templates (Resend, sent from Raspucat)
- [ ] **Admin alert:** client name, business, cancellation date, account email, `delivery_email`, link to admin panel quote
- [ ] **Client handoff email:**
  - Thank you / sorry to see you go message
  - List of all deliverable links from `portal_deliverables`
  - List of all uploaded files from `portal_files`
  - "What to do next" guidance — module-aware content handled by feature 019
  - Supabase account transfer note: the project lives under `{client_slug}@raspucat.com` —
    the client should update the account email to their own address to take full ownership
  - Support contact for any questions during transition

### Admin Panel (Flutter)
- [ ] Show `cancelled` status badge on quote row
- [ ] Show cancellation date in quote detail drawer
- [ ] Show `handoff_fee_cents` field on quote creation / edit form (admin sets per client)
- [ ] Show handoff invoice status in quote detail drawer (`pending` / `paid` / `n/a`)
- [ ] "Send Handoff Email" manual re-trigger button in quote detail drawer (calls `admin-send-handoff` directly)

---

## Acceptance Criteria
- [ ] Cancel button in client portal opens the cancellation dialog
- [ ] Dialog pre-fills delivery email with the client's account email
- [ ] Client can edit the delivery email to any valid address before confirming
- [ ] Confirm button is disabled until delivery email passes format validation
- [ ] On confirm: `delivery_email` written to quote, Stripe subscription set to `cancel_at_period_end=true`
- [ ] Portal shows "Cancellation confirmed — your service ends on [date]" after dialog closes
- [ ] Admin alert email fires within 60 seconds of `cancel_at_period_end=true`
- [ ] If `handoff_fee_cents > 0`: Stripe invoice is created and `handoff_invoice_id` written to quote
- [ ] If `handoff_fee_cents > 0`: handoff package sent to `delivery_email` only after `invoice.paid`
- [ ] If `handoff_fee_cents == 0`: handoff package sent to `delivery_email` immediately
- [ ] Admin cancel path (Path B) also triggers both admin alert and client handoff package
- [ ] Admin email contains client name, `delivery_email`, and link to their quote
- [ ] Handoff email is sent to `delivery_email` (not necessarily the account email)
- [ ] Handoff email lists all files and deliverables stored for that quote
- [ ] `handoff_package_ready` prevents duplicate client package emails on webhook retry
- [ ] Quote status in Supabase is `cancelled` with a `cancelled_at` timestamp on `subscription.deleted`
- [ ] Event logged in `quote_events` with `type='subscription_cancelled'`
- [ ] Manual re-trigger button in admin panel sends to the stored `delivery_email`

---

## Out of Scope
- Automated PDF generation (use static email template for MVP)
- Re-subscription / win-back flow (future feature)
- Prorated refunds (handled by Stripe Portal config)

---

## Dependencies
- `010_client_portal` — cancellation dialog lives here; Stripe Customer Portal cancel is replaced by this in-app flow
- `007_client_site_health` ✅ — `admin-deactivate-monitor` already fires in `admin-cancel-subscription`
- `013_client_email_provisioning` — provisioned email retained 90 days post-cancellation; cron handles cleanup
- Existing `stripe-webhook` edge function (Raspucat) — enhanced with handoff handlers + `invoice.paid` event added in Stripe Dashboard
- Existing `portal_files` and `portal_deliverables` tables (Raspucat)
- Resend integration in place on Raspucat

---

## Mode
STUDIO

---

## Notes
- `admin-send-handoff` is the single source of truth for handoff emails — both paths (client
  portal and admin cancel) route through it. This avoids duplication and ensures the email
  content is always built from Raspucat's data (where `portal_files` and `portal_deliverables` live).
- Idempotency is handled by `handoff_package_ready` on the quote row — no separate events
  table needed. Check before sending; set to true after sending.
- `handoff_fee_cents` is set by admin at quote creation. Typical values: 0 (included in plan),
  one month's retainer rate, or a flat fee (e.g. 15000 = $150).
- Handoff invoice metadata must include `type: 'handoff'` and `quote_id` so the `invoice.paid`
  handler can identify and route it correctly.
- Admin alert fires on `cancel_at_period_end=true`. Client gets handoff only after fee is paid
  (or immediately if no fee). `subscription.deleted` is a fallback safety net.
- The "What to do next" section of the handoff email is made module-aware by feature 019,
  which runs as a FLOW enhancement on top of this feature's base email template.
