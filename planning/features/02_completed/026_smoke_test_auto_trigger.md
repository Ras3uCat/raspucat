# 026 — Smoke Test Auto-Trigger (Playwright → Raspucat Callback)

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Complete

## Mode
STUDIO

## Context
The modular_project template includes Playwright test specs (feature 109) covering
auth, booking, and admin flows. Currently `smoke_test_passed` is checked manually in the
Raspucat admin delivery checklist. Wiring `deliver.sh --smoke-test` to run Playwright
and POST the result back to Raspucat would advance the client portal to "Deployed"
automatically — removing a manual step from every delivery.

## What Needs To Change
- Add `--smoke-test` flag to `deliver.sh` in modular_project
- After build, run `cd qa && npx playwright test` (config in `qa/playwright.config.js` handles `testDir: ./chrome` and reporters — do NOT pass `--reporter=json`)
- Set `BASE_URL` env var from `client.json` `SITE_URL` before invoking Playwright (`qa/playwright.config.js`, relative to project root, reads `process.env.BASE_URL`)
- Parse pass/fail from Playwright exit code
- POST to Raspucat `admin-delivery-progress` (upsert action) with body:
  `{ quoteId, adminToken, action: "upsert", step: "smoke_test_passed", checked: true|false, checked_by: "system" }`
  — `quoteId` from `RASPUCAT_QUOTE_ID`, `adminToken` from `RASPUCAT_ADMIN_TOKEN`
- Raspucat `admin-delivery-progress` already handles this step — no backend change needed
- Side effect: when `checked: true`, backend auto-advances `portal_stage → "deployed"` (no extra call needed)

## Acceptance Criteria
- [ ] `deliver.sh --smoke-test` runs Playwright suite against `BASE_URL` (set from client.json `SITE_URL`) after build
- [ ] Requires `SITE_URL` to be set and live (skips gracefully if not reachable)
- [ ] On all-pass: POSTs `{ quoteId, adminToken, action: "upsert", step: "smoke_test_passed", checked: true, checked_by: "system" }` → Raspucat auto-advances `portal_stage` to `"deployed"`
- [ ] On any failure: POSTs same body with `checked: false` + prints failing test names to console
- [ ] Smoke test step is skipped silently if `qa/node_modules` not installed (non-fatal)
- [ ] Raspucat admin delivery checklist shows `smoke_test_passed` auto-checked with `checked_by: system`
- [ ] Client portal `portal_stage` advances to `"deployed"` after a passing smoke test (verify in portal UI)

## Scope (files to create/modify — in modular_project)
- `execution/frontend/app/deliver.sh` (add --smoke-test flag + Playwright invocation + callback; POST body must include `checked_by: "system"`)
- `execution/frontend/app/client.json.example` (document that `RASPUCAT_QUOTE_ID`, `RASPUCAT_API`, `RASPUCAT_ADMIN_TOKEN` are required for `--smoke-test` — fields already present, just add inline comment; `RASPUCAT_ADMIN_TOKEN` maps to `adminToken` in the POST body)
- `qa/README.md` (document --smoke-test flag usage and `BASE_URL` env var)

## Dependencies
- Playwright specs exist in `qa/chrome/` (auth_flows, booking_flow, admin_flows) — not a blocker
- `RASPUCAT_QUOTE_ID`, `RASPUCAT_API`, `RASPUCAT_ADMIN_TOKEN` must be set in client.json (fields already in `client.json.example`)
- `SITE_URL` (used as `BASE_URL` for Playwright) must be live and reachable at time of smoke test
