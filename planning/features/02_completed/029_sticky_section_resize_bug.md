---
id: "029"
title: Bug — Sticky Sections Break on Window Resize
mode: FLOW
status: completed
---

# Bug — Sticky Sections Break on Window Resize

## Symptoms

After resizing the browser window, the scroll-driven sticky animations in "What We Build"
and "How It Works" stop responding. The sticky content either freezes, jumps to the wrong
position, or never advances past the first item.

## Root Cause

Both `_StickySwapSectionState` and `_HorizontalScrollPanelsState` compute `_sectionAbsoluteY`
once in `initState` via `addPostFrameCallback`:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final box = _key.currentContext?.findRenderObject() as RenderBox?;
  if (box != null) {
    _sectionAbsoluteY = box.localToGlobal(Offset.zero).dy + _sc.offset;
  }
});
```

On resize:
1. All sections reflow — the section's absolute Y position changes
2. Viewport height changes — the runway (`viewportH * n`) is recalculated per scroll tick
   but the base offset is wrong
3. `_sectionAbsoluteY` is never refreshed, so the scroll math is permanently off

## Fix

Override `didChangeDependencies` (or implement `WidgetsBindingObserver.didChangeMetrics`)
in both state classes to re-read the section's absolute position after any size change.

`didChangeDependencies` fires when `MediaQuery` changes (which includes window resize on
Flutter web), making it the idiomatic hook:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      _sectionAbsoluteY = box.localToGlobal(Offset.zero).dy + _sc.offset;
    }
  });
}
```

The existing `initState` `postFrameCallback` can then be removed (covered by the first
`didChangeDependencies` call which always fires after `initState`).

## Affected Files

- `lib/common/widgets/sticky_swap_section.dart` — `_StickySwapSectionState`
- `lib/common/widgets/horizontal_scroll_panels.dart` — `_HorizontalScrollPanelsState`

## Acceptance Criteria

- [ ] Resize the window mid-page — sticky animations continue to track correctly
- [ ] Resize from desktop → mobile breakpoint and back — no frozen state
- [ ] No duplicate `postFrameCallback` registrations on every frame
- [ ] `flutter analyze` clean on both files after the change
