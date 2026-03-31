# Strategic Roadmap

## Vision
Raspucat is the internal operations platform for building, delivering, and managing client websites — from quote to live site, all in one admin + client portal.

## Tech Stack (Active)
- **Frontend:** Flutter (GetX) — Material 3 + E-prefix design tokens
- **Backend:** Supabase (PostgreSQL + RLS + Edge Functions)
- **Payments:** Stripe (Checkout + Webhooks)
- **Architecture:** [ADR History](DECISIONS.md)

---

## Release Phases

### Phase 0–3: Foundation → Payments → Portal → Delivery
Status: ✅ COMPLETE (features 001–023)

Key milestones completed:
- Plans section, Stripe integration, Admin dashboard
- Client portal, subscription activation, cancellation handoff
- Email provisioning, delivery progress tracking, module redeploy
- Promo codes, legal pages, Claude harness upgrade

---

### Phase 4: Delivery Pipeline Efficiency
Status: 🏗️ ACTIVE
Goal: Reduce manual effort per client delivery and improve visibility into live client state.

| Priority | Feature | Effort | Value |
|:---:|:---|:---:|:---:|
| 1 | [024 — Discovery Form → client.json](features/00_backlog/024_discovery_form_client_json.md) | M | High |
| 2 | [026 — Smoke Test Auto-Trigger](features/00_backlog/026_smoke_test_auto_trigger.md) | M | Medium |

**Rationale:**
- **024 first** — Each new client delivery requires significant manual `client.json` fill-in. A discovery form compounds value with every engagement.
- **026 second** — High payoff (fully automated delivery gate), but requires coordinated changes to the `modular_project` template repo in addition to this one.

> Note: 025 (Template Version Tracking) was removed — fully implemented under feature 018.

---

### Phase 5: Internal Tooling
Status: 📝 QUEUED
Goal: Improve developer/designer experience and internal brand consistency.

| Priority | Feature | Effort | Value |
|:---:|:---|:---:|:---:|
| 4 | [004 — Brand Kit Screen](features/00_backlog/004_brand_kit_screen.md) | M | Low |

---

## Critical Path & Constraints
- **No active blockers** as of 2026-03-27
- Features 025 and 024 are self-contained to this repo
- Feature 026 requires a coordinated PR in `modular_project` (deliver.sh + Playwright setup)

## Project Guardrails
- All files ≤ 300 lines — extract rather than grow
- No business logic in widgets — controllers only
- All DB changes require a timestamped migration file
- RLS enabled on every table — never expose `service_role` to Flutter

## Success Metrics
- Time from quote-accepted → client site live: target < 2 business days
- Manual steps per delivery: target 0 (fully automated handoff)
- Admin fill-in time for client.json: target < 5 minutes (from ~30 min)
