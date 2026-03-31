# 027 — New Personality Presets: Raspucat Dropdown Update

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Complete

## Mode
STUDIO

## Context
modular_project feature 112 is **complete** — all 9 new personalities and hamburger nav are
implemented in `_personality_presets.dart` and `app_shell.dart`. The remaining work is
Raspucat-only: the client portal discovery form (`portal_discovery_form.dart`) only exposes
`edgy` and `playful` in its personality dropdown. The other 7 need to be added.

`NAV_STYLE: hamburger` is already in the nav dropdown — no change needed there.

---

## Scope

Add 7 missing entries to `_personalities` in `portal_discovery_form.dart`:

| Key | Label |
|---|---|
| `artisan` | Artisan & handcrafted |
| `wellness` | Wellness & holistic |
| `tech` | Tech & modern |
| `retro` | Retro & nostalgic |
| `nature` | Nature & eco |
| `creative` | Creative & expressive |
| `nightlife` | Nightlife & dining |

The existing 5 originals (`luxury`, `bold`, `warm`, `minimal`, `corporate`) should also be
present — check whether they are already in the dropdown or are currently free-text only.

**File:** `lib/app/modules/widgets/portal_discovery_form.dart`

---

## Acceptance Criteria
- [ ] All 14 personalities are selectable in the client portal discovery form dropdown
- [ ] `portal_discovery_form.dart` stays under 300 lines
- [ ] `flutter analyze` — zero issues

## Dependencies
- 024 complete ✅
- modular_project 112 complete ✅
