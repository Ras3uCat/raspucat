# 002_site_audit_fixes / 001_critical_bugs

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
Three critical bugs discovered during the 2026-02-25 audit. All are silent failures —
they either do nothing, return wrong data, or degrade performance without throwing an error.

---

## User Stories
- As a visitor, I want the GitHub button to open the project repo so I can view the source code.
- As a developer, I want platform detection to be correct so platform-gated features work on desktop.
- As a developer, I want no debug output in production so performance is not degraded.

---

## Acceptance Criteria (Binary Pass/Fail)

### Bug 1: Platform Detection (`device_utility.dart:59-69`)
- [ ] `isMacOS()` returns `GetPlatform.isMacOS`.
- [ ] `isWindows()` returns `GetPlatform.isWindows`.
- [ ] `isLinux()` returns `GetPlatform.isLinux`.
- [ ] Manual test: running on Linux confirms `isLinux()` returns `true`.

### Bug 2: GitHub Button (`project_screen.dart:86-87`)
- [ ] Tapping the GitHub button opens `project.githubUrl` in the browser.
- [ ] Button is not rendered if `project.githubUrl` is null (existing guard retained).
- [ ] `EDeviceUtils.launchUrl()` is used (not a raw `url_launcher` call).

### Bug 3: Print Statement (`responsive_layout.dart:20`)
- [ ] `print(constraints.maxWidth)` line is deleted.
- [ ] No `print()` calls remain outside of `kDebugMode` guards in the codebase.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| GitHub link handler | `EDeviceUtils.launchUrl(project.githubUrl!)` | Consistent with existing URL launch pattern |
| Print removal | Delete line, no replacement | Debug artifact, no production value |
| Platform fix | Replace all three incorrect returns | One-line fix per method |

---

## Implementation Detail
**Files modified:**
- `lib/utils/device_utility.dart` — fix lines 59, 64, 69
- `lib/app/modules/widgets/project_screen.dart` — implement `onTap` at line 86
- `lib/common/responsive_layout.dart` — delete `print()` at line 20

---

## Edge Cases & QA
- [ ] `githubUrl` null guard still prevents button from rendering when URL is absent.
- [ ] `launchUrl` error handling (already exists in `EDeviceUtils`) covers invalid URLs.
- [ ] Platform detection tested in both web and native builds.
