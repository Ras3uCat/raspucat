# 002_site_audit_fixes / 003_low_priority

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

---

## Overview
Code quality, DRY violations, accessibility, and minor performance improvements.
None of these affect functionality today but will compound as the codebase grows.
Recommended to batch these into a single "cleanup sprint."

---

## User Stories
- As a screen reader user, I want images and buttons to have labels so I can navigate the site.
- As a developer, I want magic numbers replaced with named constants so changes are made in one place.
- As a developer, I want mobile detection logic in one place so breakpoints are consistent.

---

## Acceptance Criteria (Binary Pass/Fail)

### Accessibility
- [x] All `Image.asset()` calls include `semanticLabel`.
- [x] All `SvgPicture.asset()` calls include `semanticLabel`.
- [ ] `NeonButton` wraps its child with a `Tooltip` or `Semantics` label where the purpose
      is not obvious from text alone (e.g., icon-only buttons).

### Constants — Spacing
- [x] `SizedBox(height: 16)` in `projects_screen.dart:30` replaced with `ESizes.spaceBtwItems`.
- [x] `SizedBox(height: 48)` in `projects_screen.dart:46` replaced with `ESizes.spaceBtwSections`.
- [x] `project_screen.dart` spacing — verified already using `ESizes` constants, no changes needed.
- [x] `margin: EdgeInsets.symmetric(horizontal: 8)` in `projects_carousel.dart:77`
      replaced with `ESizes.sm`.

### Constants — Durations
- [x] `EDurations.carouselAutoPlay` constant added (value: `Duration(seconds: 4)`).
- [x] `EDurations.carouselAnimation` constant added (value: `Duration(milliseconds: 800)`).
- [x] `projects_carousel.dart` uses `EDurations.carouselAutoPlay`.
- [x] Carousel auto-play interval is unified to one constant.

### DRY — Mobile Detection
- [x] `EDeviceUtils.isMobileWidth(double width)` helper added.
- [x] `projects_carousel.dart` uses the shared utility.
- [x] Remaining files updated: `site_footer`, `dialog`, `plans_screen`, `plan_configurator_overlay`.

### NeonButton — Hover State
- [x] `isHovered` is not recreated on every `build()` call.
- [x] Converted to `StatefulWidget` with `_isHovered` bool in state.

### NeonText — Global State
- [x] `AutoSizeGroup headline` and `defaultGroup` moved to `static final` inside `NeonText`.
- [x] No file-level globals remain.

### Parallax — Magic Numbers (`triangle_widget.dart`)
- [x] Magic numbers `40` and `120` replaced with named constants `parallaxMinSize` and `parallaxSizeRange` with explanatory comments.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Mobile utility method | `EDeviceUtils.isMobileWidth(double width)` | Keeps existing pattern; no architectural change |
| Carousel constants | Add to `lib/utils/constants/durations.dart` (create if missing) | Follows existing `ESizes` / `EColors` pattern |
| NeonButton refactor | `StatefulWidget` | Simpler than a controller for single-widget state |
| Parallax constants | Inline named constants in `triangle_widget.dart` | Too specific to extract to global file |

---

## Implementation Detail
**Files modified:**
- `lib/app/modules/screens/projects_screen.dart` — spacing constants
- `lib/app/modules/widgets/project_screen.dart` — spacing constants, semantic labels
- `lib/app/modules/widgets/projects_carousel.dart` — duration constant, spacing, mobile utility
- `lib/app/modules/widgets/center_logo.dart` — semantic label on SVG
- `lib/common/widgets/neon_button.dart` — hover state refactor
- `lib/common/widgets/neon_text.dart` — global state cleanup
- `lib/common/widgets/triangle_widget.dart` — named parallax constants
- `lib/utils/device_utility.dart` — add `isMobileWidth()` helper

**Files created (if missing):**
- `lib/utils/constants/durations.dart` — `EDurations` class with carousel constants

---

## Edge Cases & QA
- [ ] Carousel timing change (if any) does not break animation on slow connections.
- [ ] Accessibility labels pass a basic VoiceOver / TalkBack manual test.
- [ ] Mobile layout unchanged after breakpoint detection refactor.
- [ ] No visual regression in `NeonButton` after hover state refactor.
