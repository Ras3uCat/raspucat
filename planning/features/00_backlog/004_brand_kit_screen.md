# 004_brand_kit_screen

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
A living, interactive brand style guide screen embedded in the Ras3uCat app at a hidden route
(`/brand-kit`). Accessible via URL only — no navigation link, no button. Designed to be handed
to any developer or designer so they can build a Ras3uCat-themed site without guesswork.

The kit showcases every design token, reusable widget, motion pattern, image usage rule, brand
voice string, and sigil variant — all live and interactive, not static screenshots.

---

## User Stories
- As a developer, I want to see every color, font, and component live so I can replicate the
  Ras3uCat aesthetic exactly.
- As a designer, I want a visual, self-explanatory reference so I can understand the brand
  without reading code.
- As the brand owner, I want a URL I can share privately with collaborators without exposing
  a public link on the main site.

---

## Acceptance Criteria (Binary Pass/Fail)
- [ ] Route `/brand-kit` exists and renders the brand kit screen.
- [ ] No link, button, or nav item anywhere in the existing UI points to `/brand-kit`.
- [ ] Hero section shows M3OWBrandMark, stylized app name, tagline, and credit line.
- [ ] Color section shows all 6 brand tokens as live swatches with hover state (hex + usage).
- [ ] Typography section shows all 4 font families as live specimens.
- [ ] Motion section demonstrates parallax, AnimatedOnView, and GradientOverlay live.
- [ ] Components section has live NeonButton (hoverable), NeonText, EDialog trigger, and M3OWBrandMark at 3 sizes.
- [ ] Assets section shows all logo variants with usage guidelines.
- [ ] Voice section displays all EBrand voice strings with Do/Don't examples.
- [ ] Sigils section shows all sigil and credit line variants.
- [ ] Every section animates in on scroll (AnimatedOnView).
- [ ] Background triangles present and interactive throughout.
- [ ] Screen is responsive across mobile, tablet, and desktop.
- [ ] All files stay under 300 lines.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Discovery | URL-only, no nav link | Easter egg access; aligns with brand mystery |
| Route | `/brand-kit` | Clean, self-descriptive |
| Layout | Single scrollable page, 8 sections | Each section = one topic, immersive scroll journey |
| State | Reuse all existing controllers | No new state overhead |
| Code hints | Directional labels only, no snippets | Client-ready, not a dev docs page |
| Popup style | EDialog for component demos | Consistent with existing project section pattern |

---

## Scope Control
- [x] **Included:** 8 interactive sections (hero, colors, typography, motion, components, assets, voice, sigils)
- [x] **Included:** Live hover, scroll, parallax, and dialog interactions
- [x] **Included:** All EBrand strings, EColors tokens, font specimens
- [x] **Included:** Responsive layout (mobile/tablet/desktop)
- [ ] **NOT Included:** Stripe, auth, or any backend integration
- [ ] **NOT Included:** Copy-paste code snippets
- [ ] **NOT Included:** Any nav link or button to this route from existing UI
- [ ] **NOT Included:** PDF or export function

---

## UX & UI Design

**Visual Style:** Matches the main Ras3uCat site exactly — midnight background, cyan accents,
neon glows, geometric triangles, parallax motion. The brand kit itself IS the brand.

**Scroll Flow:**
1. **Hero** — M3OWBrandMark, stylized brand name, tagline, credit line. Full-height, parallax logo drift.
2. **Colors** — 6 swatches in a responsive grid. Hover reveals hex + usage note.
3. **Typography** — 4 font specimens (Play, Orbitron, Space Grotesk, Inter). Live NeonText glow demo.
4. **Motion** — Live parallax triangle + AnimatedOnView entrance + GradientOverlay shimmer. Directional labels describe the technique without code.
5. **Components** — Live NeonButton (hoverable), NeonText specimen, EDialog trigger, M3OWBrandMark at sm/md/lg.
6. **Assets** — Logo variants (SVG black, SVG white, PNG gradient). Image usage rule: always with 0.1 cyan overlay tint.
7. **Voice** — All EBrand voice strings as styled block quotes. Do/Don't tone examples.
8. **Sigils** — All M3OW/credit variants with usage context labels. Closes with `EBrand.voiceFooter`.

**Widgets reused (no new equivalents created):**
- `NeonButton`, `NeonText`, `M3OWBrandMark`, `BackgroundTriangles`, `TriangleWidget`
- `AnimatedOnView`, `GradientOverlay`, `SectionContainer`, `EDialog`
- `EScrollController` (parallax), `SectionAnimationController` (scroll triggers), `GradientController` (shimmer)

---

## Implementation Detail

**New Files:**
- `lib/app/modules/screens/brand_kit_screen.dart`
- `lib/app/modules/widgets/brand_kit/bk_hero_section.dart`
- `lib/app/modules/widgets/brand_kit/bk_colors_section.dart`
- `lib/app/modules/widgets/brand_kit/bk_typography_section.dart`
- `lib/app/modules/widgets/brand_kit/bk_motion_section.dart`
- `lib/app/modules/widgets/brand_kit/bk_components_section.dart`
- `lib/app/modules/widgets/brand_kit/bk_assets_section.dart`
- `lib/app/modules/widgets/brand_kit/bk_voice_section.dart`
- `lib/app/modules/widgets/brand_kit/bk_sigils_section.dart`

**Modified Files:**
- `lib/routes/app_routes.dart` — add `brandKit = '/brand-kit'`
- `lib/routes/routes.dart` — add `GetPage` entry
- `lib/utils/constants/exports.dart` — export new brand kit widgets

**Backend:** None.

---

## Edge Cases & QA
- [ ] Route is not discoverable via any UI element on the live site.
- [ ] Each section file stays under 300 lines.
- [ ] Parallax does not cause jank on mobile (keep EScrollController.scrollOffset multiplier low, ~0.05).
- [ ] EDialog opens and closes cleanly in the components section.
- [ ] Color swatches are readable on midnight background (use border + label, never color-only).
- [ ] Logo SVGs render at all breakpoints without overflow (use BoxFit.contain, constrained width).
- [ ] AnimatedOnView IDs are unique per section to avoid state collisions.
