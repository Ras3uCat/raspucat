# 003_ui_audit_fixes / 001_navigation

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`navbar.dart` exists and defines items `["Projects", "Blog", "Contact"]` but renders an
empty `Row`. There is no way for a visitor to jump between sections. This sub-feature
enables the navbar, wires it to scroll anchors, and adds a mobile hamburger menu.

---

## User Stories
- As a visitor, I want to click "Projects" in the nav and jump to the projects section.
- As a mobile visitor, I want a hamburger menu so I can navigate without a wide screen.
- As a visitor, I want to know which section I'm currently in via a highlighted nav item.

---

## Acceptance Criteria (Binary Pass/Fail)
- [ ] Navbar renders visible links on desktop (not an empty Row).
- [ ] Clicking a nav link scrolls smoothly to the corresponding section anchor.
- [ ] "Blog" link is either wired to a route or removed until the blog feature exists.
- [ ] Navbar background transitions from transparent to `#000612` with subtle opacity on scroll.
- [ ] Active section is visually indicated (e.g., cyan underline or glow on current link).
- [ ] On mobile breakpoint (`< ESizes.mobile`), nav links are hidden and a hamburger icon appears.
- [ ] Tapping the hamburger animates it into a triangle — tapping again animates back to hamburger.
- [ ] Triangle uses `TriangleNavigationPainter` (already exists at `lib/common/painters/triangle_navigation_painter.dart`).
- [ ] Hamburger opens a dropdown or slide-in menu with the same nav items.
- [ ] Hamburger menu closes on item tap or outside tap.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Scroll method | `Scrollable.ensureVisible` or `ScrollController.animateTo` | GetX scroll controller already exists |
| Navbar position | Fixed top | Standard; keeps navigation accessible at all times |
| Active state style | Cyan underline `EColors.primary` | Consistent with existing NeonText glow pattern |
| Mobile menu style | Dropdown or slide-in from top-right | Consistent with top-right button position |
| Blog link | Remove until blog feature ships | Avoids dead links |
| Hamburger → triangle animation | Morph via `AnimationController` + `CustomPaint` | `TriangleNavigationPainter` already built |

---

## Hamburger → Triangle Animation Detail

`TriangleNavigationPainter` already handles the triangle shape, fill, glow, and active state.
The morph uses an `AnimationController` (300ms, `Curves.easeInOut`) to interpolate between
the two states.

**Closed state (hamburger):** three horizontal lines drawn via `CustomPaint`
**Open state (triangle):** `TriangleNavigationPainter` with `isActive: true` (filled, glowing cyan)

**Morph approach — two options:**

Option A — **Crossfade** (simpler):
- `AnimatedCrossFade` between a `CustomPaint` drawing three lines and a `CustomPaint`
  drawing the triangle using `TriangleNavigationPainter`
- Duration: 250ms, curve: `Curves.easeInOut`

Option B — **Line-to-triangle morph** (premium):
- All three lines animated: top and bottom lines converge to the triangle's left and right
  base corners, middle line fades out, resulting path becomes the triangle
- Single `CustomPainter` with a `t` value (0.0 = hamburger, 1.0 = triangle)
- Uses `lerpDouble` on all 6 line endpoints

**Recommendation: Option A for initial implementation.** Option B as a follow-on polish pass.

**Triangle orientation:**
- Points **upward** (matches existing painter) — "launch/signal" metaphor consistent with brand
- `isActive: true` on open → filled cyan with glow

---

## Implementation Detail
**Files modified:**
- `lib/common/navbar/navbar.dart` — enable nav items, add scroll logic, add active state
- `lib/app/modules/screens/home_screen.dart` — add scroll anchors to each section
- `lib/app/controllers/scroll_controller.dart` — wire navbar to section positions

**Files created:**
- `lib/common/navbar/mobile_menu.dart` — hamburger/triangle toggle button + slide-in menu
- `lib/common/painters/hamburger_painter.dart` — three-line hamburger `CustomPainter`
  (mirrors `TriangleNavigationPainter` API: `color`, `isActive`, `isHovered`)

---

## Edge Cases & QA
- [ ] Navbar does not obscure hero content on initial load.
- [ ] Scroll animation does not break if user is already at the target section.
- [ ] Mobile menu closes when device is rotated to desktop width.
- [ ] "Contact" link scrolls to the Contact section (requires 003_missing_sections to exist).
- [ ] Triangle glow does not bleed into navbar background when menu is open.
- [ ] Animation completes cleanly if tapped rapidly (no partial states).
