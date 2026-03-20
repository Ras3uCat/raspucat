# Feature: Client Site Health

**Mode:** STUDIO
**Status:** BACKLOG
**Priority:** High

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

```sql
ALTER TABLE quotes
  ADD COLUMN site_url TEXT,
  ADD COLUMN uptimerobot_monitor_id TEXT,
  ADD COLUMN uptime_status TEXT DEFAULT 'unknown', -- 'up' | 'degraded' | 'down' | 'unknown'
  ADD COLUMN last_uptime_check_at TIMESTAMPTZ,
  ADD COLUMN lighthouse_performance INT,           -- 0–100
  ADD COLUMN lighthouse_accessibility INT,
  ADD COLUMN lighthouse_best_practices INT,
  ADD COLUMN lighthouse_seo INT,
  ADD COLUMN lighthouse_performance_prev INT,      -- previous audit scores for delta calculation
  ADD COLUMN lighthouse_accessibility_prev INT,
  ADD COLUMN lighthouse_best_practices_prev INT,
  ADD COLUMN lighthouse_seo_prev INT,
  ADD COLUMN last_audited_at TIMESTAMPTZ,
  ADD COLUMN open_issues_count INT DEFAULT 0;
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

### UptimeRobot (uptime monitoring)
- **Monitor creation:** When admin sets `site_url` on a quote, a call to `admin-create-monitor` creates the UptimeRobot monitor via API and writes the returned `monitor_id` back to `uptimerobot_monitor_id`
- **Monitor deactivation:** When a quote is cancelled or client churns, `admin-deactivate-monitor` pauses/deletes the UptimeRobot monitor to prevent accumulation against plan limits
- Configure webhook → `supabase/functions/uptimerobot-webhook`
- Webhook payload updates `uptime_status` + `last_uptime_check_at` on the matching quote
- Inserts a `site_events` row on downtime start/end

### PageSpeed Insights API (Lighthouse audits)
- Scheduled Supabase edge function: `run-lighthouse-audits` (weekly cron)
- Calls Google PageSpeed Insights API for each `site_url` where `quotes.status IN ('deposit_paid', 'fully_paid')`
- Writes scores back to `lighthouse_*` columns + `last_audited_at`
- Inserts a `site_events` row with the score snapshot in `payload`

---

## Edge Functions

| Function | Trigger | Purpose |
|---|---|---|
| `uptimerobot-webhook` | POST from UptimeRobot | Update `uptime_status`, log `site_events` |
| `run-lighthouse-audits` | Supabase cron (weekly) | Fetch PageSpeed scores, write to quotes |
| `admin-get-site-health` | Admin dashboard load | Return health summary per quote |
| `admin-create-monitor` | Admin saves `site_url` | Create UptimeRobot monitor, write `monitor_id` back to quote |
| `admin-deactivate-monitor` | Quote cancelled / client churned | Pause or delete UptimeRobot monitor |

---

## Admin Dashboard Integration

### Health badge on `AdminQuoteRow`
- Color-coded indicator next to status badge:
  - Green dot → `uptime_status == 'up'` + lighthouse score ≥ 80
  - Amber dot → any score 50–79 or `uptime_status == 'degraded'`
  - Red dot → `uptime_status == 'down'` or any score < 50
  - Grey dot → `uptime_status == 'unknown'` (no monitor set up yet)

### Health flags for notification badges (extends 006)
- Site has been `down` for > 15 minutes
- Lighthouse performance score dropped > 10 points since last audit
- `last_audited_at` is null or > 14 days ago (audit overdue)
- `open_issues_count > 0`

### Site Health Detail (expandable in quote drawer)
- Last uptime check timestamp + current status
- Lighthouse scores (Performance / Accessibility / Best Practices / SEO) with delta from previous audit (computed from `lighthouse_*_prev` columns, not JSONB parsing)
- Recent `site_events` timeline (last 5 events)
- Link to UptimeRobot monitor (external)

---

## Acceptance Criteria

- [ ] `site_url` is validated as a well-formed `https://` URL before saving
- [ ] Saving `site_url` triggers `admin-create-monitor` and writes `uptimerobot_monitor_id` back to the quote
- [ ] Cancelling/churning a quote triggers `admin-deactivate-monitor` and clears the monitor ID
- [ ] UptimeRobot webhook correctly updates `uptime_status` on the matching quote
- [ ] `run-lighthouse-audits` runs weekly, writes all four scores + `_prev` columns for delta calculation
- [ ] Health badge renders correctly for all four states on `AdminQuoteRow`
- [ ] Notification badge count includes health-based flags alongside billing flags
- [ ] `site_events` log is visible in the quote detail drawer
- [ ] Lighthouse audit cron handles PSI rate limit errors gracefully (log + skip, do not crash)

---

## Architecture Notes

- UptimeRobot webhook must be unauthenticated (UptimeRobot doesn't send custom auth headers) — validate by checking a shared secret passed as a query param (key name: `webhookSecret`, stored in Supabase vault). Always return HTTP 200 even on mismatch to prevent UptimeRobot retry storms; log the rejection instead.
- PageSpeed Insights API key stored in Supabase vault, not in code
- PSI API free tier limit is ~400 requests/day. If client roster exceeds this, stagger audits across the week (e.g. batch by day-of-week modulo client count) rather than running all on one day
- `open_issues_count` is a placeholder column for a future issues-tracking feature. It should default to 0 and not be surfaced in the UI until that feature is defined. Do not build issue open/close logic in this feature.
- `admin-get-site-health` can be merged into `admin-list-quotes` response to avoid a second round-trip — evaluate at implementation time based on payload size
- Health badge state should be derived in `AdminController` from quote fields, not a separate controller
- Do not add a `site_url` field to the client-facing configurator — admin-only input

## Out of Scope

- Automated fix/remediation of site issues
- Client-facing health dashboard
- SMS/email alerts to clients (notify admin only)
- Monitoring non-client (internal) infrastructure
