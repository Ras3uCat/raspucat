---
id: "028"
title: Mobile Layout — Sticky Sections
mode: STUDIO
status: backlog
---

# Mobile Layout — Sticky Sections

## Context

Both scroll-driven sections on the home screen degrade to static fallbacks on mobile
(`size.width < ESizes.mobile` = 700px). The desktop animations rely on a `GlobalKey`
that only attaches when the desktop `SizedBox` renders, so `_sectionAbsoluteY` stays
`-1` on mobile and the scroll math never fires.

Affected files:
- `lib/common/widgets/sticky_swap_section.dart` → `_MobileSwapList` (What We Build)
- `lib/common/widgets/horizontal_scroll_panels.dart` → `_MobilePanelStack` (How It Works)

## Goal

Both sections should feel intentional and engaging on mobile without breaking the
existing desktop/tablet experience.

## Proposed Approach

### What We Build (`StickySwapSection`)
Replace `_MobileSwapList` static cards with a vertical scroll-reveal list:
- Each card fades + slides up as it enters the viewport
- Use `Visibility` + `AnimationController` driven by an `IntersectionObserver`-style
  scroll listener on `EScrollController`
- No sticky required — sequential reveal is the right mobile pattern

### How It Works (`HorizontalScrollPanels`)
Replace `_MobilePanelStack` with a `PageView` carousel:
- Fixed height (`viewportH * 0.85`)
- Horizontal swipe between panels
- Dot indicator at the bottom (same `_DotIndicator` style as desktop)
- `PageController` + `onPageChanged` to drive dot state
- Must be a `StatefulWidget`

## Constraints
- Desktop path (`size.width >= ESizes.mobile`) must not be touched
- `_key` / `_sectionAbsoluteY` initialization stays desktop-only
- No raw size or color values — `ESizes` / `EColors` tokens only
- 300-line file limit — extract if needed
- Analyzer must be clean before marking complete

## Acceptance Criteria
- [ ] On a 390px-wide viewport, "What We Build" cards animate in on scroll
- [ ] On a 390px-wide viewport, "How It Works" panels are swipeable with dot indicator
- [ ] Desktop (≥ 700px) sticky scroll behavior is unchanged
- [ ] `flutter analyze` reports no warnings on changed files
- [ ] No `StatefulWidget` used for business logic — animation state only
