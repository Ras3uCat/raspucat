# 002_site_audit_fixes

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
Consolidated findings from a full codebase audit conducted 2026-02-25.
Issues are grouped into three tracks: **Critical Bugs**, **Polish**, and **Low Priority**.
No new features — this is a quality, correctness, and SEO pass only.

---

## Sub-Features

This feature is split into three sub-files to stay under the 200-line rule:

- `002_site_audit_fixes/001_critical_bugs.md`
- `002_site_audit_fixes/002_polish.md`
- `002_site_audit_fixes/003_low_priority.md`

---

## Acceptance Criteria (Binary Pass/Fail)

### Critical
- [ ] `isMacOS()`, `isWindows()`, `isLinux()` in `device_utility.dart` return the correct platform.
- [ ] GitHub button in `project_screen.dart` opens the project's GitHub URL.
- [ ] `print(constraints.maxWidth)` removed from `responsive_layout.dart`.

### Polish
- [ ] `web/index.html` has a meaningful `<title>`, `<meta name="description">`, and OG tags.
- [ ] `pubspec.yaml` description is no longer `"A new Flutter project."`.
- [ ] `web/manifest.json` orientation is `"any"`.
- [ ] Unknown route shows a branded 404 screen with a back-to-home link.
- [ ] `main.dart` title uses `EBrand.appName` instead of a hardcoded string.
- [ ] Dashing Beard Co commented image is documented or removed.

### Low Priority
- [ ] Hardcoded `SizedBox(height: 16/48)` in `projects_screen.dart` replaced with `ESizes` constants.
- [ ] Mobile breakpoint detection extracted — no duplication across files.
- [ ] Carousel auto-play interval unified to a single `EDurations` constant.
- [ ] `Image.asset` and `SvgPicture.asset` widgets have `semanticLabel` values.
- [ ] `NeonButton` hover state does not create a new Rx object on every build.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Branded 404 | New `NotFoundScreen` widget | Consistent with brand; gives user a path back |
| SEO meta tags | Static HTML in `web/index.html` | Flutter web doesn't support dynamic head tags at build time |
| Platform fix | Use `GetPlatform.isMacOS/isWindows/isLinux` | Direct fix for copy-paste bug |
| Carousel constant | New `EDurations.carouselAutoPlay` | Centralizes the value; currently 3s vs 4s conflict |

---

## Scope Control
- [x] **Included:** Bug fixes, constants cleanup, SEO/meta, accessibility labels.
- [ ] **NOT Included:** New UI features or layout changes.
- [ ] **NOT Included:** Analytics integration.
- [ ] **NOT Included:** Unit tests (separate feature).
- [ ] **NOT Included:** Image loading optimization (separate feature).
