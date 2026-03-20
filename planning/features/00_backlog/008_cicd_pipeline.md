# 008_cicd_pipeline

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
Set up a CI/CD build pipeline for the Flutter web app. Currently builds are run manually.

---

## Acceptance Criteria

### Build Config
- [ ] `flutter build web` command includes `--web-renderer html` flag (required for SEO text crawlability — see `002_site_audit_fixes`).
- [ ] Build artifacts are deployed to hosting target (GitHub Pages / Vercel / Firebase Hosting — TBD).
- [ ] Pipeline runs on push to `main`.

---

## Notes
- The `--web-renderer html` flag is the **blocking SEO requirement** from `002_site_audit_fixes`. Without it, text is rendered to canvas and invisible to crawlers.
