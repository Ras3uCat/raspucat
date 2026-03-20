# 002_site_audit_fixes

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

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
- [x] `isMacOS()`, `isWindows()`, `isLinux()` in `device_utility.dart` return the correct platform.
- [x] GitHub button in `project_screen.dart` opens the project's GitHub URL.
- [x] `print(constraints.maxWidth)` removed from `responsive_layout.dart`.

### Polish
- [x] `web/index.html` has a meaningful `<title>`, `<meta name="description">`, and OG tags.
- [x] `pubspec.yaml` description is no longer `"A new Flutter project."`.
- [x] `web/manifest.json` orientation is `"any"`.
- [x] Unknown route shows a branded 404 screen with a back-to-home link.
- [x] `main.dart` title uses `EBrand.appName` instead of a hardcoded string.
- [x] Dashing Beard Co commented image is documented or removed.

### SEO / Text Crawlability
- [x] Flutter web build uses the **HTML renderer** (`--web-renderer html`) — confirmed `flt` elements visible in DevTools.
- [x] Verify rendered output in DevTools: confirmed real DOM text elements present.
- [x] Hero section wrapped in `SelectionArea` for copy/paste UX.
- [ ] `flutter build web` CI/CD command updated to include `--web-renderer html` flag (pending CI setup).

### Low Priority
- [x] Hardcoded `SizedBox(height: 16/48)` in `projects_screen.dart` replaced with `ESizes` constants.
- [x] Mobile breakpoint detection extracted — `EDeviceUtils.isMobileWidth()` used across all files.
- [x] Carousel auto-play interval unified to `EDurations.carouselAutoPlay`.
- [x] `Image.asset` and `SvgPicture.asset` widgets have `semanticLabel` values.
- [x] `NeonButton` hover state does not create a new Rx object on every build.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Branded 404 | New `NotFoundScreen` widget | Consistent with brand; gives user a path back |
| SEO meta tags | Static HTML in `web/index.html` | Flutter web doesn't support dynamic head tags at build time |
| Text crawlability | HTML renderer (`--web-renderer html`) | CanvasKit renders to `<canvas>`, making text invisible to search crawlers; HTML renderer outputs real DOM text nodes |
| SelectableText | Wrap key marketing copy | UX improvement for copy/paste; renderer choice handles the crawlability concern |
| Platform fix | Use `GetPlatform.isMacOS/isWindows/isLinux` | Direct fix for copy-paste bug |
| Carousel constant | New `EDurations.carouselAutoPlay` | Centralizes the value; currently 3s vs 4s conflict |

---

## Scope Control
- [x] **Included:** Bug fixes, constants cleanup, SEO/meta, accessibility labels.
- [ ] **NOT Included:** New UI features or layout changes.
- [ ] **NOT Included:** Analytics integration.
- [ ] **NOT Included:** Unit tests (separate feature).
- [ ] **NOT Included:** Image loading optimization (separate feature).
