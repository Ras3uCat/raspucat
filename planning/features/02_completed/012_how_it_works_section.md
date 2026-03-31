# 012 — "How It Works" Section

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

**Mode: STUDIO**

---

## Overview

Potential clients land on the site and understand the product is a web platform build — but the
full journey (configure → deposit → build → portal → manage → grow) isn't explained anywhere.
This section bridges the gap between "I'm interested" and "I'm ready to configure."

It lives on the marketing site between the Plans/Pricing section and the Projects section.
It's not a FAQ — it's a narrative of the client experience, told in 6 phases.

---

## Brand Direction

**Tone:** Retro-futuristic / Mission Control. The client is not "buying a website" —
they are **initiating a build sequence**. Language should feel like a technical briefing:
precise, confident, with a hint of sci-fi.

**Visual Identity:**
- Vertical timeline or horizontal phase strip — each phase is a numbered "node"
- Neon node connectors (EColors.primary glow) linking the phases
- Each phase has an icon, a codename label, a headline, and 1–2 lines of copy
- Entrance animation: phases stagger in as the user scrolls into view
- On desktop: horizontal scroll or side-by-side layout. On mobile: vertical stack.

**Phase Codenames (on-brand labels above each headline):**
```
01 / CONFIGURE
02 / DEPOSIT
03 / BUILD
04 / LAUNCH
05 / EXPAND
06 / OPERATE
```

---

## The 6 Phases (Content)

### 01 / CONFIGURE
**Headline:** Pick your plan. Build your stack.
**Copy:** Choose a preset plan or build from scratch with the module configurator. Toggle
add-ons, watch the price update live. No surprises — your total is locked before you commit.
**Icon:** `Icons.tune_outlined`

---

### 02 / DEPOSIT
**Headline:** Secure your slot.
**Copy:** A deposit locks in your build. Stripe-powered — takes 30 seconds. Your remaining
balance is only charged when the site is live and you're satisfied.
**Icon:** `Icons.lock_outlined`

---

### 03 / BUILD
**Headline:** We build. You watch.
**Copy:** Your private client portal opens the moment your deposit clears. Track your project
stage, share assets, send messages, and see every update in real time — no chasing emails.
**Icon:** `Icons.terminal_outlined`

---

### 04 / LAUNCH
**Headline:** Live. Verified. Yours.
**Copy:** We flip the switch together. Final balance is charged only after you confirm the
site is ready. Your domain, your brand, your business — online and running.
**Icon:** `Icons.rocket_launch_outlined`

---

### 05 / EXPAND
**Headline:** Add features anytime.
**Copy:** Your portal stays open after launch. Buy new modules — booking, AI chatbot,
loyalty programs — straight from the portal. No new contracts. No waiting in a queue.
**Icon:** `Icons.add_circle_outline`

---

### 06 / OPERATE
**Headline:** Stay running. Or take the keys.
**Copy:** Monthly management covers hosting, updates, and support so you never think about
infrastructure. Prefer full ownership? Choose the handover package and we transfer everything
— code, credentials, docs, and one onboarding call.
**Icon:** `Icons.settings_outlined`

---

## User Stories

- As a first-time visitor, I want to understand what happens after I click "Configure" so I
  know what I'm committing to.
- As a business owner, I want to understand the portal before I buy, so I know I'll have
  visibility into my project.
- As a skeptic, I want to know that I don't pay in full upfront and that I can approve before
  final payment.
- As an existing client considering add-ons, I want to be reminded that the portal is always
  available for expansions.

---

## Acceptance Criteria

### Section Structure
- [x] Section added to `desktop_layout.dart` between the Plans section and the Projects section.
- [x] Section has a heading: `"THE SEQUENCE"` with a muted sub-label: `"From first signal to fully operational."`
- [x] 6 phase cards rendered in order.
- [x] On desktop (≥ 1024px): horizontal layout — phases side-by-side with a connecting line.
- [x] On mobile: vertical stack — phases listed top to bottom.

### Phase Card Design
- [x] Each card has: codename label (e.g. `01 / CONFIGURE`), icon, headline, body copy.
- [x] Codename label: small, muted, monospace-style, EColors.primary at low opacity.
- [x] Icon: outlined style, EColors.primary, medium size.
- [x] Headline: EColors.textWhite, bold, `ESizes.fontSizeSm` (w600).
- [x] Body: EColors.textSecondary, `ESizes.fontSizeLabel`, line height 1.6.
- [x] Card background: `EColors.primary.withValues(alpha: 0.03)` with primary border at low opacity.

### Connector Line (Desktop)
- [x] A horizontal line connects all 6 phase nodes at icon level.
- [x] Line uses `EColors.primary.withValues(alpha: 0.2)` — subtle, not distracting.
- [x] Dashed line style via `CustomPainter` (`_DashPainter`).

### Animation
- [x] Phases stagger in with a fade + slight upward slide as the section enters the viewport.
- [x] Stagger delay: 80ms between each phase via `Interval` curves on a shared `AnimationController`.
- [x] Uses `AnimationController` + `FadeTransition` + `SlideTransition`.

### Copy Constants
- [x] All copy stored in `const _phases` list of `_Phase` data objects.
- [x] Data model: `_Phase` with fields: `codename`, `headline`, `body`, `icon`, `badge?`.
- [x] Section heading/sub-label in `EText` constants.

### Portal Callout (Optional Enhancement)
- [x] Phase 03 (BUILD) card has accent badge: `"Portal opens on deposit"`.

---

## Files to Create
- `lib/app/modules/widgets/how_it_works_section.dart`

## Files to Modify
- `lib/common/responsive/screens/desktop_layout.dart` — insert section in correct position
- `lib/utils/constants/text.dart` — add any reusable string constants if needed

---

## Design Notes

The "How It Works" section is one of the highest-conversion elements on a service business
landing page. The goal is not to overwhelm — it's to eliminate doubt. Every phase should
answer a specific fear:

| Phase | Fear It Addresses |
|:------|:-----------------|
| Configure | "I don't know what I need" |
| Deposit | "What if I pay and nothing happens?" |
| Build | "I'll lose control once I sign" |
| Launch | "I'll be stuck with something broken" |
| Expand | "I'll outgrow it quickly" |
| Operate | "I'll be locked in forever" |

The section should feel like a confident technical briefing — not a sales pitch.
