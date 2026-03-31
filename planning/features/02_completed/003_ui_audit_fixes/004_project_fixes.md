# 003_ui_audit_fixes / 004_project_fixes

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
Two project-level UX issues: the DarkArc project entry is incomplete (no images, no URLs),
and the project detail view has no visible back/close affordance — the only exit is the
browser back button or clicking outside the modal.

---

## User Stories
- As a visitor, I want every project card to show something meaningful when I tap it.
- As a visitor, I want a visible way to return to the projects list from a detail view.

---

## Acceptance Criteria (Binary Pass/Fail)

### DarkArc Project
- [ ] One of the following is true:
  - DarkArc has at least one image, and a GitHub or live URL — **OR**
  - DarkArc is removed from `project_data.dart` and the carousel.
- [ ] If retained, the placeholder fallback (gradient + code icon) is intentional and documented.
- [ ] Owner decision on DarkArc status is recorded in a comment in `project_data.dart`.

### Project Detail — Back Navigation
- [ ] A visible back/close button exists in the project detail screen.
- [ ] Tapping it returns the user to the projects section.
- [ ] Button uses an existing `NeonButton` or icon button styled with `EColors`.
- [ ] Button is accessible via keyboard (`Tab` focus) on web.
- [ ] Back navigation uses `Get.back()` (not a full route push).

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| DarkArc decision | Owner to confirm | Cannot delete owner's project data without confirmation |
| Back button position | Top-left of detail screen | Convention; consistent with `AppBar` back affordance |
| Back button style | Icon button (`Icons.arrow_back_ios`) with cyan tint | Subtle, on-brand, familiar |

---

## Open Questions (Owner to Confirm Before Moving to Active)
1. Should DarkArc be removed, or do you plan to add images/links for it?

---

## Implementation Detail
**Files modified:**
- `lib/app/data/projects/project_data.dart` — update or remove DarkArc entry
- `lib/app/modules/widgets/project_screen.dart` — add back/close button

---

## Edge Cases & QA
- [ ] Back button does not appear if detail view is accessed as an initial route (edge case).
- [ ] Carousel returns to the same position after navigating back (not reset to first card).
