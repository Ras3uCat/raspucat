# 003_ui_audit_fixes / 002_hero_section

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
The hero section has a `NeonButton` that is commented out, leaving the page with no CTA.
There is also no clear next action for a visitor. This sub-feature uncomments and styles
the CTA and reviews the tagline to better reflect the brand voice.

---

## User Stories
- As a visitor, I want a clear CTA so I know what to do after reading the hero.
- As a visitor, I want the tagline to feel unique to this brand, not generic.

---

## Acceptance Criteria (Binary Pass/Fail)
- [ ] A `NeonButton` CTA is visible in the hero section.
- [ ] The CTA label and action are confirmed by the owner before implementation.
- [ ] Tagline copy is reviewed — updated or signed off as intentional by the owner.
- [ ] CTA animates in with the same staggered entrance pattern as the heading/tagline.
- [ ] CTA is keyboard-focusable and has a `semanticLabel`.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| CTA action | Scroll to Projects section | Most natural next step; no external dependency |
| CTA label | `"EXPLORE WORK"` (placeholder) | Matches all-caps brand voice — owner to confirm |
| Tagline | Owner to confirm | Current tagline is functional but generic |
| CTA animation delay | After heading + tagline (3rd in stagger) | Maintains existing entrance sequence |

---

## Open Questions (Owner to Confirm Before Moving to Active)
1. What should the CTA button say and do? (Scroll to projects / open contact / external link?)
2. Is the current tagline intentional, or should it be updated to match the M3OW brand voice?

---

## Implementation Detail
**Files modified:**
- `lib/app/modules/screens/home_screen.dart` — uncomment and configure NeonButton CTA
- `lib/utils/constants/text.dart` — add CTA label string to `EStrings`

---

## Edge Cases & QA
- [ ] CTA does not overlap the logo or tagline on small screens.
- [ ] Button glow effect does not cause visual clutter on the animated triangle background.
