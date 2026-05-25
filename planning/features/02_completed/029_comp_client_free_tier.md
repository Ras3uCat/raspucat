# 029_comp_client_free_tier

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

**Mode:** STUDIO

---

## Overview

Add an admin-only "Comp this project" toggle to the new-client quote creation flow. When enabled,
all billing amounts are set to $0.00 and the Stripe payment pipeline is bypassed entirely.
Designed for Ryan's internal side projects — no client-facing UI changes.

**Stripe decision:** Bypass Stripe completely for comped quotes. Do NOT create $0 Stripe products
or subscriptions. Stripe's "webhook as source of truth" rule is an untrusted-client protection;
admin-comped projects are a trusted override. `status = 'active'` (not `stripe_subscription_id`)
is the gate for site-live state.

---

## User Stories
- As admin, I want to toggle "Comp this project" when creating a quote so all fees are $0
  and I never get prompted to pay.
- As admin, I want to start a subscription on a comped quote and have it go active immediately
  with no Stripe interaction.

---

## Acceptance Criteria

- [x] Admin quote form has a "Comp this project" toggle (admin UI only, no client-facing label)
- [x] When toggled on, all monetary fields (setup fee, deposit, balance) display as $0.00 and are read-only
- [x] Comped quote is persisted with `is_comped = true` and all cents fields = 0
- [x] Client-facing deposit step is skipped (no payment prompt) when `is_comped = true`
- [x] "Start Subscription" on a comped quote sets `status = 'active'` and `subscription_started_at = now()` with zero Stripe API calls
- [x] No Stripe customer or subscription record is created for comped quotes
- [x] Non-comped quotes are unaffected — full Stripe flow continues to work exactly as before
- [x] `is_comped` cannot be set by the Flutter client — only via `adminToken`-authenticated Edge Function
- [x] All new files stay under 300 lines

---

## Architecture

### DB Migration
```sql
-- supabase/migrations/YYYYMMDDHHMMSS_add_is_comped_to_quotes.sql
-- NOTE: Replace YYYYMMDDHHMMSS with actual timestamp before running.

-- Add 'active' to quote_status enum (used as the site-live gate for comped projects).
-- The existing enum is: pending | deposit_paid | fully_paid | cancelled
ALTER TYPE quote_status ADD VALUE IF NOT EXISTS 'active';

ALTER TABLE public.quotes
  ADD COLUMN is_comped BOOLEAN NOT NULL DEFAULT FALSE;

-- rollback: ALTER TABLE public.quotes DROP COLUMN is_comped;
-- rollback note: enum values cannot be removed in Postgres without a full type rebuild.
```

### Edge Function: `admin-create-quote`
- Accept `isComped: boolean` in request body
- When `isComped = true`: force `setup_total_cents = 0`, `deposit_cents = 0`, `balance_cents = 0`
- Persist `is_comped = true` on the row
- Guard `setupTotalCents` validation to allow 0 for comped quotes:
  ```typescript
  if (!isComped && setupTotalCents <= 0) throw new Error('setupTotalCents required');
  ```

### Edge Function: `start-subscription`
```typescript
// Top of function, after fetching quote:
if (quote.is_comped) {
  await supabase.from('quotes').update({
    status: 'active',
    subscription_started_at: new Date().toISOString(),
  }).eq('id', quoteId);

  // Log audit event — matches existing pattern for non-comped activations.
  await supabase.from('quote_events').insert({
    quote_id: quoteId,
    event_type: 'quote_comped_activated',
  });

  // No client/owner email sent for comped activations (internal side projects only).
  return new Response(JSON.stringify({ comped: true }), { status: 200 });
}
// ... existing Stripe logic unchanged below
```

### Flutter Changes
- `lib/app/modules/widgets/admin_quote_form_body.dart` — extract comp toggle into `_comp_toggle_section.dart` before adding (file is at 240 lines; adding inline will breach 300-line limit)
- `lib/app/modules/widgets/_comp_toggle_section.dart` *(new)* — `SwitchListTile` for comp toggle; greys out price fields when active
- `lib/app/controllers/admin_catalog_controller.dart` — pass `isComped` to Edge Function call
- `QuoteModel` — add `bool isComped = false` field, wire to `fromJson` / `toJson`
- `lib/app/modules/widgets/payment_step.dart` — guard deposit step: `if (!quote.isComped) showPaymentStep()`

---

## Design Decisions

| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Stripe bypass vs $0 products | Bypass entirely | Avoids $0 invoice noise, unnecessary Stripe records |
| Access control for comped flag | adminToken Edge Function only | Prevents client from self-comping |
| Partial comp (e.g., $0 setup, paid subscription) | Not supported | YAGNI — full comp or full pay |
| Client visibility of comp status | Hidden (admin-only) | No reason to surface this to clients |
| Active gate field | `status = 'active'` | Not `stripe_subscription_id IS NOT NULL`; `'active'` added to enum via migration |
| `billing_cycle` for comped quotes | Any value accepted | `start-subscription` early-returns before Price ID lookup; no Stripe call regardless of billing_cycle |
| Email on comped activation | None | Internal side projects only; no client-facing notification needed |

---

## Scope Control

- [x] **Included:** `is_comped` DB column + `'active'` enum value — migration
- [x] **Included:** Admin quote form toggle (`_comp_toggle_section.dart` extraction)
- [x] **Included:** `admin-create-quote` Edge Function update + `setupTotalCents` validation bypass
- [x] **Included:** `start-subscription` Stripe bypass + `quote_comped_activated` event log
- [x] **Included:** `payment_step.dart` deposit flow guard
- [x] **Included:** `QuoteModel.isComped` field (`bool`, default `false`)
- [x] **Included:** Test — `test/app/modules/widgets/admin_quote_form_body_test.dart` (comp toggle behavior)
- [x] **Included:** Test — Edge Function integration scenario for comped activation path
- [ ] **NOT Included:** Client-facing "comped" label or UI
- [ ] **NOT Included:** Partial comp (mixed free/paid)
- [ ] **NOT Included:** Retroactively comping existing paid quotes
- [ ] **NOT Included:** $0 Stripe products or subscriptions

---

## Dependencies
- `supabase/migrations/20260318000001_quotes.sql` — base quotes schema (already shipped)
- `supabase/functions/admin-create-quote/index.ts` — extend, don't replace
- `supabase/functions/start-subscription/index.ts` — extend, don't replace
- `lib/app/modules/widgets/admin_quote_form_body.dart` — refactor + extend (extract comp section first)
- `lib/app/modules/widgets/_comp_toggle_section.dart` — new file
- `lib/app/modules/widgets/payment_step.dart` — add `isComped` guard
- `lib/app/controllers/admin_catalog_controller.dart` — controller to extend
- `test/app/modules/widgets/admin_quote_form_body_test.dart` — new test file
- Edge Function integration test (comped activation path)

---

## Verification
1. Create a comp quote in admin — verify `is_comped = true` and all cents = 0 in DB
2. Open client portal for comped quote — verify deposit step (`payment_step.dart`) is skipped
3. Admin hits "Start Subscription" on comped quote — verify no Stripe API calls (check Stripe dashboard), `status = 'active'` in DB, and `quote_comped_activated` event logged
4. Create a normal paid quote — verify full Stripe checkout + subscription flow is unaffected
5. **Security:** Attempt to set `is_comped = true` directly via Supabase Flutter client SDK (no service_role key) — verify the write is rejected by RLS
