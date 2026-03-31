# 019 — Dynamic Handoff Email by Module

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

## Mode
FLOW

---

## Overview

The cancellation handoff email (feature 011) sends generic "What to do next" guidance
regardless of what features the client's site actually has. This feature makes that section
module-aware using `quotes.modules` — a text array of site feature slugs (e.g.
`["booking","newsletter","gallery"]`) already read by `admin-register-site`.

---

## Problem
- Handoff email has generic DNS/Supabase guidance regardless of active modules
- Client with shop gets no mention of how to access their Stripe dashboard or export orders
- Client with booking gets no mention of cancellation policy or refund flow
- Client with newsletter gets no "export your subscribers" warning
- Gallery warning (time-sensitive — storage tied to Supabase account) buried at the bottom

---

## Data Source

`quotes.modules` (text[]) is the authoritative source — it stores modular project feature
slugs (`booking`, `shop`, `newsletter`, etc.) set by `deliver.sh` → `admin-register-site`.

This is distinct from `quotes.module_ids` which stores Raspucat catalog add-on IDs
(`booking_shop`, `blog_gallery`) and is not used here.

---

## Scope

### Migration
- [ ] Add `modules text[] not null default '{}'` to `quotes` table
  - Column already referenced in `admin-register-site` — just needs the DB column to exist
  - Also add `client_slug text` — derived from `business_name` at quote creation (slugified),
    used in the Supabase transfer note (`{slug}@raspucat.com`)

### `admin-register-site` patch
- [ ] Accept `modules` array in request body from `deliver.sh` and write it to
  `quotes.modules` on every deploy (idempotent — overwrites on re-deploy)
- [ ] Accept `clientSlug` in request body and write to `quotes.client_slug`
  (already receives `clientSlug` param — just needs to persist it to the new column)

### `admin-send-handoff` — `buildClientPackage()`
- [ ] Replace the current static "What to do next" section with composed module-aware blocks
- [ ] Read `quote.modules` (string[]) and `quote.client_slug` from the fetched quote row
- [ ] Build section in this order:
  1. Always-present block (Supabase transfer, DNS, support)
  2. Gallery block — if present, **move to top** (time-sensitive)
  3. Module blocks in order: booking, shop, events, newsletter, blog,
     subscriptions, crm, loyalty, referrals, gift, reviews
- [ ] Use `modules.includes('booking')` style conditionals throughout
- [ ] Each block is a self-contained styled card using the existing `themedEmail()` design

### Module-Aware Handoff Content

#### Always included
- Supabase account transfer: "Your database is under `{client_slug}@raspucat.com` — log in at
  supabase.com and update the account email to take full ownership"
- DNS transfer: update A record when ready to move to a new host
- Support: reply to this email for help during transition

#### If `gallery` in modules (surface early — time-sensitive)
> ⚠ Download your gallery photos now — they live in Supabase Storage tied to your account.
> Once the account is transferred, the storage bucket moves with it. Download before any
> migration to avoid access issues.

#### If `booking` in modules
- Your booking payments are in your own Stripe account. Log in at stripe.com using the email
  address you used during Stripe onboarding to access payouts, refunds, and settings.
- Cancellation policy: Admin → Settings → Booking Rules
- Issue refunds: Admin → Bookings → select booking → Refund

#### If `shop` in modules
- Your shop payments are in your Stripe account (same login as above if booking is also active).
- Fulfil orders: Admin → Shop → Orders
- Export products: Admin → Shop → Products → Export (keep a copy before switching platforms)

#### If `events` in modules
- Your event payments are in your Stripe account. Log in at stripe.com to manage payouts.
- Stripe webhook: if you move to a new provider, you'll need to re-register the webhook endpoint
- Past attendee data: exportable from your Supabase dashboard (`event_tickets` table)

#### If `newsletter` in modules
- Export your subscriber list from Supabase (`newsletter_subscribers` table) before transferring
- Resend domain: verify a new domain with your new email provider — existing Resend verification
  is tied to this project
- ⚠ Unsubscribe links: existing links will stop working once the site is down. Notify subscribers
  before go-down if possible.

#### If `blog` in modules
- Blog posts are stored in your Supabase DB (`blog_posts` table) — fully exportable
- No third-party CMS dependency — all content is yours and travels with the database

#### If `subscriptions` in modules
- Recurring subscription management is in your Stripe account at stripe.com
- Active subscribers should be notified of any plan or billing changes before they happen
- Subscriber records are in Supabase (`subscriptions` table) — exportable

#### If `crm` in modules
- Client records (`profiles` + `bookings`) are exportable from your Supabase dashboard
- Export via: Supabase Dashboard → Table Editor → select table → Export to CSV

#### If `loyalty` in modules
- Loyalty points ledger is in Supabase (`loyalty_ledger` table) — exportable
- Points balances will be lost if clients are migrated to a new platform without data migration

#### If `referrals` in modules
- Referral records are in Supabase (`referrals` table) — exportable
- Outstanding referral rewards (discount codes) will stop working when the site goes down

#### If `gift` in modules
- Gift voucher records are in Supabase (`gift_vouchers` table) — exportable
- ⚠ Outstanding unredeemed vouchers: you are responsible for honouring these after transition.
  Export the list and contact those clients directly.

#### If `reviews` in modules
- Review records are in Supabase (`reviews` table) — exportable
- Google Reviews Auto-Sync (if enabled) will stop pulling once the site is down

---

## Acceptance Criteria
- [ ] `quotes.modules` column exists in DB and is written by `admin-register-site` on deploy
- [ ] `quotes.client_slug` column exists and is written by `admin-register-site` on deploy
- [ ] Handoff email "What to do next" only contains blocks for modules in `quotes.modules`
- [ ] Gallery block appears near top of module section (before booking/shop/etc.)
- [ ] Booking clients see Stripe login instructions + cancellation policy + refund guidance
- [ ] Shop clients see Stripe login + order fulfil + product export guidance
- [ ] Newsletter clients see subscriber export + unsubscribe token warning
- [ ] Referral/gift/review clients see their relevant export + caveat guidance
- [ ] Always-present block (Supabase transfer, DNS, support) renders regardless of modules
- [ ] `client_slug` renders correctly in Supabase transfer note
- [ ] Clients without a given module see none of that module's content

---

## Dependencies
- Feature 011 ✅ — this enhances `admin-send-handoff`'s `buildClientPackage()` function
- `deliver.sh` (modular project) — must pass `modules` + `clientSlug` to `admin-register-site`
  (already passes `clientSlug`; needs `modules` added to the payload)

---

## Notes
- `quotes.modules` slugs come from the modular project `client.json` MODULES array.
  Do NOT confuse with `quotes.module_ids` (Raspucat catalog add-on UUIDs/IDs).
- `admin-register-site` already reads `quote.modules` with `.includes('booking')` style checks.
  The column just needs the DB migration to exist.
- Stripe guidance says "log in at stripe.com using the email from Stripe onboarding" —
  this is intentionally generic since we don't store their Stripe email. Keep it actionable.
- Gallery warning is time-sensitive because storage bucket ownership transfers with the
  Supabase account. Surface it first in the module section.
- The same module-awareness could later apply to the launch email (014) "what you can manage"
  section — treat as a follow-on to 014, not in scope here.
