# 022_promo_codes

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

**Mode: STUDIO**

**Depends on:** `005_stripe_integration` (completed) — promo codes are applied to the Stripe PaymentIntent created in that flow.

---

## Overview

Allow clients to enter a Stripe promotion code during checkout. The code is validated server-side before the PaymentIntent is created. Valid codes reduce the **full setup fee** (not just the deposit) — the discount is split proportionally across the deposit and balance charges so the total discount is always applied correctly.

Promo codes are created and managed entirely in the Stripe Dashboard — no admin UI needed in the Flutter app.

---

## Discount Logic

| Item | Behaviour |
|:---|:---|
| Discount basis | Full setup fee (e.g. 10% off $3,500 = $350 saved) |
| Deposit | 50% of **discounted** setup total |
| Balance | Remaining 50% of discounted total |
| Subscription | Not discounted — management pricing is separate |

- Stripe `promotion_code` is validated via `stripe.promotionCodes.list({ code, active: true, limit: 1 })`.
- The resolved **promotion code ID** (not coupon ID) is passed to the PaymentIntent via `discounts: [{ promotion_code: promotionCodeId }]` — this ensures Stripe tracks redemption counts and respects `max_redemptions` limits.
- Stripe coupons are either **percentage-based** (`percent_off`) or **fixed-amount** (`amount_off`). Both must be handled:
  - Percentage: `discountAmt = floor(setupTotalCents * percent_off / 100)`
  - Fixed amount: `discountAmt = min(coupon.amount_off, setupTotalCents)` — cap at setup total
- Discount amount is returned to Flutter so the UI can show a savings line before payment.
- `setup_total_cents` stored on the quote is the **discounted total** — `charge-balance` reads this directly so the balance charge is always correct. Original pre-discount total is stored separately as `original_setup_total_cents` for admin reference.

---

## User Flow

```
[Step 3 — Payment]
      │
      ▼
┌─────────────────────────────────────────┐
│  STEP 4 — Payment                       │
│  ─────────────────────────────────────  │
│  Promo code   [______________] [Apply]  │
│               ✓ LAUNCH10 — 10% off      │
│                                         │
│  Order Summary                          │
│  ─ Setup total:        $3,500           │
│  ─ Promo (10%):       -$350             │
│  ─ Discounted total:   $3,150           │
│  ─ Due today (50%):    $1,575           │
│                                         │
│  [Stripe Payment Element]               │
└─────────────────────────────────────────┘
```

---

## Scope

### New Edge Function — `validate-promo-code`
- Accepts: `{ code: string, setupTotalCents: number }`
- Calls `stripe.promotionCodes.list({ code, active: true, limit: 1 })`
- Resolves coupon type and computes discount:
  - Percentage: `discountAmt = floor(setupTotalCents * percent_off / 100)`
  - Fixed amount: `discountAmt = min(amount_off, setupTotalCents)`
- Returns: `{ valid: bool, discountType: 'percent' | 'fixed', discountPct?: number, discountAmtCents: number, promotionCodeId: string }`
- Returns 400 if code not found or inactive

### Updated Edge Function — `create-payment-intent`
- Accepts new optional field: `promoCode?: string`
- If present, **re-validates server-side** (never trust client) — resolves `promotionCodeId`
- Applies discount: `discounts: [{ promotion_code: promotionCodeId }]` on PaymentIntent
- Stores **discounted total** as `setup_total_cents` on quote and original as `original_setup_total_cents`
- Recalculates `depositCents` from discounted setup total
- Returns `discountAmountCents` alongside existing `clientSecret` + `quoteId`

### Updated Edge Function — `charge-balance`
- No logic change needed — already reads `setup_total_cents` from the quote
- Since migration stores the discounted total there, balance charge is automatically correct

### Supabase Migration
- Add to `quotes` table:
  - `promo_code text` — the code string entered by the client
  - `discount_amount_cents int default 0`
  - `original_setup_total_cents int` — pre-discount total for admin reference

### Flutter — `configurator_state.dart`
- Add `RxString appliedPromoCode`, `RxInt promoDiscountCents`, `RxBool promoIsLoading`, `RxnString promoError`
- Add `applyPromoCode(String code)` — calls `validate-promo-code` with current `computedSetup`, updates state
- Add `clearPromoCode()` — resets all promo state
- **Changing plan, modules, or management option calls `clearPromoCode()`** — prevents stale discount against a different total
- `discountedSetup` getter: `computedSetup.value - promoDiscountCents.value`
- Pass `promoCode` to `createPaymentIntent()` body

### Flutter — `payment_step.dart`
- Add promo code input row above the Stripe element
- Apply button → calls `applyPromoCode()` with loading state
- Show success line (code + discount) when valid
- Show inline error when invalid/expired
- Show updated savings in `PriceSummaryBar`

---

## Acceptance Criteria

- [ ] Valid Stripe promo code reduces the full setup fee before deposit split
- [ ] Both percentage and fixed-amount coupons calculate correctly
- [ ] Invalid / expired code shows a clear inline error, does not block payment
- [ ] Promo code is re-validated in the Edge Function (client input never trusted)
- [ ] Stripe tracks redemption count via `promotion_code` ID (not raw coupon ID)
- [ ] Discount amount and code are stored on the quote record
- [ ] `original_setup_total_cents` preserves the pre-discount total on the quote
- [ ] Balance charge uses discounted total — client is never overcharged
- [ ] Changing plan/modules/management after applying a code clears the promo
- [ ] Removing an applied code resets all totals to original values
- [ ] Admin quote detail shows promo code and discount amount (read-only)
- [ ] No promo code entered = existing flow unchanged

---

## Out of Scope

- Admin UI for creating/managing promo codes (use Stripe Dashboard)
- Discounts on management subscriptions
- Multiple promo codes per order
