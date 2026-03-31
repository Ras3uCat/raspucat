# Feature: Client Site Health

**Mode:** STUDIO
**Status:** COMPLETE

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

---

## Problem

As the client roster grows, manually checking each site for downtime, performance regressions, and stale content becomes unmanageable. There is no centralized visibility into whether active clients' sites are healthy, and no alerting when something goes wrong.

## Goals

1. Passive uptime monitoring with zero manual effort
2. Periodic Lighthouse audits per client site
3. Health badges surfaced in the admin dashboard
4. Webhook-driven alerts from external monitors into Supabase

---

## Data Model

### New column additions to `quotes` table

> **Note:** `site_url` already exists (migration 20260320000003). Do not re-add it.
> `supabase_project_ref` already exists (migration 20260322000001). Use it instead of a
> separate `supabase_url` column for the Supabase deliverable URL.

```sql
-- Migration: 20260322000003_site_health.sql
ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS uptimerobot_monitor_id TEXT,
  ADD COLUMN IF NOT EXISTS uptime_status TEXT DEFAULT 'unknown', -- 'up' | 'degraded' | 'down' | 'unknown'
  ADD COLUMN IF NOT EXISTS last_uptime_check_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS lighthouse_performance INT,           -- 0–100
  ADD COLUMN IF NOT EXISTS lighthouse_accessibility INT,
  ADD COLUMN IF NOT EXISTS lighthouse_best_practices INT,
  ADD COLUMN IF NOT EXISTS lighthouse_seo INT,
  ADD COLUMN IF NOT EXISTS lighthouse_performance_prev INT,
  ADD COLUMN IF NOT EXISTS lighthouse_accessibility_prev INT,
  ADD COLUMN IF NOT EXISTS lighthouse_best_practices_prev INT,
  ADD COLUMN IF NOT EXISTS lighthouse_seo_prev INT,
  ADD COLUMN IF NOT EXISTS last_audited_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS open_issues_count INT DEFAULT 0;
```

### New `site_events` table (health incident log)

```sql
CREATE TABLE site_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,  -- 'downtime_start' | 'downtime_end' | 'audit_completed' | 'issue_opened' | 'issue_resolved'
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

---

## External Integrations

### Site Registration — deliver.sh integration

After a successful deploy, `deliver.sh` POSTs to **two** endpoints (both fire-and-forget,
non-blocking, only if `RASPUCAT_QUOTE_ID` + `RASPUCAT_API` + `RASPUCAT_ADMIN_TOKEN` are set):

1. `admin-delivery-progress` — already implemented (feature 016)
2. `admin-register-site` — new in this feature:
   ```bash
   curl -sf -X POST "${RASPUCAT_API}/functions/v1/admin-register-site" \
     -H "Content-Type: application/json" \
     -d "{\"adminToken\":\"${RASPUCAT_ADMIN_TOKEN}\",\"quoteId\":\"${RASPUCAT_QUOTE_ID}\",\"siteUrl\":\"${SITE_URL}\",\"clientSlug\":\"${CLIENT_SLUG}\"}" \
     2>/dev/null || true
   ```

`admin-register-site`:
1. Writes `site_url` to the matching `quotes` row (idempotent)
2. Calls `admin-create-monitor` to start UptimeRobot monitoring
3. Auto-populates `portal_deliverables` based on modules already on the quote
4. Calls `admin-delivery-progress` internally to auto-check `site_registered` and
   `uptime_robot_active` delivery steps (both `checked_by: 'system'`)

For clients not built with modular_project, admin can manually enter `site_url` in the
quote detail drawer — saving it also triggers `admin-create-monitor`.

### Auto-populated Deliverables (on `admin-register-site`)

`admin-register-site` upserts the following rows into `portal_deliverables`:

| Deliverable | Value source | Always? |
|---|---|---|
| Live site URL | `siteUrl` from POST body | Yes |
| Admin panel URL | `{siteUrl}/auth` | Yes |
| Supabase project URL | derived from `quotes.supabase_project_ref` | If `supabase_project_ref` set |
| Booking admin URL | `{siteUrl}/admin/bookings` | If `booking` in modules |
| Shop admin URL | `{siteUrl}/admin/shop` | If `shop` in modules |
| Events admin URL | `{siteUrl}/admin/events` | If `events` in modules |

> Additional deliverables (repo links, brand kit, DNS records) are added manually via the portal.

### UptimeRobot (uptime monitoring)

- **API key:** stored as Supabase secret `UPTIMEROBOT_API_KEY`
- **Status updates:** `poll-uptime-status` cron (every 30 min) calls `getMonitors` API,
  updates `uptime_status` + `last_uptime_check_at`, logs `downtime_start`/`downtime_end`
  events to `site_events` on status transitions. Handles pagination automatically.
  > Webhooks require UptimeRobot Team/Enterprise. Polling on free tier is sufficient for
  > a health dashboard — 30-min resolution is fine for visibility, not incident response.
- **Monitor creation:** triggered by `admin-register-site` or when admin manually saves
  `site_url` in the admin drawer — calls `admin-create-monitor`, writes returned
  `monitor_id` back to `quotes.uptimerobot_monitor_id`
- **Monitor deactivation:** when a quote is cancelled, `admin-cancel-subscription` calls
  `admin-deactivate-monitor` before returning — pauses/deletes the UptimeRobot monitor
  and clears `uptimerobot_monitor_id` on the quote
- **Free tier capacity:** 50 monitors. Upgrade to Pro (~$7/mo) for 1000+ monitors.
  No code changes needed when upgrading — pagination is already handled.

### PageSpeed Insights API (Lighthouse audits)

- **API key:** stored as Supabase secret `PAGESPEED_API_KEY`
- **Scheduled function:** `run-lighthouse-audits` (weekly cron — see manual steps below)
- Runs for all quotes where `status IN ('pending', 'deposit_paid', 'fully_paid', 'active')`
  and `site_url IS NOT NULL`
- Writes scores to `lighthouse_*` columns; copies current to `*_prev` before overwriting
- Inserts a `site_events` row with score snapshot in `payload`
- **Rate limiting:** PSI free tier is ~400 req/day. If client count exceeds 400/7 ≈ 57,
  stagger audits across the week: `WHERE (EXTRACT(DOW FROM now()) = (quote_row_number % 7))`
  so each client is audited on a fixed day of the week. Log + skip on PSI errors (do not crash).

---

## Edge Functions

| Function | Trigger | Purpose |
|---|---|---|
| `admin-register-site` | POST from `deliver.sh` after deploy, or admin saves `site_url` | Write `site_url`, trigger monitor, populate deliverables, auto-check delivery steps |
| `admin-create-monitor` | Called internally by `admin-register-site` | Create UptimeRobot monitor, write `monitor_id` to quote |
| `admin-deactivate-monitor` | Called by `admin-cancel-subscription` on cancellation | Pause/delete UptimeRobot monitor, clear `monitor_id` |
| `poll-uptime-status` | Supabase cron (every 30 min) | Call UptimeRobot `getMonitors` API, update `uptime_status`, log `site_events` on transitions |
| `run-lighthouse-audits` | Supabase cron (weekly) | Fetch PSI scores, write to quotes with prev-score delta |

> `admin-get-site-health` merged into `admin-list-quotes` — health fields are already on
> the quotes row, no second round-trip needed.

---

## Admin Dashboard Integration

### `site_url` input in quote detail drawer

- New editable text field in the Details tab ("Site URL") — admin-only input
- Saving triggers `admin-register-site` (which creates the UptimeRobot monitor)
- Validated as a well-formed `https://` URL before saving
- Shown as a link if already set

### Health badge on `AdminQuoteRow`

Color-coded dot next to the status badge:
- 🟢 Green → `uptime_status == 'up'` + all lighthouse scores ≥ 80
- 🟡 Amber → any score 50–79 or `uptime_status == 'degraded'`
- 🔴 Red → `uptime_status == 'down'` or any score < 50
- ⚫ Grey → `uptime_status == 'unknown'` (no monitor yet)

Only shown for quotes with `site_url` set. Badge state derived in `AdminController`,
not a separate controller.

### Site Health section in quote detail drawer

New collapsible section in the Details tab (below Dates):
- Current uptime status + last check timestamp
- Lighthouse scores: Performance / Accessibility / Best Practices / SEO
  — each shown with Δ delta from previous audit (from `*_prev` columns)
- Recent `site_events` timeline (last 5 events)
- Link to UptimeRobot monitor dashboard (external)

---

## Acceptance Criteria

- [x] Migration adds all new columns without conflicting with existing `site_url`
- [x] `site_url` input in admin drawer validates `https://` format before saving
- [x] Saving `site_url` triggers `admin-create-monitor` and writes `uptimerobot_monitor_id`
- [x] `admin-register-site` auto-checks `site_registered` + `uptime_robot_active` in `delivery_progress`
- [x] `admin-register-site` auto-populates `portal_deliverables` based on quote modules
- [x] Cancelling a quote triggers `admin-deactivate-monitor` and clears `monitor_id`
- [x] ~~UptimeRobot webhook~~ → replaced by `poll-uptime-status` cron (every 30 min) — free tier compatible; updates status + logs `site_events` on transitions
- [x] `run-lighthouse-audits` runs for all quotes with `site_url` including `status='active'`
- [x] PSI stagger logic prevents >57 audits/day (modulo day-of-week)
- [x] PSI errors are logged + skipped — function does not crash
- [x] `*_prev` scores copied before overwriting for delta calculation
- [x] Health badge renders correctly for all four states on `AdminQuoteRow`
- [x] Site Health section shows scores + deltas + recent events in detail drawer
- [x] `deliver.sh` POSTs to `admin-register-site` after deploy (non-blocking)

---

## Manual Steps (post-implementation)

- Set `UPTIMEROBOT_API_KEY` in Raspucat Supabase secrets
- Set `PAGESPEED_API_KEY` in Raspucat Supabase secrets
- Schedule `poll-uptime-status` cron in Supabase dashboard: `*/30 * * * *` (every 30 min)
- Schedule `run-lighthouse-audits` cron in Supabase dashboard: `0 3 * * 1` (weekly, Mondays at 3am UTC)
- ~~`UPTIMEROBOT_WEBHOOK_SECRET`~~ — not needed; polling replaces webhook (free tier compatible)

---

## Dependencies

- Feature 016 (delivery progress) — `admin-register-site` calls `admin-delivery-progress` to auto-check steps ✅ complete
- `supabase_project_ref` on quotes (migration 20260322000001) ✅ complete
- `portal_deliverables` table (migration 20260320000003) ✅ complete

---

## Out of Scope

- Automated fix/remediation of site issues
- Client-facing health dashboard
- SMS/email alerts to clients (notify admin only)
- Monitoring non-client (internal) infrastructure
- `open_issues_count` UI (column exists, feature not yet defined)
