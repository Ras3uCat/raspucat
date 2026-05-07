---
Title: Animation Library Upgrade
Mode: STUDIO
Priority: Medium
Status: Complete
Source: Two-Shades-of-Travel (vanilla JS) + Cheese-Inc (Flutter web) pattern audit
---

# Animation Library Upgrade

## Goal
Build a complete, reusable Flutter web animation widget library into `modular_project` so every future client landing page ships with premium scroll/hover/parallax effects by default.

## Background
Patterns cataloged from two reference sites:
- `/home/ryan/Downloads/Two-Shades-of-Travel/` — vanilla JS master class in scroll-driven UX
- `clients/cheese-inc/execution/frontend/app/` — Flutter web implementation of equivalent patterns

Full pattern catalog in Claude memory:
- `reference_two_shades_animations.md` — JS patterns + file:line refs
- `reference_cheese_inc_flutter_animations.md` — Flutter widget catalog

---

## Acceptance Criteria
- [x] All widgets present in `modular_project` `lib/core/widgets/`:
  - `reveal_on_scroll.dart` ✓ (was already ported)
  - `text_reveal.dart` ✓ (was already ported)
  - `tilt_card.dart` ✓ (was already ported)
  - `magnetic_widget.dart` ✓ (was already ported)
  - `cursor_overlay.dart` ✓ (upgraded — added CursorState, hover ring expansion, BlendMode.difference)
  - `cursor_state.dart` ✓ (defined inside cursor_overlay.dart)
  - `marquee_section.dart` ✓ (was already ported)
  - `ambient_hero_background.dart` ✓ (was already ported)
  - `inertia_carousel.dart` ✓ (was already ported)
  - `app_loader.dart` ✓ (upgraded — SlideTransition curtains via _exitCtrl)
  - `_loader_curtains.dart` ✓ (new generic version, no branding)
  - `sticky_swap_section.dart` ✓ (new — 141 lines)
  - `horizontal_scroll_panels.dart` ✓ (new — 157 lines)
- [x] `visibility_detector: ^0.4.0` in `pubspec.yaml`
- [x] `HomeController` scroll offset pattern documented — `NotificationListener<ScrollNotification>` in `HomeView` feeds `scrollOffset.value`; consumed by `hero_fullbleed.dart`
- [x] `flutter analyze`: No issues found
- [x] Smoke test in Chrome: page loads, renders, nav/hero/CTA visible, zero JS errors (Flutter canvas renders animations; headless Playwright can't visually verify canvas, no functional errors detected)

---

## Tasks

### 1. Audit — Check What's Already Ported
Path: `/home/ryan/Documents/development/flutter_apps/dev/modular_project/execution/frontend/app/lib/core/widgets/`

Compare contents against the acceptance criteria widget list above. Produce a diff: what exists vs. what's missing. Only port what's absent.

### 2. Port Missing Widgets from Cheese-Inc
Source: `/home/ryan/Documents/development/flutter_apps/clients/cheese-inc/execution/frontend/app/lib/core/widgets/`
Target: `/home/ryan/Documents/development/flutter_apps/dev/modular_project/execution/frontend/app/lib/core/widgets/`

Port all missing files from the acceptance criteria list. Include `cursor_state.dart` — it's a dependency of both `cursor_overlay.dart` and `magnetic_widget.dart` (exposes an `isInteractive` flag that expands the cursor ring).

Then update `pubspec.yaml`:
```yaml
visibility_detector: ^0.4.0
```
Run: `flutter pub get`

### 3. Document Scroll Offset Controller Pattern
The hero parallax and nav opacity effects in cheese-inc are not standalone widgets — they're driven by `HomeController.scrollOffset`. Add a comment block to `modular_project`'s `HomeController` (or a mixin) documenting the pattern:

```dart
// Scroll parallax: attach to primary ScrollController in initState
// controller.scrollOffset = RxDouble(0.0)
// scrollController.addListener(() => controller.scrollOffset.value = scrollController.offset);
//
// Nav opacity: Obx(() => opacity = (controller.scrollOffset.value / 120).clamp(0.0, 1.0))
// Hero parallax: Transform.translate(offset: Offset(0, controller.scrollOffset.value * 0.3))
```

### 4. Build: StickySwapSection (New Widget)
Flutter equivalent of Two-Shades-of-Travel `#sticky-swap` (Two-Shades-of-Travel `motion.js:166-260`):
- `NotificationListener<ScrollNotification>` tracks scroll within section height range
- Left column: pinned via `SliverPersistentHeader` or counter-offset `Transform`
- Right column: `AnimatedSwitcher` + `IndexedStack` crossfades images as progress steps
- Progress bar: `Transform.scale(scaleX: progress, alignment: Alignment.centerLeft)`
- File: `lib/core/widgets/sticky_swap_section.dart`

### 5. Build: HorizontalScrollPanels (New Widget)
Apple-style horizontal scroll driven by vertical scroll (Two-Shades-of-Travel `motion.js:262-355`):
- Outer `SizedBox` height = `viewportHeight + (panels - 1) * viewportHeight` (scroll runway)
- `NotificationListener` maps scroll offset → horizontal track position
- `Transform.translate(offset: Offset(-progress * panelWidth, 0))` on track
- Optional progress dots with `AnimatedContainer` indicator
- File: `lib/core/widgets/horizontal_scroll_panels.dart`

### 6. Landing Page Wiring (Deferred — create separate feature)
When ready to apply widgets to the modular_project home screen:
- `TextReveal` on hero headline
- `RevealOnScroll` on feature cards (staggered `delay` param)
- `MagneticWidget` on CTA buttons
- `TiltCard` wrapping service/feature cards
- `MarqueeSection` as section divider
- `CursorOverlay` in `AppShell` (wrap with `kIsWeb` guard)
- Scroll parallax on hero background via `HomeController.scrollOffset`
- Nav fade-in via `HomeController.scrollOffset`

---

## Reference Easings (Flutter Curves equivalents)
| CSS original | Flutter Curve |
|---|---|
| `cubic-bezier(0.16, 1, 0.3, 1)` ease-out-expo | `Cubic(0.16, 1.0, 0.3, 1.0)` |
| `cubic-bezier(0.25, 1, 0.5, 1)` ease-out-quart | `Curves.easeOut` |
| `cubic-bezier(0.76, 0, 0.24, 1)` ease-in-out-quart | `Cubic(0.76, 0.0, 0.24, 1.0)` |
