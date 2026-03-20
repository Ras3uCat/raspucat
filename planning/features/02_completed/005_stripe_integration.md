# 005_stripe_integration

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

**Mode: STUDIO**

**Depends on:** `001_plans_section` (completed) — Stripe checkout is the payment layer that replaces the `mailto:` CTA in the configurator.

---

## Overview

Add a full Stripe payment flow to the Raspucat configurator. When a visitor finishes configuring their plan and management option, they click **"Initiate Launch Sequence"** and are presented with a custom Stripe Elements payment form (no redirect, card data never touches our server). Stripe charges a **50% deposit** upfront. The remaining 50% and management subscription are triggered later from a protected **Admin Dashboard** built into the Flutter web app.

This feature is also a portfolio showcase — every part (custom Elements form, webhook handling, admin triggers) demonstrates full-stack Stripe capability to prospective clients.

---

## Pricing Logic

| Item | At Checkout | Later (Admin trigger) |
|:---|:---:|:---:|
| Setup fee | 50% deposit | 50% balance via saved card |
| Management subscription | Not started | Admin triggers when site goes live |

- Deposit amount = `floor(setupPrice / 2)` — round down so balance is never negative.
- Management subscription is only created if client selected a monthly/annual option (not Handover & Docs).
- Handover & Docs ($400 one-time) is charged in full at checkout — no subscription needed.

---

## User Flow

```
[Configurator Step 2 — Management]
      │
      ▼
[User clicks "Initiate Launch Sequence"]
      │
      ▼
┌─────────────────────────────────────────┐
│  STEP 3 — Your Details                  │
│  ─────────────────────────────────────  │
│  Name        [________________]         │
│  Email       [________________]         │
│  Business    [________________]         │
│                                         │
│  Order Summary (read-only)              │
│  ─ Plan: Premium Engine                 │
│  ─ Modules: X selected                  │
│  ─ Management: Standard ($149/mo)       │
│  ─ Setup total: $3,500                  │
│  ─ Due today (50% deposit): $1,750      │
│                                         │
│  [Continue to Payment →]               │
└─────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│  STEP 4 — Payment                       │
│  ─────────────────────────────────────  │
│  [Stripe Elements card form]            │
│  Card number / Expiry / CVC             │
│                                         │
│  🔒 Secured by Stripe                   │
│                                         │
│  [⚡ Initiate Launch Sequence]          │
└─────────────────────────────────────────┘
      │
      ▼
[Stripe processes payment]
      │
      ├── Success → Confirmation screen + Supabase quote updated + email to owner + email to client
      └── Failure → Inline error on form, no navigation away
```

---

## Admin Dashboard Flow

```
[/admin — password-gated route]
      │
      ▼
┌────────────────────────────────────────────────────────┐
│  Quotes                                    [🔒 Logout] │
│  ──────────────────────────────────────────────────────│
│  Client         Plan       Deposit   Balance  Status   │
│  ──────────────────────────────────────────────────────│
│  Jane Smith     Premium    ✅ Paid   $1,750   Awaiting │
│    [Charge Remaining $1,750]  [Start Subscription]     │
│                                                        │
│  John Doe       Pro        ✅ Paid   $1,100   Complete │
│    Subscription: Active since 2026-04-01               │
└────────────────────────────────────────────────────────┘
```

- "Charge Remaining" → calls Edge Function → uses saved Stripe `customerId` + `paymentMethodId` to create a PaymentIntent for the balance.
- "Start Subscription" → calls Edge Function → creates Stripe Subscription for that customer using their saved payment method.
- Both buttons show inline success/error feedback. No page reload.

---

## Acceptance Criteria

### Price Summary Bar (Steps 1 & 2)
- [x] Below the setup cost, show two lines: "Due today: $X (50% deposit)" in gold and "Due on launch: $Y" in secondary text.
- [x] For Handover & Docs selection, show "Due today: $400 (paid in full)" — no balance line.

### Configurator — Step 3 (Details)
- [x] After Step 2, "Initiate Launch Sequence" button advances to a new Step 3 within the same overlay.
- [x] Step 3 collects: full name, email, business name.
- [x] Order summary is shown read-only: plan, selected modules count, management choice, setup total, deposit due today.
- [x] All fields validated before proceeding to Step 4.
- [x] "Back" returns to Step 2 without losing selections.

### Configurator — Step 4 (Payment)
- [x] **Payment Element** (not Card Element) renders inline — modern, supports all payment methods dynamically.
- [x] Dynamic payment methods enabled in Stripe Dashboard — `payment_method_types` is NOT hardcoded.
- [x] Form styled to match the site's dark theme.
- [x] Stripe secret key is never in client code — PaymentIntent is created server-side via Supabase Edge Function.
- [x] PaymentIntent is created with `setup_future_usage: 'off_session'` so the payment method is saved to the Stripe Customer for future balance + subscription charges.
- [x] Client uses **Stripe Confirmation Tokens** (not `createPaymentMethod`/`createToken`) for pre-PaymentIntent rendering.
- [x] Stripe API version `2026-01-28.clover` used in all Edge Functions.
- [x] Deposit amount (50%) is calculated from `setupPrice` and passed to the Edge Function.
- [x] "Initiate Launch Sequence" button triggers Stripe payment confirmation.
- [x] On success: overlay closes, confirmation screen shown with order summary and "We'll be in touch" message.
- [x] On failure: Stripe error message shown inline on the form. No navigation away.
- [x] "🔒 Secured by Stripe" badge visible below the form.

### Quote Capture (Supabase)
- [x] `create-payment-intent` Edge Function creates a `quotes` record with status = `pending` and attaches the `quote_id` to the Stripe PaymentIntent metadata — this is how the webhook identifies which record to update.
- [x] `stripe-webhook` updates the existing `quotes` record (looked up via `metadata.quote_id`) to status = `deposit_paid`, writing `stripe_customer_id`, `stripe_payment_intent_id`, and `stripe_payment_method_id`.
- [x] Failed or abandoned payments leave the quote at status = `pending` indefinitely (no cleanup needed for MVP).
- [x] The `quotes` table stores `stripe_payment_method_id` — required for off-session balance charge and subscription creation.

### Webhook — All Events
- [x] Webhook signature is verified using `STRIPE_WEBHOOK_SECRET` on every request.
- [x] **Idempotency:** `evt.id` is checked against a `processed_webhook_events` table before processing — duplicate deliveries are silently ignored.
- [x] Handles unknown event types gracefully (log and return 200, do not throw).
- [x] Stripe API version `2026-01-28.clover` used.

### Webhook — Deposit (`payment_intent.succeeded`)
- [x] Updates the `quotes` record status to `deposit_paid`, stores `stripe_customer_id`, `stripe_payment_intent_id`, `stripe_payment_method_id`.
- [x] Sends notification email to `meow@raspucat.com`: client name, plan, modules, management choice, deposit paid, balance due.
- [x] Sends confirmation email to client: order summary, deposit receipt, balance due on launch, Stripe Customer Portal link.
- [x] Email provider: **Resend** (via Supabase Edge Function).

### Webhook — Subscription Payment (`invoice.payment_succeeded`)
- [x] Looks up the quote via `stripe_subscription_id` (or `stripe_customer_id`) to get client details.
- [x] Sends notification email to `meow@raspucat.com`: client name, subscription plan, amount charged, next billing date.
- [x] Sends receipt email to client: amount charged, period covered, next billing date, Stripe Customer Portal link.
- [x] Skips emails when `invoice.billing_reason == 'subscription_create'` — first invoice overlaps with deposit email.

### Webhook — Upcoming Renewal Reminder (`invoice.upcoming`)
- [x] Sends reminder email to client 3 days before renewal: amount due, billing date, Stripe Customer Portal link to update payment method if needed.
- [x] No owner email needed — informational only for the client.
- [x] **Requires:** `invoice.upcoming` added to the Stripe webhook endpoint's subscribed events. Default lead time in Stripe is 3 days (configurable in Stripe Dashboard → Settings → Billing → Manage upcoming renewal email).

### Webhook — Failed Subscription Payment (`invoice.payment_failed`)
- [x] Sends alert email to `meow@raspucat.com`: client name, amount that failed, next retry date.
- [x] Sends email to client: payment failed notice, link to update payment method via Stripe Customer Portal.

### Webhook — Subscription Cancelled (`customer.subscription.deleted`)
- [x] Updates the `quotes` record: clears `stripe_subscription_id`, sets `subscription_started_at` to null.
- [x] Sends notification email to `meow@raspucat.com`: client name, subscription cancelled, effective date.

### Balance Charge Emails (`charge-balance` Edge Function)
- [x] On successful balance charge, sends notification email to `meow@raspucat.com`: client name, amount charged, project now fully paid.
- [x] Sends receipt email to client: final payment confirmation, amount, note that their site build is now fully funded.

### Admin Dashboard
- [x] Protected route at `/admin` — password-gated (env var `ADMIN_PASSWORD`).
- [x] Lists all quotes from Supabase ordered by created date descending.
- [x] Only shows quotes with status = `deposit_paid`, `fully_paid` — excludes `pending` (incomplete checkouts).
- [x] Each row shows: client name, email, plan, deposit paid, balance due, management option, billing cycle, subscription status.
- [x] "Charge Remaining" button: visible only when status = `deposit_paid` and `balance_cents > 0`. Calls Edge Function → charges balance to saved payment method → updates status to `fully_paid`.
- [x] "Start Subscription" button: visible only when management option is monthly/annual (not Handover & Docs) and `subscription_started_at` is null. Calls Edge Function → creates Stripe Subscription with correct billing cycle (monthly or annual) → updates Supabase with `stripe_subscription_id` and `subscription_started_at`.
- [x] Both buttons show loading state and inline success/error feedback.
- [x] Admin route is excluded from the main site navigation.

---

## Architecture

### Client (Flutter Web)
- `stripe_js` package — Stripe Elements rendered in Flutter Web via JS interop.
- Step 3 and Step 4 are new steps added to `PlanConfiguratorOverlay` (steps 2 → 3 → 4).
- Admin dashboard is a new screen `lib/app/modules/screens/admin_screen.dart` with its own route and binding.
- No Stripe secret key ever in Flutter code.

### Server (Supabase Edge Functions)
| Function | Trigger | Purpose |
|:---|:---|:---|
| `create-payment-intent` | Client calls on Step 4 load | Creates Stripe Customer + pending `quotes` record + PaymentIntent with `setup_future_usage: off_session`; returns `clientSecret` and `quoteId` |
| `stripe-webhook` | Stripe calls on payment events | Handles `payment_intent.succeeded` (deposit) and `invoice.payment_succeeded` (subscription renewals) — verifies signature, updates quote, sends owner + client emails via Resend |
| `charge-balance` | Admin dashboard button | Charges `balance_cents` off-session to saved payment method; updates status to `fully_paid`; sends balance receipt emails to owner + client |
| `start-subscription` | Admin dashboard button | Creates Stripe Subscription with correct interval (month or year based on `billing_cycle`); updates Supabase |

**Note:** All Edge Functions must return CORS headers (`Access-Control-Allow-Origin`) to allow calls from the Flutter Web app domain.

### Supabase Schema

```sql
-- supabase/migrations/20260318000001_quotes.sql
create table quotes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  client_name text not null,
  client_email text not null,
  business_name text not null,
  plan_id text not null,
  module_ids text[] not null default '{}',
  management_option_id text,
  billing_cycle text check (billing_cycle in ('monthly', 'annual', 'onetime')),
  setup_total_cents int not null,
  deposit_cents int not null,
  balance_cents int not null,
  stripe_customer_id text,
  stripe_payment_intent_id text,
  stripe_payment_method_id text,  -- saved for off-session balance charge + subscription
  stripe_subscription_id text,
  status text not null default 'pending'
    check (status in ('pending', 'deposit_paid', 'fully_paid', 'cancelled')),
  subscription_started_at timestamptz
);

-- Public: insert only (client submits quote)
-- Admin: full access via service role key in Edge Functions
alter table quotes enable row level security;
create policy "deny all public reads" on quotes for select using (false);
create policy "deny all public writes" on quotes for insert with check (false);

-- Webhook idempotency table
create table processed_webhook_events (
  evt_id text primary key,
  processed_at timestamptz default now()
);
```

---

## Environment Variables

```env
# .env (Flutter — client-safe only)
# Use pk_test_... during development, pk_live_... for production
STRIPE_PUBLISHABLE_KEY=pk_test_...

# Supabase Edge Function secrets (never in client)
# Use sk_test_... during development, sk_live_... for production
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...        # different value for test vs live
STRIPE_CUSTOMER_PORTAL_URL=https://billing.stripe.com/p/login/...
RESEND_API_KEY=re_...
RESEND_FROM_EMAIL=hello@raspucat.com   # must be a verified domain in Resend
ADMIN_PASSWORD=...
NOTIFICATION_EMAIL=meow@raspucat.com
```

---

## Design Decisions

| Decision | Choice | Rationale |
|:---|:---|:---|
| Stripe Elements vs Checkout | **Payment Element** (custom form) — overrides `stripe-checkout-subscriptions` skill default | Portfolio showcase — demonstrates full-stack Stripe capability. Skill prefers Checkout Sessions; Payment Element is the approved exception per skill ("Payment Element OK for advanced customization"). Confirmation Tokens used as required. |
| 50% deposit | Yes | Industry standard for web dev; protects both parties; reduces friction vs. full payment upfront |
| Balance + subscription trigger | Admin dashboard | Owner controls timing — subscription shouldn't start before site is live |
| Secret key location | Supabase Edge Functions only | Card data and secret key never on client; Stripe-compliant |
| Admin auth | Password via env var | Simple for a solo operator; no need for full auth system for one admin |
| Quote storage | Supabase `quotes` table | Single source of truth; enables admin dashboard; survives email failure |
| Email provider | Resend | First-class Supabase Edge Function support, simple API, generous free tier |
| Deposit UI in configurator | Due today / Due on launch lines in PriceSummaryBar | Sets payment expectations before the client reaches checkout — reduces drop-off and support questions |
| Client confirmation email | Resend → client on webhook success | Professional handoff; Stripe Customer Portal link lets them self-manage payment method without contacting you |

---

## Scope Control

- [x] **Included:** Stripe Elements custom payment form (Steps 3 & 4 in configurator overlay)
- [x] **Included:** 50% deposit charged at checkout
- [x] **Included:** Quote saved to Supabase on successful payment
- [x] **Included:** Stripe webhook → Supabase update + owner + client emails for deposit (`payment_intent.succeeded`)
- [x] **Included:** Stripe webhook → owner + client emails for every subscription renewal (`invoice.payment_succeeded`)
- [x] **Included:** Owner + client emails when final 50% balance is charged via admin
- [x] **Included:** Admin dashboard at `/admin` (password-gated)
- [x] **Included:** "Charge Remaining" one-click from admin
- [x] **Included:** "Start Subscription" one-click from admin
- [x] **Included:** Deposit/balance breakdown shown in PriceSummaryBar during configurator flow
- [x] **Included:** Resend as email provider for all transactional emails
- [x] **Included:** Webhook idempotency via `processed_webhook_events` table
- [x] **Included:** `invoice.payment_failed` handler — alerts owner + client on failed subscription renewal
- [x] **Included:** `customer.subscription.deleted` handler — updates Supabase + notifies owner
- [ ] **NOT Included:** Client-facing account/portal (Stripe Customer Portal link sent in email only)
- [ ] **NOT Included:** Automated subscription start (manual trigger only for MVP)
- [ ] **NOT Included:** Refund flow (handled directly in Stripe dashboard)
- [ ] **NOT Included:** Multi-admin or role-based access

---

## Resolved Decisions

1. **Handover & Docs ($400 one-time):** Charged in full at checkout — no 50/50 split. ✅
2. **Deposit rounding:** Floor on deposit, ceiling on balance (e.g. $2,201 → $1,100 + $1,101). ✅
3. **Email provider:** Resend. ✅
4. **Admin auth:** Static env var password is sufficient for MVP. ✅
5. **Client email:** Confirmation email sent via Resend after successful payment — includes order summary, deposit receipt, balance due on launch, and Stripe Customer Portal link. ✅
