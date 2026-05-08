---
Title: What We Build — Orbital Section
Mode: STUDIO
Priority: Medium
Status: Backlog
---

## Goal
Add a second "What We Build" section immediately after the existing sticky-swap section. This section uses a **Radial Orbital Timeline** aesthetic: a central glowing orb with the 4 service nodes orbiting it in 3D, auto-rotating, each node expanding into a frosted-glass detail card on tap.

Reference design: https://cdn.21st.dev/bundled/1820.html?theme=dark&dark=true

## Scope

### New Files
- `lib/app/modules/widgets/what_we_build_orbital_section.dart` — thin wrapper, reuses `StickySwapItem` data
- `lib/common/widgets/orbital_timeline.dart` — core StatefulWidget, rotation ticker, expansion state
- `lib/common/widgets/_orbital_node.dart` — individual orbiting node (icon + label + detail card)
- `lib/common/widgets/_orbital_center_orb.dart` — central pulsing gradient orb with ring animations
- `lib/common/widgets/_orbital_node_card.dart` — expanded detail card (frosted glass, energy bar)

### Modified Files
- `lib/common/responsive/screens/desktop_layout.dart` — add `WhatWeBuildOrbitalSection()` after line 61

## Acceptance Criteria
- [ ] Section renders on desktop immediately below the sticky-swap `WhatWeBuildSection`
- [ ] 4 nodes orbit the central orb continuously at ~6°/s (0.3° per 50ms tick)
- [ ] Nodes have opacity variation simulating depth (front = 1.0, back = 0.4)
- [ ] Clicking a node pauses rotation, expands detail card; clicking background resumes
- [ ] Detail card shows: title, body text, `EColors`-accented energy bar, service color accent
- [ ] Mobile: orbital hidden, falls back to a stacked card list (no crash)
- [ ] `flutter analyze` returns zero new warnings
- [ ] No magic numbers — all sizes/colors use `ESizes` / `EColors` constants

## Design Tokens
- Background: `EColors.backgroundDark`
- Orbit ring: `Colors.white.withValues(alpha: 0.1)`
- Orb gradient: `EColors.primary` → `EColors.accent` (cyan → magenta)
- Node active border glow: `Colors.white` shadow
- Card bg: `Colors.black.withValues(alpha: 0.9)` + `BackdropFilter` blur
- Energy bar fill: `EColors.primary` → `EColors.accent`
