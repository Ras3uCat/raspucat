# 034 — Follow-up Timing Reads from Settings

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`outreach_settings.follow_up_days` is configurable in the admin panel and persisted to the DB.
But `admin-outreach-email` hardcodes `+3 days` for `next_followup_at` in three places.
The setting is fetched and displayed in Flutter but never used by the backend.

---

## User Stories
- As the business owner, I want to change the follow-up cadence from 3 days to 5 days in
  settings and have it take effect immediately without touching code.

---

## Acceptance Criteria
- [ ] `send` action sets `next_followup_at = now + settings.follow_up_days` (added to existing settings SELECT — no extra round-trip).
- [ ] `send-batch` loads `follow_up_days` once before the batch loop; each email uses that value.
- [ ] `auto-draft-followups` reschedules `next_followup_at = now + settings.follow_up_days`.
- [ ] If `outreach_settings` row is missing, falls back to 3 days.
- [ ] Negative or zero `follow_up_days` is clamped to `max(1, followUpDays)` before computing the timestamp.
- [ ] Changing `followUpDays` in admin settings → next send uses the new value (no Flutter changes needed — settings are already persisted by the admin panel).

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Settings load | Load once at top of each action | Avoid N+1; settings is a singleton |
| Fallback | 3 days if settings row missing | Safe default, matches current behavior |

---

## Scope Control
- [x] Included: Three hardcoded `+3 day` locations replaced with `settings.follow_up_days`
- [ ] NOT Included: Per-lead override of follow-up timing
- [ ] NOT Included: Timezone support for follow-up scheduling
- [ ] NOT Included: Flutter UI changes (admin panel already persists `follow_up_days` to DB)
- [ ] NOT Included: `send-batch` idempotency — see feature 038. Implement 034 first to avoid merge conflicts.

---

## Implementation Detail

**File:** `supabase/functions/admin-outreach-email/index.ts`

For each of the three actions (`send`, `send-batch`, `auto-draft-followups`), add a settings
load before the timing calculation:

```ts
// Use maybeSingle() — single() throws if no row exists; ?? 3 fallback would never fire
const { data: settings } = await supabase
  .from('outreach_settings').select('follow_up_days').limit(1).maybeSingle();
const followUpDays = Math.max(1, settings?.follow_up_days ?? 3);
const followupAt = new Date(Date.now() + followUpDays * 24 * 60 * 60 * 1000).toISOString();
```

`send` action already has an isolated settings query for other fields — add `follow_up_days`
to that existing SELECT to avoid a second round-trip.

`send-batch` and `auto-draft-followups` each need one settings load added **before the batch
loop begins** — not once per iteration.

---

## Edge Cases & QA
- [ ] `follow_up_days = 0` or negative → clamped to 1 via `Math.max(1, ...)`. Confirmed decision: 0/negative values from the admin panel are a misconfiguration, not a valid scheduling intent.
- [ ] `outreach_settings` row missing → `maybeSingle()` returns `null` → `?? 3` → 3-day default.
- [ ] Negative DB values: consider adding `CHECK (follow_up_days >= 1)` constraint in a follow-up migration to enforce at the DB level.
- [ ] Verify `send-batch` loads settings once before the loop — not once per email.
- [ ] Verify `send` action does not add a second `outreach_settings` SELECT (piggybacks on existing query).
