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
- [ ] Hamburger opens a slide-in or dropdown menu with the same nav items.
- [ ] Hamburger menu closes on item tap or outside tap.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Scroll method | `Scrollable.ensureVisible` or `ScrollController.animateTo` | GetX scroll controller already exists |
| Navbar position | Fixed top | Standard; keeps navigation accessible at all times |
| Active state style | Cyan underline `EColors.primary` | Consistent with existing NeonText glow pattern |
| Mobile menu style | Dropdown or bottom sheet | Bottom sheet feels more native on mobile |
| Blog link | Remove until blog feature ships | Avoids dead links |

---

## Implementation Detail
**Files modified:**
- `lib/common/widgets/navbar.dart` — enable nav items, add scroll logic, add active state
- `lib/app/modules/screens/home_screen.dart` — add scroll anchors to each section
- `lib/app/controllers/scroll_controller.dart` — wire navbar to section positions

**Files created (if needed):**
- `lib/common/widgets/mobile_menu.dart` — hamburger + slide-in menu

---

## Edge Cases & QA
- [ ] Navbar does not obscure hero content on initial load.
- [ ] Scroll animation does not break if user is already at the target section.
- [ ] Mobile menu closes when device is rotated to desktop width.
- [ ] "Contact" link scrolls to the Contact section (requires 003_missing_sections to exist).
