#!/bin/bash
# One-time script: creates Stripe products + prices for management plans.
# Usage: STRIPE_SECRET_KEY=sk_test_... bash setup-stripe-prices.sh

if [ -z "$STRIPE_SECRET_KEY" ]; then
  echo "❌  Set STRIPE_SECRET_KEY before running this script."
  exit 1
fi

STRIPE_VERSION="2026-01-28.clover"

stripe_post() {
  curl -s -X POST "https://api.stripe.com/v1$1" \
    -u "$STRIPE_SECRET_KEY:" \
    -H "Stripe-Version: $STRIPE_VERSION" \
    "${@:2}"
}

echo "Creating Stripe products and prices..."

# ── Standard Management ──────────────────────────────────────────────────────
STANDARD_PRODUCT=$(stripe_post /products \
  -d "name=Standard Management" \
  -d "description=Hosting & SSL, Supabase DB & Auth, domain management, platform updates, monthly stats digest, 1 hr content support.")
STANDARD_ID=$(echo "$STANDARD_PRODUCT" | grep -o '"id": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
echo "✅  Product: Standard Management ($STANDARD_ID)"

STANDARD_MONTHLY=$(stripe_post /prices \
  -d "product=$STANDARD_ID" \
  -d "unit_amount=14900" \
  -d "currency=usd" \
  -d "recurring[interval]=month" \
  -d "nickname=Standard — Monthly")
STANDARD_MONTHLY_ID=$(echo "$STANDARD_MONTHLY" | grep -o '"id": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
echo "✅  Price: Standard Monthly → $STANDARD_MONTHLY_ID"

STANDARD_ANNUAL=$(stripe_post /prices \
  -d "product=$STANDARD_ID" \
  -d "unit_amount=149000" \
  -d "currency=usd" \
  -d "recurring[interval]=year" \
  -d "nickname=Standard — Annual")
STANDARD_ANNUAL_ID=$(echo "$STANDARD_ANNUAL" | grep -o '"id": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
echo "✅  Price: Standard Annual  → $STANDARD_ANNUAL_ID"

# ── Premium Management ───────────────────────────────────────────────────────
PREMIUM_PRODUCT=$(stripe_post /products \
  -d "name=Premium Management" \
  -d "description=Everything in Standard plus priority support (< 4h response), monthly AI chatbot fine-tuning, advanced SEO tracking.")
PREMIUM_ID=$(echo "$PREMIUM_PRODUCT" | grep -o '"id": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
echo "✅  Product: Premium Management ($PREMIUM_ID)"

PREMIUM_MONTHLY=$(stripe_post /prices \
  -d "product=$PREMIUM_ID" \
  -d "unit_amount=29900" \
  -d "currency=usd" \
  -d "recurring[interval]=month" \
  -d "nickname=Premium — Monthly")
PREMIUM_MONTHLY_ID=$(echo "$PREMIUM_MONTHLY" | grep -o '"id": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
echo "✅  Price: Premium Monthly → $PREMIUM_MONTHLY_ID"

PREMIUM_ANNUAL=$(stripe_post /prices \
  -d "product=$PREMIUM_ID" \
  -d "unit_amount=299000" \
  -d "currency=usd" \
  -d "recurring[interval]=year" \
  -d "nickname=Premium — Annual")
PREMIUM_ANNUAL_ID=$(echo "$PREMIUM_ANNUAL" | grep -o '"id": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
echo "✅  Price: Premium Annual  → $PREMIUM_ANNUAL_ID"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Add these to Supabase Edge Function secrets:"
echo ""
echo "STRIPE_PRICE_STANDARD_MONTHLY=$STANDARD_MONTHLY_ID"
echo "STRIPE_PRICE_STANDARD_ANNUAL=$STANDARD_ANNUAL_ID"
echo "STRIPE_PRICE_PREMIUM_MONTHLY=$PREMIUM_MONTHLY_ID"
echo "STRIPE_PRICE_PREMIUM_ANNUAL=$PREMIUM_ANNUAL_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
