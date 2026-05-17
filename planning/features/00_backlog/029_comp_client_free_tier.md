# 029_comp_client_free_tier

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

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

- [ ] Admin quote form has a "Comp this project" toggle (admin UI only, no client-facing label)
- [ ] When toggled on, all monetary fields (setup fee, deposit, balance) display as $0.00 and are read-only
- [ ] Comped quote is persisted with `is_comped = true` and all cents fields = 0
- [ ] Client-facing deposit step is skipped (no payment prompt) when `is_comped = true`
- [ ] "Start Subscription" on a comped quote sets `status = 'active'` and `subscription_started_at = now()` with zero Stripe API calls
- [ ] No Stripe customer or subscription record is created for comped quotes
- [ ] Non-comped quotes are unaffected — full Stripe flow continues to work exactly as before
- [ ] `is_comped` cannot be set by the Flutter client — only via `adminToken`-authenticated Edge Function
- [ ] All new files stay under 300 lines

---

## Architecture

### DB Migration
```sql
-- supabase/migrations/YYYYMMDDHHMMSS_add_is_comped_to_quotes.sql
ALTER TABLE public.quotes
  ADD COLUMN is_comped BOOLEAN NOT NULL DEFAULT FALSE;

-- rollback: ALTER TABLE public.quotes DROP COLUMN is_comped;
```

### Edge Function: `admin-create-quote`
- Accept `isComped: boolean` in request body
- When `isComped = true`: force `setup_total_cents = 0`, `deposit_cents = 0`, `balance_cents = 0`
- Persist `is_comped = true` on the row

### Edge Function: `start-subscription`
```typescript
// Top of function, after fetching quote:
if (quote.is_comped) {
  await supabase.from('quotes').update({
    status: 'active',
    subscription_started_at: new Date().toISOString(),
  }).eq('id', quoteId);
  return new Response(JSON.stringify({ comped: true }), { status: 200 });
}
// ... existing Stripe logic unchanged below
```

### Flutter Changes
- `lib/app/modules/widgets/admin_quote_form_body.dart` — add `SwitchListTile` for comp toggle; grey out price fields when active
- `lib/app/controllers/admin_catalog_controller.dart` — pass `isComped` to Edge Function call
- `QuoteModel` — add `isComped` field, wire to `fromJson` / `toJson`
- Client deposit screen — guard payment step: `if (!quote.isComped) showPaymentStep()`

---

## Design Decisions

| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Stripe bypass vs $0 products | Bypass entirely | Avoids $0 invoice noise, unnecessary Stripe records |
| Access control for comped flag | adminToken Edge Function only | Prevents client from self-comping |
| Partial comp (e.g., $0 setup, paid subscription) | Not supported | YAGNI — full comp or full pay |
| Client visibility of comp status | Hidden (admin-only) | No reason to surface this to clients |
| Active gate field | `status = 'active'` | Not `stripe_subscription_id IS NOT NULL` |

---

## Scope Control

- [x] **Included:** `is_comped` DB column + migration
- [x] **Included:** Admin quote form toggle with zeroed-out price fields
- [x] **Included:** `admin-create-quote` Edge Function update
- [x] **Included:** `start-subscription` Stripe bypass for comped quotes
- [x] **Included:** Client deposit flow guard
- [x] **Included:** `QuoteModel.isComped` field
- [ ] **NOT Included:** Client-facing "comped" label or UI
- [ ] **NOT Included:** Partial comp (mixed free/paid)
- [ ] **NOT Included:** Retroactively comping existing paid quotes
- [ ] **NOT Included:** $0 Stripe products or subscriptions

---

## Dependencies
- `supabase/migrations/20260318000001_quotes.sql` — base quotes schema (already shipped)
- `supabase/functions/admin-create-quote/index.ts` — extend, don't replace
- `supabase/functions/start-subscription/index.ts` — extend, don't replace
- `lib/app/modules/widgets/admin_quote_form_body.dart` — widget to extend
- `lib/app/controllers/admin_catalog_controller.dart` — controller to extend

---

## Verification
1. Create a comp quote in admin — verify `is_comped = true` and all cents = 0 in DB
2. Open client portal for comped quote — verify deposit step is skipped
3. Admin hits "Start Subscription" on comped quote — verify no Stripe API calls (check Stripe dashboard), `status = 'active'` in DB
4. Create a normal paid quote — verify full Stripe checkout + subscription flow is unaffected
