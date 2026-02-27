# 003_ui_audit_fixes

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
UI/UX audit findings from 2026-02-26. The visual design language (neon/cyberpunk aesthetic,
triangles, glow effects) is strong and consistent. The gaps are structural — the navbar is
disabled, the hero has no CTA, and three core portfolio sections (About, Skills, Contact)
don't exist yet. This feature covers everything needed to make the site feel complete.

---

## Sub-Features

| File | Scope |
| :--- | :--- |
| `003_ui_audit_fixes/001_navigation.md` | Enable navbar, anchor scroll, mobile hamburger |
| `003_ui_audit_fixes/002_hero_section.md` | CTA button, tagline refinement |
| `003_ui_audit_fixes/003_missing_sections.md` | About, Skills/Tech Stack, Contact, Footer |
| `003_ui_audit_fixes/004_project_fixes.md` | DarkArc data, back navigation on detail view |
| `003_ui_audit_fixes/005_polish.md` | Scroll indicator, skeleton loaders, filtering, testimonials |

---

## Acceptance Criteria (Binary Pass/Fail)

### Navigation
- [ ] Navbar renders links that scroll to named sections.
- [ ] Mobile viewport shows a hamburger menu instead of inline links.
- [ ] Active section is highlighted in the navbar.

### Hero
- [ ] Hero section has a visible, tappable CTA button.
- [ ] Tagline is reviewed and updated to better reflect the brand voice.

### Missing Sections
- [ ] About section exists with bio copy and credentials.
- [ ] Skills/Tech Stack section displays the primary technologies.
- [ ] Contact section provides a clear way to reach out.
- [ ] Footer exists with brand sigil and social/legal links.

### Projects
- [ ] DarkArc is either completed (images + links) or removed from the carousel.
- [ ] Project detail view has a visible back/close affordance.

### Polish
- [ ] Scroll progress indicator is visible on desktop.
- [ ] Project carousel images show skeleton loaders while loading.
- [ ] Carousel can be filtered by technology tag.
- [ ] Testimonials section exists (even if placeholder copy for now).

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Navbar style | Fixed top, transparent-to-dark on scroll | Standard web portfolio convention; keeps brand visible |
| Mobile menu | Slide-in drawer or dropdown | Consistent with dark aesthetic |
| About layout | Text left, visual right (desktop) | Natural reading flow |
| Skills display | Animated tag/badge grid | Reuses neon badge pattern from project tech tags |
| Contact | `mailto:` link + social icons | No backend needed for MVP |
| Footer copy | Use existing `EBrand.footerText` (`"Sync complete △ M3OW"`) | Already written, unused |
| Scroll indicator | Thin cyan line at top of viewport | Subtle, on-brand |

---

## Scope Control
- [x] **Included:** All items listed in sub-feature files.
- [ ] **NOT Included:** Blog section (needs separate content strategy decision).
- [ ] **NOT Included:** Dark/light mode toggle (low ROI for dark-only brand).
- [ ] **NOT Included:** Analytics integration (separate feature).
- [ ] **NOT Included:** Backend contact form (mailto is sufficient for MVP).
