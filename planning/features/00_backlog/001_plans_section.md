# 001_plans_section

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
Add a **PLANS** section to the Ras3uCat portfolio site. This section showcases three service tiers —
**Pro**, **Premium**, and **Custom** — styled in the site's existing neon/cyberpunk aesthetic.
The goal is to convert portfolio visitors into clients by presenting clear pricing and feature differentiation.

Reference design: `ChatGPT Image Feb 19, 2026, 10_29_18 AM.png`

---

## User Stories
- As a visitor, I want to see available service tiers so I can choose the right plan for my needs.
- As a visitor, I want a "Get In Touch" path for custom work so I can reach out directly.
- As a visitor, I want to clearly see what differentiates Pro from Premium so I can make an informed decision.

---

## Acceptance Criteria (Binary Pass/Fail)
- [ ] PLANS section is visible on the home page as a named scroll section.
- [ ] Three tier cards render: Pro, Premium, Custom.
- [ ] Pro card is visually highlighted (neon glow border) as the recommended tier.
- [ ] Each paid tier card shows: tier name, price, feature list, and "Select Plan" CTA.
- [ ] Custom card shows: diamond icon, description copy, and "Get In Touch" CTA.
- [ ] "Get In Touch" button opens a contact method (email link or contact form).
- [ ] Section is responsive — stacks vertically on mobile, row on desktop.
- [ ] All colors, typography, and effects use existing `EColors`, `EAppTheme`, and site widgets (e.g., `NeonText`, `NeonButton`, `SectionContainer`).

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Tier count | 3 (Pro, Premium, Custom) | No Basic tier per owner direction |
| Featured tier | Pro | Highlighted with neon glow border per reference image |
| Custom tier CTA | Email / contact link | No backend needed for MVP |
| Pricing (placeholder) | $199 / $299 / Custom | Owner to confirm final pricing before launch |
| Layout | `Row` on desktop, `Column` on mobile | Matches reference image; responsive via `EDevice` breakpoints |

---

## Scope Control
- [x] **Included:** Static plan cards with placeholder features and pricing.
- [x] **Included:** Neon glow effect on Pro card (featured).
- [x] **Included:** Diamond icon on Custom card.
- [x] **Included:** Responsive layout (desktop row / mobile column).
- [ ] **NOT Included:** Stripe payment integration (separate feature).
- [ ] **NOT Included:** Auth or account creation flow.
- [ ] **NOT Included:** Dynamic pricing from backend.

---

## UX & UI Design
**Visual Reference:** Cyberpunk pricing grid — dark `#000612` background, `#58E3EF` cyan accents,
neon glow border on the featured Pro card, triangle decorations matching site motif.

**Flow:**
1. User scrolls to PLANS section on home page.
2. Three cards displayed side by side (desktop) or stacked (mobile).
3. Pro card glows — draws the eye as the recommended option.
4. User clicks "Select Plan" → TBD (placeholder for Stripe or contact).
5. User clicks "Get In Touch" on Custom card → opens `mailto:meow@raspucat.com`.

**Widgets (reuse existing where possible):**
- `SectionContainer` — wraps the section with consistent padding/background.
- `NeonText` — section heading "PLANS".
- `NeonButton` — "Select Plan" and "Get In Touch" CTAs.
- New widget: `PlanCard` — self-contained card with glow variant for Pro.
- Triangle decorators — reuse existing triangle painter/widget from the site.

---

## Implementation Detail
**Frontend files (new/modified):**
- `lib/app/modules/widgets/plan_card.dart` — new `PlanCard` widget.
- `lib/app/data/models/plan_model.dart` — `PlanModel` data class (name, price, features, isFeatured).
- `lib/app/data/projects/plan_data.dart` — static list of the 3 plans.
- `lib/app/modules/screens/home_screen.dart` — add PLANS section below existing content.

**Backend:** None for MVP. All data is static.

---

## Edge Cases & QA
- [ ] Cards do not overflow on small screens (< 360px wide).
- [ ] Glow effect on Pro card does not cause performance issues on low-end devices.
- [ ] "Get In Touch" mailto link works on both desktop and mobile browsers.
- [ ] Feature list scrolls gracefully if copy is longer than card height.
- [ ] Section heading matches existing section heading style used elsewhere on the site.
