# 002_site_audit_fixes / 002_polish

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
SEO, meta, manifest, and minor code quality fixes. None of these are crashes —
they hurt discoverability, brand consistency, and user experience on edge paths (e.g., 404).

---

## User Stories
- As a visitor sharing the site link, I want a proper social media preview card.
- As a search engine, I want meaningful meta content to index this site correctly.
- As a visitor who hits an unknown route, I want a branded page with a way back home.
- As a developer, I want string constants used consistently so `EBrand` is the source of truth.

---

## Acceptance Criteria (Binary Pass/Fail)

### SEO — `web/index.html`
- [ ] `<title>` is descriptive (e.g., `Ras3uCat — Flutter & Mobile Developer`).
- [ ] `<meta name="description">` has a meaningful value proposition (not just `"Ras3uCat"`).
- [ ] `<meta property="og:title">` is present.
- [ ] `<meta property="og:description">` is present.
- [ ] `<meta property="og:image">` is present (use site logo or a social card asset).
- [ ] `<meta name="theme-color">` is set to `#000612`.
- [ ] `<meta name="author">` is present.

### Manifest — `web/manifest.json`
- [ ] `"orientation"` is `"any"`.
- [ ] `"description"` matches the HTML meta description.

### pubspec — `pubspec.yaml`
- [ ] `description` field is no longer `"A new Flutter project."`.

### 404 Screen — `main.dart` unknownRoute
- [ ] Unknown routes render a dedicated `NotFoundScreen` widget.
- [ ] `NotFoundScreen` uses brand colors (`#000612` bg, `#58E3EF` text).
- [ ] `NotFoundScreen` includes a button that navigates back to `ERoutes.home`.
- [ ] `NotFoundScreen` text uses `EBrand` or `EStrings` constants, not hardcoded strings.

### Constants consistency — `main.dart`
- [ ] `title:` in `GetMaterialApp` uses `EBrand.appName`.

### Project data — `project_data.dart`
- [ ] The commented-out Dashing Beard Co GIF is either restored, replaced, or the comment
      is replaced with an inline `// Removed: file size exceeded GitHub LFS limit` note.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| OG image | Site logo / `raspucat_512.png` | Already in assets; no new file needed |
| 404 widget location | `lib/app/modules/screens/not_found_screen.dart` | Consistent with screen file pattern |
| 404 copy | "404 — Lost in space." + home button | Matches cyberpunk brand voice |
| `EBrand.appName` | Already defined | Use existing constant, don't add new ones |

---

## Implementation Detail
**Files modified:**
- `web/index.html` — add/update meta tags
- `web/manifest.json` — fix orientation and description
- `pubspec.yaml` — update description
- `main.dart` — use `EBrand.appName`; replace inline 404 scaffold with `NotFoundScreen()`

**Files created:**
- `lib/app/modules/screens/not_found_screen.dart` — branded 404 screen

---

## Edge Cases & QA
- [ ] OG image resolves correctly when link is shared on Twitter/Slack/iMessage.
- [ ] `NotFoundScreen` back button clears the navigation stack (`Get.offAllNamed`).
- [ ] Manifest orientation change does not break PWA install on mobile.
