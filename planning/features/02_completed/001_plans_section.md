# 001_plans_section

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

**Mode: STUDIO**

---

## Overview
Add a **PLANS** section to the Raspucat portfolio site. This section showcases three service tiers —
**Pro**, **Premium**, and **Custom** — styled in the site's existing neon/cyberpunk aesthetic.
The goal is to convert portfolio visitors into clients by presenting clear pricing and feature differentiation.

All three plans use the same **Base + Configurator** model. Pro and Premium are curated presets
(modules pre-selected and locked). Custom is a fully open configurator. Every plan opens the same
full-screen overlay configurator — the difference is what's pre-checked on entry.

Reference design: `ChatGPT Image Feb 19, 2026, 10_29_18 AM.png`

---

## Pricing Reference
See `planning/PRICING.md` for the full source of truth. Summary:

| Plan | Setup Price | Bundle Savings | Monthly |
|:---|:---:|:---:|:---:|
| Pro (Launchpad) | $2,200 | ~$300 off a la carte | $149/mo |
| ⭐ Premium (Engine) | $3,500 | ~$750 off a la carte | $149/mo |
| Custom (Build Your Own) | From $1,200 + add-ons | Volume discount up to 15% | $149/mo |

- Management ($149/mo or $299/mo) is selected in **Step 2** of the configurator.
- Handover & Documentation ($400 one-time) is a self-manage alternative to monthly management.

---

## User Stories
- As a visitor, I want to see available service tiers so I can understand the pricing model at a glance.
- As a visitor, I want to click into a plan and configure my own feature set so I know exactly what I'm paying for.
- As a visitor, I want to see the price update live as I toggle features so I feel in control of my budget.
- As a visitor, I want to choose a management plan after configuring my build so the total cost of ownership is clear.
- As a visitor using Pro or Premium, I want to see what's included in my preset so I understand the bundle value.

---

## Acceptance Criteria (Binary Pass/Fail)

### Plan Cards
- [ ] PLANS section is visible on the home page as a named scroll section.
- [ ] Three tier cards render: Pro, Premium, Custom.
- [ ] Premium card is visually highlighted (neon glow border) as the recommended tier.
- [ ] Each card shows: tier name, setup price, bundle savings (Pro/Premium) or "Build Your Own" (Custom), monthly price, and "Select Plan" CTA.
- [ ] Cards are responsive — stacked vertically on mobile, row on desktop.
- [ ] All colors, typography, and effects use existing `EColors`, `EAppTheme`, and site widgets.

### Configurator Overlay (Step 1 — Modules)
- [ ] Clicking "Select Plan" on any card opens a full-screen overlay configurator.
- [ ] Overlay renders a list of all available modules with name, description, and a la carte price.
- [ ] Pro/Premium: preset modules render as checked and non-toggleable (locked).
- [ ] Custom: all modules start unchecked and are freely toggleable.
- [ ] Live price counter at the bottom updates on every toggle.
- [ ] Volume discount badge (Custom only) updates dynamically based on add-on count.
- [ ] Bundle savings badge (Pro/Premium) is shown statically.
- [ ] "Continue" CTA proceeds to Step 2.
- [ ] Overlay is dismissible (back button / swipe / close icon).

### Management Step (Step 2 — Ongoing Support)
- [ ] After Step 1, a Step 2 screen renders within the same overlay.
- [ ] Three options shown: Standard Management ($149/mo), Premium Management ($299/mo), Handover & Documentation ($400 one-time).
- [ ] Annual pricing shown as an alternative with savings called out.
- [ ] Selecting an option updates the total shown.
- [ ] "Get a Quote" CTA on Step 2 opens contact (mailto or contact form).
- [ ] "Back" returns to Step 1 without losing module selections.

---

## Design Decisions

| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Tier count | 3 (Pro, Premium, Custom) | No Basic tier per owner direction |
| Featured tier | Premium | Highest value preset — best fit for established SMBs |
| Configurator UX | Full-screen overlay (not centered dialog) | Dialog is too cramped for 17+ modules; overlay gives room to breathe while keeping the focused/intentional feel |
| Two-step flow | Step 1: modules / Step 2: management | Setup fee and recurring cost are different buying decisions — keeps each step cognitively clean |
| Custom entry state | All modules unchecked | Honest starting point — client builds from scratch |
| Pro/Premium entry state | Preset modules checked & locked | Communicates bundle value, prevents stripping below bundle floor |
| Discount display | Badge on live price counter | Makes savings tangible and visible as client configures |
| Management default | $149/mo shown on card | Anchors recurring expectation upfront; handover is an opt-in alternative |
| Layout | `Row` on desktop, `Column` on mobile | Matches reference image; responsive via `EDevice` breakpoints |

---

## Scope Control
- [x] **Included:** Three plan cards with live pricing and "Select Plan" CTA.
- [x] **Included:** Full-screen overlay configurator with toggleable modules.
- [x] **Included:** Step 1 (module selection) and Step 2 (management plan).
- [x] **Included:** Live price counter with dynamic discount badge.
- [x] **Included:** Preset locked modules for Pro and Premium.
- [x] **Included:** Neon glow effect on Premium card (featured).
- [x] **Included:** Responsive layout (desktop row / mobile column).
- [ ] **NOT Included:** Stripe payment integration (separate feature).
- [ ] **NOT Included:** Auth or account creation flow.
- [x] **Included:** Supabase backend — `modules`, `management_options`, `plans` tables with RLS.
- [x] **Included:** Repository pattern (`PlanRepository`) fetching live data via `supabase_flutter`.
- [x] **Included:** `.env` / `flutter_dotenv` for credentials.
- [ ] **NOT Included:** Quote submission backend (mailto CTA only for MVP).

---

## UX & UI Design

**Visual Reference:** Cyberpunk pricing grid — dark `#000612` background, `#58E3EF` cyan accents,
neon glow border on the featured Premium card, triangle decorations matching site motif.

### Flow

```
[PLANS Section]
      │
      ▼
[User clicks "Select Plan" on any card]
      │
      ▼
┌─────────────────────────────────────────┐
│  STEP 1 — Configure Your Build          │
│  ─────────────────────────────────────  │
│  [Module list with toggles + prices]    │
│                                         │
│  Pro/Premium: preset modules locked ✅  │
│  Custom: all modules open               │
│                                         │
│  ┌────────────────────────────────┐     │
│  │ 💰 Total: $X,XXX               │     │
│  │ 🏷 Saving $XXX (bundle/volume) │     │
│  └────────────────────────────────┘     │
│                                         │
│  [Continue →]              [✕ Close]   │
└─────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│  STEP 2 — Choose Your Support Plan      │
│  ─────────────────────────────────────  │
│  ○ Standard Management  $149/mo         │
│    ($1,490/yr — save $298)              │
│                                         │
│  ○ Premium Management   $299/mo         │
│    ($2,990/yr — save $598)              │
│                                         │
│  ○ Handover & Docs      $400 one-time   │
│    (self-manage, no monthly fee)        │
│                                         │
│  ┌────────────────────────────────┐     │
│  │ 💰 Setup: $X,XXX               │     │
│  │ 📅 Monthly: $XXX/mo            │     │
│  └────────────────────────────────┘     │
│                                         │
│  [← Back]          [Get a Quote →]     │
└─────────────────────────────────────────┘
      │
      ▼
[mailto:meow@raspucat.com or contact form]
```

**Widgets (reuse existing where possible):**
- `SectionContainer` — wraps the PLANS section.
- `NeonText` — section heading "PLANS".
- `NeonButton` — "Select Plan", "Continue", "Get a Quote" CTAs.
- `PlanCard` (**exists** — modify CTA + card content only).
- `PlansScreen` (**exists** — no structural changes needed).
- `PlanConfiguratorOverlay` (**new**) — full-screen overlay managing both steps.
- `ModuleToggleTile` (**new**) — individual module row with toggle, description, and price.
- `PriceSummaryBar` (**new**) — sticky bottom bar showing live total + discount badge.
- Triangle decorators — reuse existing triangle painter/widget from the site.

---

## Data Model

### Existing — `PlanModel` (needs new fields added)

```dart
// CURRENT fields (do not remove):
final String id;
final String name;
final String label;
final String price;        // display string e.g. '$2,200'
final String idealFor;
final List<String> features;
final bool isFeatured;
final bool isCustom;

// ADD these fields:
final String monthlyPrice;       // e.g. '$149/mo'
final String? bundleSavings;     // e.g. 'Save ~$300' — null for Custom
final List<String> lockedModuleIds; // preset module IDs locked in configurator
```

### New Models

```dart
// module_model.dart
class ModuleModel {
  final String id;
  final String name;
  final String description;
  final int price;           // a la carte base price in dollars
  final String? priceNote;   // e.g. '+ usage' or '+' for variable pricing; shown as footnote
  final String? upgradeOf;   // id of the module this upgrades (e.g. 'ai_chatbot_lite'); null if standalone
}

// management_option_model.dart
class ManagementOptionModel {
  final String id;           // 'standard' | 'premium' | 'handover'
  final String name;
  final String description;
  final int monthlyPrice;    // 0 for handover
  final int annualPrice;     // 0 for handover
  final int onetimePrice;    // 0 for management plans
}
```

---

## Implementation Files

### Modify (existing — do not rewrite, targeted changes only)

| File | What Changes |
|:---|:---|
| `lib/app/data/models/plan_model.dart` | Add `monthlyPrice`, `bundleSavings`, `lockedModuleIds` fields |
| `lib/app/data/projects/plan_data.dart` | Update all prices, features, `isFeatured` → Premium, add new field values |
| `lib/app/modules/widgets/plan_card.dart` | Add monthly price + savings badge to `_PlanCardContent`; update `onCta` to open `PlanConfiguratorOverlay` instead of `mailto:` |

### Create (new files)

| File | Purpose |
|:---|:---|
| `lib/app/modules/widgets/plan_configurator_overlay.dart` | Full-screen overlay, manages Step 1 / Step 2 state |
| `lib/app/modules/widgets/module_toggle_tile.dart` | Individual module row with toggle, name, description, price |
| `lib/app/modules/widgets/price_summary_bar.dart` | Sticky bottom bar — live total + discount badge |
| `lib/app/data/models/module_model.dart` | `ModuleModel` data class |
| `lib/app/data/models/management_option_model.dart` | `ManagementOptionModel` data class |
| `lib/app/data/static/module_data.dart` | All 17 modules with a la carte prices |
| `lib/app/data/static/management_data.dart` | 3 management options with monthly/annual/one-time prices |

### No Changes Needed

| File | Reason |
|:---|:---|
| `lib/app/modules/screens/plans_screen.dart` | Already handles responsive layout, animation, and hover state correctly |

### Backend — Supabase

**Migration:** `supabase/migrations/20260316000001_plans_pricing.sql`
Apply via Supabase dashboard → SQL Editor, or `supabase db push` once linked.

**New files:**

| File | Purpose |
|:---|:---|
| `lib/app/data/repositories/plan_repository.dart` | Fetches `plans`, `modules`, `management_options` from Supabase; single source of truth |
| `lib/app/data/datasources/supabase_client.dart` | Thin wrapper — initializes `SupabaseClient` from `.env` via `flutter_dotenv` |

**Initialization** (in `main.dart` before `runApp`):
```dart
await dotenv.load(fileName: '.env');
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

**Repository interface:**
```dart
// plan_repository.dart
Future<List<PlanModel>> fetchPlans();
Future<List<ModuleModel>> fetchModules();
Future<List<ManagementOptionModel>> fetchManagementOptions();
```

**Prices from DB are in USD cents** — divide by 100 for display (e.g. `220000 → $2,200`).

**RLS:** All three tables are public read-only (no auth token required). Matches the portfolio site's anonymous visitor model.

---

## Gaps & Open Questions

These must be resolved before or during implementation:

### 1. AI Chatbot Lite → Full Upgrade Path (UNRESOLVED)
PRICING.md lists "AI Chatbot — Full" at **$800 as an upgrade from Lite**, not a standalone add-on.
- **Gap:** The configurator treats all modules as independent toggles. Lite and Full are mutually exclusive and dependent (can't select Full without Lite; selecting Full replaces Lite's price, not adds to it).
- **Decision needed:** Should Full appear as a separate row that auto-selects Lite and disables it? Or is this out of scope for MVP (omit Full from the configurator)?
- **Interim assumption:** Include both rows; Full is disabled unless Lite is selected. Selecting Full adds $800 (upgrade delta), and Lite becomes non-toggleable while Full is active. This requires a `dependsOn` or `upgradeOf` field on `ModuleModel`.

### 2. Variable-Price Modules
Two modules have non-integer pricing that `ModuleModel.price: int` cannot represent:
- **SMS Reminders:** `$400 + usage` (Twilio pass-through)
- **Gated Video/Course Content:** `$1,500+` (minimum, scoped per engagement)

**Decision needed:** Options:
  - Add `String? priceNote` field to `ModuleModel` for display-only footnote; use the base price ($400, $1,500) in calculations.
  - Mark these as "Contact for pricing" and exclude from live price counter.
- **Interim assumption:** Add `String? priceNote` field. Show base price in counter + footnote asterisk on the tile.

### 3. Module Descriptions Unspecified
`ModuleModel` has a `description` field but no content is defined. PRICING.md has brief parenthetical notes for some modules (e.g., "PWA Push Notifications (home screen, no App Store)"). All 17 modules need descriptions before `module_data.dart` can be written.
- **Action:** Implementer must author descriptions. Use PRICING.md parentheticals as a starting point. Keep to ≤ 1 sentence each.

### 4. Preset Module IDs Not Listed
The plan data section says "add `lockedModuleIds`" but never enumerates the actual IDs. From PRICING.md:

| Plan | Locked Module IDs (by name — map to IDs in `module_data.dart`) |
|:---|:---|
| Pro | Blog & Gallery, Online Booking / Shop, Stripe Integration |
| Premium | Blog & Gallery, Online Booking / Shop, Stripe Integration, Tip/Gratuity at Checkout, PWA Push Notifications, Monthly Stats Digest, AI Chatbot (Lite) |

### 5. Base Price Constant Missing
The $1,200 base setup fee is referenced in edge cases ("price never goes below $1,200") but is not defined as a named constant in the data layer.
- **Action:** Define `static const int kBasePriceSetup = 1200;` in `module_data.dart` or a `pricing_constants.dart` file. Use it in the live price counter calculation.

### 6. Annual Pricing Toggle — Mechanism Unspecified
AC says "Annual pricing shown as an alternative with savings called out" but doesn't specify whether this is a toggle switch, radio buttons, or static display.
- **Decision needed:** Is annual pricing a user-selectable toggle (changes the monthly/annual display in the total bar) or purely informational text?
- **Interim assumption:** Static informational display — show both `$149/mo` and `$1,490/yr` with savings note. No toggle required for MVP.

### 7. Quote Contact Address Not in AC
The flow diagram shows `mailto:meow@raspucat.com` but this is not in the Acceptance Criteria.
- **Action:** Add to AC: `"Get a Quote" CTA launches mailto:meow@raspucat.com with subject "Raspucat Quote Request".`

### 8. High-Value Differentiators — In-Scope?
PRICING.md has a "High-Value Differentiators" section (Tip Engine, AI Concierge, PWA vs Native, Monthly Stats Digest). Not mentioned in the feature file.
- **Decision needed:** Should any of these appear as callout cards or tooltips within the configurator overlay?
- **Interim assumption:** Out of scope for MVP. Module descriptions in `ModuleModel` can incorporate the key selling points.

---

## Edge Cases & QA
- [ ] Overlay is scrollable when module list exceeds screen height.
- [ ] Locked modules cannot be toggled on Pro/Premium (tap does nothing, no error).
- [ ] Price counter never goes below the base price ($1,200).
- [ ] Volume discount badge only appears on Custom plan.
- [ ] Step 2 "Back" preserves all Step 1 selections without reset.
- [ ] Annual pricing toggle on Step 2 recalculates total correctly.
- [ ] Cards do not overflow on small screens (< 360px wide).
- [ ] Glow effect on Premium card does not cause performance issues on low-end devices.
- [ ] Overlay dismiss (close / back swipe) works on both iOS and Android.
- [ ] `mailto:` link works on both desktop and mobile browsers.
