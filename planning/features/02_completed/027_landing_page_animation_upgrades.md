---
Title: Landing Page Animation Upgrades
Mode: STUDIO
Priority: High
Status: Completed
Source: Animation pattern audit — Two-Shades-of-Travel (JS) + Cheese-Inc (Flutter) reference sites
---

# Landing Page Animation Upgrades

## Goal
Elevate the Raspucat marketing site from basic scroll-entrance animations to a premium, scroll-driven experience that matches the retro-futuristic brand. Every section should feel intentional and cinematic.

## Current State
- `AnimatedOnView` — basic fade+slide on scroll (in use across all sections)
- `TriangleController` — 20s continuous rotation on background elements
- `NeonText` / `NeonButton` — static glow (no entrance or interaction animation)
- `PulseAnimation` on plan cards
- No parallax, no cursor, no marquee, no tilt, no word reveals

## Reference Sources
- Pattern catalog (JS): Claude memory `reference_two_shades_animations.md`
- Pattern catalog (Flutter): Claude memory `reference_cheese_inc_flutter_animations.md`
- All widgets below exist in `modular_project` at:
  `/home/ryan/Documents/development/flutter_apps/dev/modular_project/execution/frontend/app/lib/core/widgets/`

---

## Proposed Upgrades (Priority Order)

---

### 1. Hero Word-by-Word Reveal
**Priority: Critical** — first thing visitors see.

**What:** Replace the static `NeonText` hero heading with a staggered word-by-word entrance that fires after the loader exits. Each word slides up from a clip and fades in with the brand neon glow.

**How:**
- Port `TextReveal` from modular_project into `lib/common/widgets/animations/`
- Wrap the hero heading in `TextReveal` triggered by `SectionAnimationController` loader-done state
- Apply NeonText styling to each revealed word (3-layer shadow)
- Timing: 1100ms per word, `Cubic(0.16, 1.0, 0.3, 1.0)` (ease-out-expo), 40ms stagger between words

**Files to touch:**
- `lib/common/widgets/animations/text_reveal.dart` (new — port from modular_project)
- `lib/app/modules/screens/home_screen.dart` (apply widget to hero heading)

---

### 2. Custom Cursor (Web Only)
**Priority: High** — single biggest perceived-quality upgrade.

**What:** Replace the default browser cursor with the branded dot + ring cursor. Ring expands from 7px → 23px on interactive elements. `BlendMode.difference` makes it visible on any background color.

**How:**
- Port `CursorOverlay` + `CursorState` from modular_project into `lib/common/widgets/`
- Wrap the root `MaterialApp` child in `CursorOverlay` (inside `AppShell` or `main.dart`)
- Wrap `NeonButton`, `ProjectCard`, and nav links with `MouseRegion` that sets `CursorState.isInteractive = true` on enter / `false` on exit
- Web-only: guarded with `kIsWeb`

**Files to touch:**
- `lib/common/widgets/cursor_overlay.dart` (new — port from modular_project)
- `lib/app/app_shell.dart` or `lib/main.dart` (wrap root with `CursorOverlay`)
- `lib/common/widgets/buttons/neon_button.dart` (add `CursorState` toggle)
- `lib/common/widgets/cards/project_card.dart` (add `CursorState` toggle)

---

### 3. Magnetic Buttons
**Priority: High** — pairs with cursor upgrade, feels premium on the CTAs.

**What:** NeonButtons gently drift ±12px toward the cursor when hovered. Snaps back on exit.

**How:**
- Port `MagneticWidget` from modular_project into `lib/common/widgets/`
- Wrap primary `NeonButton` CTAs with `MagneticWidget`
- Trigger radius: 80px. Max drift: 12px. Enter: 60ms linear. Exit: 300ms `easeOutCubic`

**Files to touch:**
- `lib/common/widgets/magnetic_widget.dart` (new — port from modular_project)
- `lib/app/modules/screens/home_screen.dart` (wrap hero CTA)

---

### 4. TiltCard on Project Cards
**Priority: High** — adds depth to the projects carousel, fits the tactical aesthetic.

**What:** `ProjectCard` tilts up to ±8° toward the cursor on hover with a Matrix4 perspective transform. Snaps back on exit.

**How:**
- Port `TiltCard` from modular_project into `lib/common/widgets/`
- Wrap `ProjectCard` with `TiltCard`
- Tilt: ±8°. Hover: 50ms. Exit: 300ms `easeOutCubic`

**Files to touch:**
- `lib/common/widgets/tilt_card.dart` (new — port from modular_project)
- `lib/common/widgets/cards/project_card.dart` (wrap with `TiltCard`)

---

### 5. Marquee Section — Tech Stack / Client Strip
**Priority: Medium** — adds motion below the fold without requiring new content.

**What:** A horizontally scrolling strip (infinite loop) displaying tech stack items, client logos, or brand keywords. Pairs well as a section divider between hero and projects.

**How:**
- Port `MarqueeSection` from modular_project into `lib/common/widgets/`
- Add a `MarqueeSection` between the hero and projects sections
- Content: tech stack icons/labels (Flutter · Supabase · Stripe · GetX · Dart · Firebase)
- Style: `ETextStyles.eyebrow` in `EColors.primaryMuted`, `// M3OW` divider format

**Files to touch:**
- `lib/common/widgets/marquee_section.dart` (new — port from modular_project)
- `lib/app/modules/screens/home_screen.dart` (insert marquee between hero and projects)

---

### 6. Sticky Swap Section — Services/Features
**Priority: Medium** — premium "feature showcase" pattern, strong for conversions.

**What:** A new "What We Build" section where the left column (title + description + progress bar) is pinned and the right column crossfades between project type screenshots/illustrations as the user scrolls.

**How:**
- Port `StickySwapSection` from modular_project into `lib/common/widgets/`
- Add a new "Services" section to the home page between Projects and Plans
- Items: 3–4 service types (e.g., "Marketing Sites", "Client Portals", "E-Commerce", "SaaS Apps")

**Files to touch:**
- `lib/common/widgets/sticky_swap_section.dart` (new — port from modular_project)
- `lib/app/modules/screens/home_screen.dart` (insert new section)
- Assets: need 3–4 service preview images

---

### 7. Horizontal Scroll Panels — "How It Works"
**Priority: Medium** — replaces the current slide-transition HowItWorks with an Apple-style horizontal scroll.

**What:** The "How It Works" steps (currently vertical with slide transitions) become horizontal scroll panels driven by the user scrolling down. Each step occupies a full-viewport panel.

**How:**
- Port `HorizontalScrollPanels` from modular_project into `lib/common/widgets/`
- Replace existing `HowItWorksSection` widget with `HorizontalScrollPanels`
- 4 panels: Discover → Design → Build → Deploy

**Files to touch:**
- `lib/common/widgets/horizontal_scroll_panels.dart` (new — port from modular_project)
- `lib/app/modules/screens/home_screen.dart` (replace HowItWorks section)

---

### 8. Hero Parallax Background
**Priority: Medium** — adds depth to the hero without new content.

**What:** The background triangles (currently only rotating) also drift upward at 0.3× scroll speed as the user scrolls past the hero, creating a parallax depth effect.

**How:**
- Add `scrollOffset` Rx to `EScrollController` (already tracks scroll position)
- In `HomeScreen` hero: wrap background `BackgroundTriangles` with `Obx(() => Transform.translate(offset: Offset(0, controller.scrollOffset.value * 0.3), child: ...))`
- Fade triangles out as they parallax (opacity = `(1 - scrollOffset / viewportH).clamp(0.0, 1.0)`)

**Files to touch:**
- `lib/app/controllers/scroll_controller.dart` (expose `scrollOffset` Rx if not present)
- `lib/app/modules/screens/home_screen.dart` (wrap hero background)

---

### 9. Scroll-X Marquee Heading (Horizontal Drift)
**Priority: Low** — subtle brand detail.

**What:** A section heading (e.g., "SELECTED WORK" or "M3OW SYSTEMS") that slowly translates left as the user scrolls past it — mirrors the Two-Shades-of-Travel scroll-x text pattern.

**How:**
- Add a `ScrollXText` widget: `NotificationListener` maps scroll progress within parent bounds → `Transform.translateX(-progress * 30%)`
- Use as a section label above the projects carousel

**Files to touch:**
- `lib/common/widgets/animations/scroll_x_text.dart` (new, ~40 lines)
- `lib/app/modules/screens/home_screen.dart` (add above projects section)

---

### 10. Counter Number Animation — Stats Section
**Priority: Low** — adds social proof, driven by scroll trigger.

**What:** A new stats strip (e.g., "12 Projects Shipped · 4 Active Clients · 99% Uptime") where numbers count up from 0 when they enter the viewport.

**How:**
- Create `CounterText` widget: `VisibilityDetector` at 50% threshold fires a `rAF`-style `AnimationController` that counts 0→value over 1.6s cubic easeOut
- Pattern from Two-Shades-of-Travel `sections.js:123-144`

**Files to touch:**
- `lib/common/widgets/counter_text.dart` (new, ~60 lines)
- `lib/app/modules/screens/home_screen.dart` (add stats strip)

---

## Widget Port Checklist (all source: modular_project `lib/core/widgets/`)
| Widget | Target path in Raspucat | Status |
|---|---|---|
| `text_reveal.dart` | `lib/common/widgets/animations/` | [x] |
| `cursor_overlay.dart` (+ CursorState) | `lib/common/widgets/` | [x] |
| `magnetic_widget.dart` | `lib/common/widgets/` | [x] |
| `tilt_card.dart` | `lib/common/widgets/` | [x] |
| `marquee_section.dart` | `lib/common/widgets/` | [x] |
| `sticky_swap_section.dart` | `lib/common/widgets/` | [x] |
| `horizontal_scroll_panels.dart` | `lib/common/widgets/` | [x] |

## New Widgets (build from scratch)
| Widget | Target path | Pattern source |
|---|---|---|
| `scroll_x_text.dart` | `lib/common/widgets/animations/` | Two-Shades-of-Travel `motion.js:147-164` |
| `counter_text.dart` | `lib/common/widgets/` | Two-Shades-of-Travel `sections.js:123-144` |

## Dependencies
- `visibility_detector: ^0.4.0` — already present in pubspec.yaml (v0.4.0+2)

---

## Acceptance Criteria
- [x] Hero heading uses word-by-word reveal on load
- [x] Custom cursor visible on web; ring expands on buttons/cards
- [x] Hero CTA button has magnetic drift on hover
- [x] Project cards tilt on hover
- [x] Marquee strip visible between hero and projects
- [x] Sticky swap "Services" section added with 3+ items (4 items)
- [x] HowItWorks replaced with horizontal scroll panels
- [x] Hero background triangles parallax on scroll
- [x] `flutter analyze`: no new issues introduced
- [x] Smoke test in Chrome across all sections
