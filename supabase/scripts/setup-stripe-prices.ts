// One-time script: creates Stripe products + prices for management plans.
// Run with: deno run --allow-net --allow-env setup-stripe-prices.ts
// Or:       STRIPE_SECRET_KEY=sk_test_... deno run --allow-net --allow-env setup-stripe-prices.ts

const secretKey = Deno.env.get('STRIPE_SECRET_KEY');
if (!secretKey) {
  console.error('❌  Set STRIPE_SECRET_KEY before running this script.');
  Deno.exit(1);
}

async function stripePost(path: string, params: Record<string, string>): Promise<Record<string, unknown>> {
  const body = new URLSearchParams(params);
  const res = await fetch(`https://api.stripe.com/v1${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${secretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      'Stripe-Version': '2026-01-28.clover',
    },
    body: body.toString(),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`Stripe error on ${path}: ${JSON.stringify(json)}`);
  return json as Record<string, unknown>;
}

console.log('Creating Stripe products and prices...\n');

// ── Standard Management ──────────────────────────────────────────────────────
const standard = await stripePost('/products', {
  name: 'Standard Management',
  description: 'Hosting & SSL, Supabase DB & Auth, domain management, platform updates, monthly stats digest, 1 hr content support.',
});
const standardId = standard.id as string;
console.log(`✅  Product: Standard Management (${standardId})`);

const standardMonthly = await stripePost('/prices', {
  product: standardId,
  unit_amount: '14900',   // $149.00
  currency: 'usd',
  'recurring[interval]': 'month',
  nickname: 'Standard — Monthly',
});
console.log(`✅  Price: Standard Monthly → ${standardMonthly.id}`);

const standardAnnual = await stripePost('/prices', {
  product: standardId,
  unit_amount: '149000',  // $1,490.00/yr
  currency: 'usd',
  'recurring[interval]': 'year',
  nickname: 'Standard — Annual',
});
console.log(`✅  Price: Standard Annual  → ${standardAnnual.id}`);

// ── Premium Management ───────────────────────────────────────────────────────
const premium = await stripePost('/products', {
  name: 'Premium Management',
  description: 'Everything in Standard plus priority support (< 4h response), monthly AI chatbot fine-tuning, advanced SEO tracking.',
});
const premiumId = premium.id as string;
console.log(`\n✅  Product: Premium Management (${premiumId})`);

const premiumMonthly = await stripePost('/prices', {
  product: premiumId,
  unit_amount: '29900',   // $299.00
  currency: 'usd',
  'recurring[interval]': 'month',
  nickname: 'Premium — Monthly',
});
console.log(`✅  Price: Premium Monthly → ${premiumMonthly.id}`);

const premiumAnnual = await stripePost('/prices', {
  product: premiumId,
  unit_amount: '299000',  // $2,990.00/yr
  currency: 'usd',
  'recurring[interval]': 'year',
  nickname: 'Premium — Annual',
});
console.log(`✅  Price: Premium Annual  → ${premiumAnnual.id}`);

// ── Summary ──────────────────────────────────────────────────────────────────
console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Add these to Supabase Edge Function secrets:

STRIPE_PRICE_STANDARD_MONTHLY=${standardMonthly.id}
STRIPE_PRICE_STANDARD_ANNUAL=${standardAnnual.id}
STRIPE_PRICE_PREMIUM_MONTHLY=${premiumMonthly.id}
STRIPE_PRICE_PREMIUM_ANNUAL=${premiumAnnual.id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`);
