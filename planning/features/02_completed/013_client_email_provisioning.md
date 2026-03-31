# 013 — Client Email Provisioning (Cloudflare Email Routing)

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

---

## Overview

When a new client quote is created in the admin panel, automatically provision a dedicated
email address at `raspucat.com` (e.g. `footballwinner@raspucat.com`) via the Cloudflare
Email Routing API. This address is used to:

1. Register the client's Supabase project (so each project has a distinct owner email)
2. Serve as the canonical identity for that client within your infrastructure
3. Forward to your personal inbox so you still receive any emails sent to it

---

## Problem

- Every client's Supabase project is currently created with the same personal email, making
  it hard to distinguish projects in the Supabase dashboard and in billing/audit trails
- No clean per-client identity for infrastructure accounts (Stripe, UptimeRobot, Vercel, etc.)
- Manual setup of forwarding addresses is tedious and easy to forget

---

## Proposed Flow

```
Admin creates new quote (enters client/site name)
  ↓
admin-provision-client-email edge function
  ├─ Derive slug from site name (e.g. "Football Winner" → "footballwinner")
  ├─ Check quotes.client_slug for collision — append numeric suffix if taken
  ├─ POST to Cloudflare Email Routing API → create rule:
  │    footballwinner@raspucat.com → forwards to admin's personal inbox
  ├─ Write client_slug + provisioned_email + cloudflare_routing_rule_id to quote
  └─ Display generated address in admin quote detail for copy/paste use
```

---

## Slug Derivation Rules

| Input | Output |
|-------|--------|
| `Football Winner` | `footballwinner` |
| `Acme Studio` | `acmestudio` |
| `Joe's Barbershop` | `joesbarbershop` |
| `The Blue Door Café` | `thebluedoorcafe` |

- Lowercase, strip spaces, strip non-alphanumeric characters (except hyphens if desired)
- Max 50 chars (Cloudflare local-part limit)
- If the derived slug is already taken (query `quotes.client_slug`), append a numeric suffix: `acmestudio2`
- Admin can override the slug before provisioning if needed

---

## Data Model

### New columns on `quotes` table

```sql
ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS provisioned_email TEXT,           -- e.g. footballwinner@raspucat.com
  ADD COLUMN IF NOT EXISTS cloudflare_routing_rule_id TEXT,  -- rule ID for deactivation
  ADD COLUMN IF NOT EXISTS client_email_provisioned_at TIMESTAMPTZ;
  -- NOTE: client_slug (text) already exists from migration 20260323000002
  -- NOTE: quotes.client_email (text not null) is the client's personal account email — do NOT confuse
```

### Column responsibilities

| Column | Purpose | Written by |
|---|---|---|
| `client_email` | Client's personal account email (pre-existing) | Admin at quote creation |
| `client_slug` | Slug for infra identity (e.g. `footballwinner`) | `admin-provision-client-email` at quote creation; `admin-register-site` can override at deploy |
| `provisioned_email` | Full provisioned address (`footballwinner@raspucat.com`) | `admin-provision-client-email` |
| `cloudflare_routing_rule_id` | Cloudflare rule ID for future deletion | `admin-provision-client-email` |
| `client_email_provisioned_at` | Timestamp of provisioning | `admin-provision-client-email` |

---

## Edge Functions

| Function | Trigger | Purpose |
|---|---|---|
| `admin-provision-client-email` | Admin creates/saves quote | Derive slug, call Cloudflare API, write result to quote |
| `admin-deprovision-client-email` | Manual trigger or cron | Delete Cloudflare routing rule, clear `provisioned_email` + `cloudflare_routing_rule_id` |
| `cleanup-expired-client-emails` | Supabase cron (daily) | Deprovision rules for quotes cancelled > 90 days ago |

### Cloudflare API call (provision)

```
POST https://api.cloudflare.com/client/v4/zones/{zone_id}/email/routing/rules
Authorization: Bearer {CLOUDFLARE_API_TOKEN}

{
  "name": "Client: Football Winner",
  "enabled": true,
  "matchers": [{ "type": "literal", "field": "to", "value": "footballwinner@raspucat.com" }],
  "actions": [{ "type": "forward", "value": ["admin@personalemail.com"] }]
}
```

- `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ZONE_ID` stored in Supabase vault
- `CLOUDFLARE_FORWARD_TO` — admin's personal inbox email; must be verified in Cloudflare
  Email Routing settings before first use; stored in Supabase vault (never hardcoded)

### Cloudflare API call (deprovision)

```
DELETE https://api.cloudflare.com/client/v4/zones/{zone_id}/email/routing/rules/{rule_id}
```

> Deprovision is **not immediate on cancellation**. The routing rule is kept active for 90 days
> after `cancelled_at` to allow for post-cancellation password resets, Supabase account
> transfers, and any other infrastructure access the client may still need under that email.
> After 90 days a scheduled Supabase cron (`cleanup-expired-client-emails`) calls
> `admin-deprovision-client-email` for any quotes where
> `cancelled_at < now() - interval '90 days'` and `cloudflare_routing_rule_id IS NOT NULL`.
> Admin can also trigger early deprovisioning manually from the quote detail drawer.

---

## Admin Panel Integration

- **Quote creation form:** show a "Provision Email" button after client name is entered
  - Pre-fills the slug preview (editable)
  - Button calls `admin-provision-client-email`
  - On success: shows `footballwinner@raspucat.com` with a copy button
- **Quote detail drawer:** show the provisioned address with a copy button and a link to
  Cloudflare dashboard for that rule
- **Quote cancelled:** routing rule is retained for 90 days (for password resets, Supabase
  account transfers etc.) — a scheduled cron handles cleanup after the retention window
- **Manual early deprovision:** admin can delete the rule immediately from the quote detail
  drawer if needed (e.g. client relationship ended badly)

---

## Workflow: Creating a Supabase Project for the Client

Once the address is provisioned:

1. Copy `footballwinner@raspucat.com` from the quote detail
2. Go to [supabase.com](https://supabase.com) → create new project
3. Sign up / invite using the provisioned address
4. Any Supabase emails (confirmations, billing alerts) land in your inbox via forwarding
5. Enter the resulting `SUPABASE_URL` and `SUPABASE_ANON_KEY` into the client's `client.json`

> This is a manual step — Supabase does not have a public API for project creation.
> The provisioned email just gives you a clean, consistent identity per project.

---

## Interaction with `deliver.sh` / `admin-register-site`

`admin-provision-client-email` sets `client_slug` at quote creation — this is the canonical
write point. `admin-register-site` (called by `deliver.sh` at deploy time) still accepts a
`clientSlug` param and will overwrite if passed. Since the provisioned slug IS the correct
value, `deliver.sh` does not need to pass `clientSlug` again once 013 is live. Existing
deployments that already pass `clientSlug` will continue to work (idempotent overwrite).

---

## Acceptance Criteria

- [ ] Entering a client name auto-derives a slug preview in the quote form
- [ ] Admin can edit the slug before provisioning
- [ ] "Provision Email" button calls `admin-provision-client-email` and shows result in < 5s
- [ ] `client_slug`, `provisioned_email`, `cloudflare_routing_rule_id`, and `client_email_provisioned_at` are written to the `quotes` row
- [ ] Address is displayed with a copy button in the quote detail drawer
- [ ] Duplicate slug is detected before calling the API (query `quotes.client_slug`) — numeric suffix appended automatically
- [ ] Routing rule is retained for 90 days after `cancelled_at` — cron deprovisions after the window
- [ ] Admin can trigger early deprovision manually from the quote detail drawer
- [ ] `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_ID`, and `CLOUDFLARE_FORWARD_TO` are stored
  in Supabase vault — never hardcoded

---

## Out of Scope

- Sending emails FROM `footballwinner@raspucat.com` (Cloudflare Email Routing is receive/forward
  only; sending requires Resend custom domain setup — future feature if needed)
- Automatic Supabase project creation (no public API)
- Per-client inbox (all forward to one address; threading by subject/from is handled by your email client)

---

## Dependencies

- Cloudflare DNS must be active for `raspucat.com`
- Cloudflare Email Routing must be enabled on the zone (free feature)
- `CLOUDFLARE_FORWARD_TO` address must be verified in Cloudflare Email Routing before first use
- Feature 007 (`admin-deactivate-monitor`) — deprovision should fire in the same cancellation
  hook to keep cleanup consolidated
- Feature 019 ✅ — `client_slug` column already exists (migration 20260323000002); 013 is now
  the canonical writer of that column at quote creation time

---

## Mode

STUDIO

---

## Notes

- Cloudflare Email Routing is free and has no mailbox limit — you pay nothing per address
- All forwarded emails arrive in your personal inbox; use email labels/filters to sort by
  sender domain (e.g. `@supabase.com` + `to:footballwinner@raspucat.com`)
- If you ever want to send FROM the address (e.g. for client-facing support), that requires
  adding `raspucat.com` as a custom domain in Resend and using it as the `from` address —
  document this in a future feature
- Zone ID is per-domain — `raspucat.com`'s zone ID is found in Cloudflare dashboard →
  Overview → right sidebar
- `client_email` (pre-existing, NOT NULL) = client's personal email. `provisioned_email` =
  the `@raspucat.com` infra alias. Never confuse these two columns.
