// Edge Function: validate-promo-code
// Validates a promo code using Stripe promotion codes + coupon metadata.
//
// Stripe coupon metadata fields:
//   applies_to: 'setup' | 'subscription' | 'both'  (default: 'both')
//   subscription_promo_code_id: Stripe promotion code ID for subscription portion
//     → Only needed when applies_to='both' AND the subscription discount differs from the setup discount.
//     → When omitted, the same promotion code is used for both setup and subscription.
//
// Response:
//   valid: true
//   appliesTo: 'setup' | 'subscription' | 'both'
//   discountAmtCents: number  (setup discount in cents; 0 if subscription-only)
//   discountPct: number | undefined
//   subscriptionDiscountPct: number | undefined
//   subscriptionDiscountFixed: number | undefined  (cents)
//   subscriptionDuration: 'once' | 'repeating' | 'forever' | undefined
//   subscriptionDurationMonths: number | undefined
//   promotionCodeId: string | undefined  (Stripe promo code ID to apply to subscription)

import Stripe from 'npm:stripe@14';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2026-01-28.clover',
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

/** Find a Stripe promotion code by its human-readable code string. */
async function findPromoByCode(code: string): Promise<{ promoCodeId: string; coupon: Stripe.Coupon } | null> {
  const results = await stripe.promotionCodes.list({
    code: code.toUpperCase(),
    active: true,
    limit: 1,
  });
  if (results.data.length === 0) return null;

  const promoRaw = results.data[0] as unknown as Record<string, unknown>;
  const couponId = extractCouponId(promoRaw);
  if (!couponId) return null;

  const coupon = await stripe.coupons.retrieve(couponId);
  return { promoCodeId: promoRaw['id'] as string, coupon };
}

/** Retrieve a promotion code directly by its Stripe ID. */
async function getPromoById(id: string): Promise<{ promoCodeId: string; coupon: Stripe.Coupon } | null> {
  try {
    const promoRaw = await (stripe.promotionCodes as unknown as {
      retrieve: (id: string) => Promise<unknown>;
    }).retrieve(id) as Record<string, unknown>;

    const couponId = extractCouponId(promoRaw);
    if (!couponId) return null;

    const coupon = await stripe.coupons.retrieve(couponId);
    return { promoCodeId: id, coupon };
  } catch {
    return null;
  }
}

/**
 * Extract coupon ID from a promotion code raw object.
 * Stripe 2026-01-28.clover: coupon lives under promotion.coupon (ID string).
 * Older: coupon is top-level expanded object or ID string.
 */
function extractCouponId(promoRaw: Record<string, unknown>): string | null {
  const promotion = promoRaw['promotion'] as Record<string, unknown> | undefined;
  if (promotion?.['coupon'] && typeof promotion['coupon'] === 'string') {
    return promotion['coupon'];
  }
  const topLevel = promoRaw['coupon'];
  if (typeof topLevel === 'string') return topLevel;
  if (topLevel && typeof topLevel === 'object') {
    return (topLevel as Record<string, unknown>)['id'] as string ?? null;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { code, setupTotalCents } = await req.json();

    if (!code || typeof setupTotalCents !== 'number' || setupTotalCents <= 0) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Look up Stripe promotion code ─────────────────────────────────────────
    const result = await findPromoByCode(String(code));
    if (!result) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired promo code.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const { promoCodeId, coupon } = result;

    // ── Read metadata ─────────────────────────────────────────────────────────
    const appliesTo = (coupon.metadata?.applies_to as 'setup' | 'subscription' | 'both' | undefined) ?? 'both';
    const subscriptionPromoCodeId = coupon.metadata?.subscription_promo_code_id as string | undefined;

    // ── Setup discount ────────────────────────────────────────────────────────
    let discountAmtCents = 0;
    let discountPct: number | undefined;

    if (appliesTo === 'setup' || appliesTo === 'both') {
      if (coupon.percent_off != null) {
        discountPct = coupon.percent_off;
        discountAmtCents = Math.floor(setupTotalCents * coupon.percent_off / 100);
      } else if (coupon.amount_off != null) {
        discountAmtCents = Math.min(coupon.amount_off, setupTotalCents);
      }
    }

    // ── Subscription discount ─────────────────────────────────────────────────
    let subscriptionDiscountPct: number | undefined;
    let subscriptionDiscountFixed: number | undefined;
    let subscriptionDuration: string | undefined;
    let subscriptionDurationMonths: number | undefined;
    let outPromoCodeId: string | undefined;

    if (appliesTo === 'subscription' || appliesTo === 'both') {
      let subCoupon: Stripe.Coupon = coupon;
      outPromoCodeId = promoCodeId;

      // If a separate subscription promo code is specified, use it instead
      if (subscriptionPromoCodeId) {
        const subResult = await getPromoById(subscriptionPromoCodeId);
        if (subResult) {
          subCoupon = subResult.coupon;
          outPromoCodeId = subResult.promoCodeId;
        }
      }

      subscriptionDuration = subCoupon.duration ?? undefined;
      subscriptionDurationMonths = subCoupon.duration_in_months ?? undefined;

      if (subCoupon.percent_off != null) {
        subscriptionDiscountPct = subCoupon.percent_off;
      } else if (subCoupon.amount_off != null) {
        subscriptionDiscountFixed = subCoupon.amount_off;
      }
    }

    return new Response(JSON.stringify({
      valid: true,
      appliesTo,
      discountAmtCents,
      discountPct,
      subscriptionDiscountPct,
      subscriptionDiscountFixed,
      subscriptionDuration,
      subscriptionDurationMonths,
      promotionCodeId: outPromoCodeId,
    }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  } catch (err) {
    console.error('validate-promo-code error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
