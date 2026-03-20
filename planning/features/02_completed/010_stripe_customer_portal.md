# 010 — Stripe Customer Portal Link (Client Billing Self-Service)

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

---

## Overview
Clients with an active subscription should be able to manage their own billing without
contacting support. Stripe's hosted Customer Portal lets them update their payment method,
view invoices, and (optionally) cancel or modify their subscription.

The flow: client taps "Manage Billing" → Edge Function creates a Billing Portal session
scoped to their Stripe Customer ID → client is redirected to the hosted Stripe portal →
they return to the portal after completing their action.

---

## User Stories
- As a client with an active subscription, I want to update my credit card without
  emailing Ras3uCat.
- As a client, I want to view my past invoices and download receipts.
- As a client, I want to understand my next billing date without asking.

---

## Acceptance Criteria

### Edge Function: `portal-billing-session`
- [x] New Edge Function created at `supabase/functions/portal-billing-session/index.ts`.
- [x] `config.toml` sets `verify_jwt = false` — intentional. JWT is verified manually via
      `jose` + Supabase JWKS so CORS OPTIONS preflight is not rejected at the gateway.
      Security is equivalent; unauthenticated requests return 401 inside the function.
- [x] Fetches the client's `stripe_customer_id` from the `quotes` table using their
      authenticated user ID (`auth.uid()`). This is the **authoritative** lookup —
      the client-side value must never be trusted for this operation.
- [x] `return_url` read from `Deno.env.get('APP_URL')` (e.g. `https://raspucat.com`) —
      never hardcoded. Final value: `${APP_URL}/portal`.
- [x] If no `stripe_customer_id` found, returns `{ error: "No billing account found." }`.
- [x] Calls `stripe.billingPortal.sessions.create({ customer, return_url })`.
- [x] Returns `{ url: session.url }` on success.
- [x] Stripe secret key read from `Deno.env.get('STRIPE_SECRET_KEY')`.
- [x] CORS preflight (`OPTIONS`) handled — returns `Access-Control-Allow-Origin: *` headers.

### `PortalQuote` Model
- [x] Add `subscriptionStartedAt` (`DateTime?`) field to `PortalQuote`.
- [x] Map from `json['subscription_started_at']` — parse as nullable `DateTime`.
  > **Note:** `subscription_started_at` is set by `start-subscription` Edge Function and
  > nulled by `stripe-webhook` on cancellation. The column already exists in the DB.

### Portal UI: "Manage Billing" Button
- [x] Button appears in `PortalDashboard` when `quote.subscriptionStartedAt != null`
      **or** `quote.status == 'deposit_paid'` — i.e., any paying client.
- [x] Button label: "Manage Billing" with a `Icons.credit_card_outlined` icon.
- [x] Tapping triggers a loading state (spinner replaces icon).
- [x] On success: `launchUrl(Uri.parse(session.url), mode: LaunchMode.externalApplication)`.
- [x] On error: inline error message below the button: `"Could not open billing portal. Please try again."`
- [x] Button is visually secondary (not primary neon) — it should not compete with the
      main portal CTAs.

### Portal Controller / Repository
- [x] `PortalRepository` gets a new method `fetchBillingPortalUrl()` that calls the
      `portal-billing-session` Edge Function and returns the session URL string.
- [x] Call includes a `Future.timeout(const Duration(seconds: 10))` — on timeout, throw
      a typed error so the controller can surface a message rather than spinning forever.
- [x] `PortalController` gets `isBillingPortalLoading = false.obs` and
      `billingPortalError = RxnString()`.
- [x] `PortalController.openBillingPortal()` method:
  1. Sets `isBillingPortalLoading = true`.
  2. Calls `_repo.fetchBillingPortalUrl()`.
  3. On success: launches URL.
  4. On error (including timeout): sets `billingPortalError`.
  5. Always sets `isBillingPortalLoading = false`.

### Stripe Customer Portal Configuration
- [x] Stripe Dashboard → Billing → Customer Portal is configured before going live.
- [x] Features to enable (owner to confirm): Update payment method, View invoices,
      Cancel subscription (optional — owner decides).
- [x] Return URL set to `https://raspucat.com/portal`.
- [x] Business information and branding filled out in Stripe portal settings.

---

## Customer Flow

```
[Portal Dashboard]
       ↓
[Sees "Manage Billing" button — only if subscription active]
       ↓
[Taps button → loading spinner]
       ↓
[Edge Function creates Stripe Billing Portal session]
       ↓
[Browser opens Stripe-hosted portal in new tab]
       ↓
[Client updates card / views invoices / manages subscription]
       ↓
[Clicks "Return to Raspucat" → redirected back to /portal]
```

---

## Design Decisions

| Decision | Choice | Rationale |
|:---------|:-------|:----------|
| Auth method | Supabase JWT (`verify_jwt = true`) | Portal session must be scoped to the authenticated client |
| Server-side customer ID lookup | Edge Function re-fetches from DB | Client-side `stripeCustomerId` is display-only; server is authoritative for billing ops |
| `return_url` source | `Deno.env.get('APP_URL')` | Matches `PortalRepository` pattern; prevents staging → prod redirect bugs |
| Open in new tab | `LaunchMode.externalApplication` | Keeps portal session alive; Stripe portal is a separate hosted page |
| Button visibility | When `subscriptionStartedAt != null` OR `status == 'deposit_paid'` | Any paying client may need to manage billing / view invoices |
| Return URL | `/portal` (root portal page) | Simple, always valid; avoids deep-link complexity |
| Cancel subscription exposure | Owner decision | Enabling cancellation in Stripe portal is optional — default to off until confirmed |
| Timeout | 10 seconds | Prevents infinite spinner on slow Edge Function cold start |

---

## Open Questions (Owner to Confirm Before Moving to Active)
1. ~~Should clients be able to cancel their own subscription via the Stripe portal?~~
   **Resolved:** Yes for now — cancellation UX will be revisited in `011_cancellation_handoff.md`.
2. ~~Should the "Manage Billing" button also appear for `deposit_paid` clients?~~
   **Resolved:** Yes — button shows for both subscription and `deposit_paid` clients.
3. ~~Is `stripe_customer_id` stored on the `quotes` table, or elsewhere?~~ **Resolved:**
   confirmed on `quotes` table, already mapped in `PortalQuote.stripeCustomerId`.

---

## Implementation Detail

**New files:**
- `supabase/functions/portal-billing-session/index.ts`
- `supabase/functions/portal-billing-session/config.toml`
  ```toml
  [functions.portal-billing-session]
  verify_jwt = true
  ```

**Modified files:**
- `lib/app/data/models/portal_quote_model.dart` — add `subscriptionStartedAt` (`DateTime?`)
  field and map `json['subscription_started_at']`
- `lib/app/data/repositories/portal_repository.dart` — add `fetchBillingPortalUrl()`
  with 10s timeout
- `lib/app/controllers/portal_controller.dart` — add `openBillingPortal()`,
  `isBillingPortalLoading`, `billingPortalError`
- `lib/app/modules/widgets/portal_dashboard.dart` — add "Manage Billing" button below
  stats row, conditional on `quote.subscriptionStartedAt != null`

---

## Edge Cases & QA
- [x] Client with no Stripe customer ID sees a graceful error, not a crash.
- [x] Network timeout (>10s) on Edge Function call shows error, not infinite spinner.
- [x] Button is not shown when client has no active subscription AND is not `deposit_paid`.
- [x] Returning from Stripe portal lands on `/portal` correctly (test SPA routing).
- [x] Staging environment redirects to staging URL, not `raspucat.com` (verify `APP_URL` env var is set correctly per environment).
- [x] Stripe portal session URL expires after ~5 min — if user copies it and reuses it,
      Stripe returns a clean expired error (not our responsibility to handle).
