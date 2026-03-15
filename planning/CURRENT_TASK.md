# Current Task Tracking

## Status Summary
- **Feature:** 001
- **Feature Name:** Plans Section
- **Current Mode:** STUDIO
- **Active Agent:** Flutter Engineer (AntiGravity)
- **Status:** 🟡 In Progress

---

## Active Objective
> Build and integrate a static **PLANS** section on the home page displaying three service tiers — **Pro (Launchpad)**, **Premium (Engine)**, and **Custom (Scale)** — in the site's neon/cyberpunk aesthetic. Goal: convert portfolio visitors into clients.

---

## Active Sub-tasks
- [ ] Task 1: Create `PlanModel` data class (`lib/app/data/models/plan_model.dart`)
- [ ] Task 2: Create static plan data list (`lib/app/data/projects/plan_data.dart`) using confirmed pricing from PRICING.md
- [ ] Task 3: Build `PlanCard` widget with glow variant for featured Pro card (`lib/app/modules/widgets/plan_card.dart`)
- [ ] Task 4: Add PLANS section to `home_screen.dart` below existing content, using `SectionContainer` + `NeonText` heading
- [ ] Task 5: Verify responsive layout — `Row` on desktop, `Column` on mobile via `EDevice` breakpoints
- [ ] Task 6: QA all acceptance criteria (see below)

---

## Pricing Data (Source: PRICING.md — use these, not placeholders)

| Tier | Label | Setup Fee | Ideal For |
|:---|:---|:---|:---|
| Pro | Launchpad | **Starting at $1,500** | Solopreneurs & Startups |
| Premium | Engine | **Starting at $3,500** | Service & Retail SMBs |
| Custom | Scale | **Starting at $8,500** | Franchises & High-Growth |

**Monthly Management (display as add-on context):**
- Standard: $149/mo — Hosting, SSL, Supabase, domain, stats digest, 1hr support
- Premium: $299/mo — All standard + priority support, AI chatbot fine-tuning, SEO

### Pro (Launchpad) Features
- Core Site (Hero, Services, FAQ)
- Blog & Gallery
- CRM & Lead Gen

### Premium (Engine) Features
- Everything in Pro
- Online Booking / Shop
- Stripe Integration
- Tip/Gratuity at Checkout
- Web Push Notifications
- Monthly Stats Digest

### Custom (Scale) Features
- Everything in Premium
- AI Chatbot (Claude-powered)
- Automated PDF Invoices
- Multi-location Support
- Mobile Apps (iOS/Android)
- Stripe Connect (Multi-staff)

---

## Known Blockers / Risks
- "Select Plan" CTA destination is TBD (Stripe not in scope for MVP — use `mailto:meow@raspucat.com` as fallback)

---

## Relevant Context
- **Primary Feature File:** `planning/features/00_backlog/001_plans_section.md`
- **Pricing Source:** `planning/PRICING.md`
- **Active Files to Create/Modify:**
  - `lib/app/data/models/plan_model.dart` (new)
  - `lib/app/data/projects/plan_data.dart` (new)
  - `lib/app/modules/widgets/plan_card.dart` (new)
  - `lib/app/modules/screens/home_screen.dart` (modify — add section)
- **Design Reference:** `ChatGPT Image Feb 19, 2026, 10_29_18 AM.png`
- **Design System:** `EColors`, `EAppTheme`, `NeonText`, `NeonButton`, `SectionContainer`

---

## Acceptance Criteria (Definition of Done)
1. [ ] PLANS section visible on home page as a named scroll section.
2. [ ] Three tier cards render: Pro (Launchpad), Premium (Engine), Custom (Scale).
3. [ ] Pro card has neon glow border (featured highlight).
4. [ ] Each paid tier card shows: tier name, setup fee range, feature list, "Select Plan" CTA.
5. [ ] Custom card shows: diamond icon, description, "Get In Touch" CTA → `mailto:meow@raspucat.com`.
6. [ ] Responsive: stacks vertically mobile / row desktop.
7. [ ] All design tokens use `EColors`, `EAppTheme`, existing site widgets — no hardcoded values.
8. [ ] No file exceeds 300 lines. No business logic in widgets.
9. [ ] Feature file moved to `features/02_completed/` after QA passes.

---

## Session Log
- **2026-03-14:** Planner initialized task from `00_backlog/001_plans_section.md`. Pricing confirmed from `PRICING.md`. CURRENT_TASK updated. Ready for AntiGravity implementation.
