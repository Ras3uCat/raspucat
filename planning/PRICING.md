# Pricing & Product Strategy

Our pricing follows a **Base + Configurator** model. Every plan starts from the same foundation and opens an interactive add-on dialog. Pro and Premium are curated presets with a bundle discount applied — Custom is fully open with a volume discount that grows as you add more.

---

## The Base (Included in Every Plan)

**Core Site + CRM/Lead Gen — $1,200 setup**
- Hero, Services, About & FAQ pages
- Contact form + basic lead capture
- Mobile-responsive, SEO-ready

This is the minimum viable product. Everything below is additive.

---

## Plan Overview

| | **Pro (Launchpad)** | **⭐ Premium (Engine)** | **Custom (Build Your Own)** |
|:---|:---:|:---:|:---:|
| **Ideal For** | Solopreneurs & Startups | Service & Retail SMBs | Franchises, Power Users & High-Growth |
| **Preset Modules** | ✅ Pre-selected & locked | ✅ Pre-selected & locked | None — fully open |
| **Bundle Discount** | ~12% off a la carte | ~18% off a la carte | — |
| **Volume Discount** | — | — | Up to 15% (see below) |
| **Setup Price** | **$2,200** *(save ~$300)* | **$3,500** *(save ~$750)* | **From $1,200 + add-ons** |
| **Monthly** | $149/mo management | $149/mo management | $149/mo management |

> **⭐ Most Popular** — Premium (Engine) is the sweet spot for established service businesses ready to take bookings, payments, and client retention seriously.

---

## What's Pre-Selected Per Plan

### Pro (Launchpad) — Preset Modules
- Blog & Gallery
- Online Booking / Shop
- Stripe Integration

*A la carte value: ~$2,500 → Bundle price: $2,200*

### ⭐ Premium (Engine) — Preset Modules
- Blog & Gallery
- Online Booking / Shop
- Stripe Integration
- Tip/Gratuity at Checkout
- PWA Push Notifications
- Monthly Stats Digest
- AI Chatbot (Lite)

*A la carte value: ~$4,250 → Bundle price: $3,500*

> For both Pro and Premium, pre-selected modules are **locked in the dialog** and cannot be deselected. Additional add-ons can be toggled freely — price updates live.

---

## Add-On & Module Catalog

These are the individual modules available in the configurator. Prices shown are **a la carte (Custom)** rates.

| Module | Price |
|:---|:---:|
| Blog & Gallery | $400 |
| Online Booking / Shop | $600 |
| Stripe Integration | $300 |
| Tip/Gratuity at Checkout | $200 |
| PWA Push Notifications *(home screen, no App Store)* | $400 |
| Monthly Stats Digest *(branded PDF: revenue, top services, growth)* | $300 |
| AI Chatbot — Lite *(FAQ, hours, pricing Q&A)* | $500 |
| AI Chatbot — Full *(custom-trained, fine-tuned monthly)* | $800 *(upgrade from Lite)* |
| Automated PDF Invoices | $400 |
| Multi-location Support | $900 |
| Native Mobile Apps *(iOS/Android, App Store presence)* | $3,500 |
| Stripe Connect *(multi-staff payouts)* | $700 |
| SMS Reminders *(Twilio)* | $400 + usage |
| Loyalty & Referrals | $600 |
| Google Reviews Auto-Sync | $350 |
| Custom Menu/Pricing Module | $450 |
| Gated Video/Course Content | $1,500+ |

---

## Custom Plan — Volume Discount Tiers

The more you build, the better your rate. Discount applies to total add-on cost (not the base).

| Add-ons Selected | Discount |
|:---|:---:|
| 0 – 2 | 0% |
| 3 – 5 | 5% off |
| 6 – 8 | 10% off |
| 9+ | 15% off |

---

## The Configurator Dialog (All Plans)

Every plan opens the same interactive dialog:
- **Pro / Premium:** Preset modules shown as checked and locked. Optional add-ons are toggleable.
- **Custom:** All modules start unchecked. Full freedom to build.
- Prices displayed next to each module.
- **Total updates live** with every toggle.
- Discount badge shown dynamically (bundle % for Pro/Premium, volume tier for Custom).

---

## Step 2 — Management Plan

After the build is configured, clients choose how the site is maintained. Management is the default path — handover is available as a paid option.

**Standard Management: $149/mo** *(or $1,490/yr — save $298)*
- Hosting & SSL
- Supabase Database & Auth
- Domain Management
- Platform license & infrastructure updates
- Monthly Stats Digest email
- 1 hour of content updates/support

**Premium Management: $299/mo** *(or $2,990/yr — save $598)*
- All Standard features
- Priority support (under 4h response)
- Monthly AI Chatbot fine-tuning
- Advanced SEO tracking & reporting

**Handover & Documentation: $400 one-time** *(self-manage option)*
- Full deployment to client's own infrastructure
- Credential & access transfer
- Technical documentation package
- 1 onboarding call
- No ongoing monthly fee after handover

---

## High-Value Differentiators

### 1. The "Tip" Engine
One-click tip selector before checkout. A favorite for salons and spas — often pays for the site itself in extra gratuities.

### 2. AI Business Concierge
- **Lite:** Pre-loaded with your FAQ, hours, and service list. Handles the "Are you open?" questions 24/7.
- **Full:** Deeply trained on your business data and tone. Fine-tuned monthly. Reduces admin load by up to 40%.

### 3. PWA vs. Native Mobile Apps
- **PWA:** Zero App Store friction. Home screen install + push notifications for booking reminders and promos.
- **Native Apps:** Full iOS/Android App Store presence, deep device integration, offline support. Best for franchises or high-volume client bases.

### 4. Monthly Stats Digest
Most SMBs don't know which services drive the most revenue. This branded monthly PDF — showing revenue trends, top services, and growth metrics — is what justifies the management fee and keeps clients retained long-term.

---

## Promo Codes — How to Create & Manage

All promo codes are created and managed entirely in **Stripe**. Raspucat reads Stripe coupon metadata to determine how a code behaves — no Supabase table entries needed.

### How It Works

Raspucat supports three promo code types, controlled by a single metadata field on the Stripe coupon:

| `applies_to` metadata value | Effect |
|:---|:---|
| `both` (or not set) | Discounts the setup fee **and** applies to the recurring subscription |
| `setup` | Discounts the setup fee only — subscription is full price |
| `subscription` | No setup discount — subscription gets the discount only |

### Creating a Promo Code in Stripe

1. Go to **Stripe Dashboard → Product Catalog → Coupons → + New coupon**
2. Set your discount:
   - **Percentage** (e.g. 95% off) or **Fixed amount** (e.g. $200 off)
   - Duration: **Forever**, **Once**, or **Repeating** (if subscription applies)
3. Under **Metadata**, add:
   ```
   applies_to = both
   ```
   (or `setup` or `subscription` as needed — omit this key to default to `both`)
4. Save the coupon → copy its **Coupon ID**
5. Go to **Stripe Dashboard → Product Catalog → Promotion codes → + New promotion code**
6. Select the coupon you just created
7. Set the **Code** (e.g. `LAUNCH50`, `TEST95`)
8. Toggle **Active** on, optionally set a redemption limit or expiry
9. Save

That's it. The code is live and Raspucat will pick it up automatically.

### Both Discounts, Different Amounts

If you need the setup discount and the subscription discount to be **different values** (e.g. $200 off setup + 20% off subscription forever):

1. Create **two separate Stripe coupons** — one for setup, one for subscription
2. Create a **promotion code** on the setup coupon (this is the code clients enter)
3. Create a **promotion code** on the subscription coupon (this is internal-only — clients never see it)
4. On the **setup coupon**, add metadata:
   ```
   applies_to = both
   subscription_promo_code_id = promo_XXXXXXXXXX
   ```
   (replace with the Stripe promotion code ID from step 3 — starts with `promo_`)

When a client redeems the code:
- The setup coupon's discount is applied to the one-time setup fee
- The subscription promotion code is stored and applied automatically when their subscription is created at launch

### Quick Reference

| Scenario | Coupon `applies_to` | `subscription_promo_code_id` needed? |
|:---|:---:|:---:|
| Full discount on everything (same %) | `both` (or omit) | No |
| Setup fee discount only | `setup` | No |
| Subscription discount only | `subscription` | No |
| Different amounts for setup + subscription | `both` | Yes |
