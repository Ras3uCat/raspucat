# 020 — Module Add-On Deployment

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

## Mode
FLOW

---

## Overview

When a client purchases an add-on module via the Raspucat portal, the admin receives the
request, opens the client's local project, runs `add-module.sh`, and the script handles
everything — including calling back to Raspucat to mark the module deployed automatically.
No manual admin panel step needed after running the script.

---

## Problem

- `client_modules_pending` tracks purchased add-ons but has no `deployed_at` — no way to
  record when the module was actually delivered
- No helper script exists to add a module to a client project cleanly
- Marking a module deployed requires manually updating the admin panel after running deploy
- `quotes.modules` and `quotes.module_ids` are not updated when a module is added post-launch

---

## Flow

```
Client purchases add-on via portal
  ↓
Admin sees pending module in admin panel (client_modules_pending)
  ↓
Admin opens client project directory locally
  ↓
./add-module.sh <module-id>
  ├─ Appends module to MODULES in client.json
  ├─ Runs deliver.sh --skip-build (migrations + functions only)
  ├─ Reads RASPUCAT_API + RASPUCAT_QUOTE_ID + RASPUCAT_ADMIN_TOKEN from client.json
  └─ POSTs to admin-mark-module-deployed → marks deployed, updates quotes, notifies client
  ↓
Admin panel automatically shows "Deployed" + timestamp — no manual step needed
```

---

## Scope

### Data Model
```sql
ALTER TABLE public.client_modules_pending
  ADD COLUMN IF NOT EXISTS deployed_at TIMESTAMPTZ;
```
> `acknowledged_at` retains its original meaning (admin saw the request).
> `deployed_at` is the new field for when the module was actually delivered.

### modular_project — `add-module.sh`
- Lives at `/execution/frontend/app/add-module.sh`
- Must be run from the client project directory (same location as deliver.sh)
- Usage: `./add-module.sh <module-id>` (e.g. `./add-module.sh newsletter`)
- Steps:
  1. Validate module-id is a known module (guard against typos)
  2. Read current MODULES from client.json
  3. Check if module already present — exit early if so (idempotent)
  4. Append module-id to MODULES string in client.json
  5. Run `./deliver.sh --skip-build`
  6. On deliver.sh success: POST to `$RASPUCAT_API/functions/v1/admin-mark-module-deployed`
     with `{ quoteId, moduleId, adminToken }` from client.json
  7. Print success with deployed module and Raspucat confirmation

### Raspucat — `admin-mark-module-deployed` edge function
- Auth: ADMIN_PASSWORD
- Input: `{ quoteId, moduleId, adminToken }`
- Sets `client_modules_pending.deployed_at = now()` for matching quote + module
- Appends moduleId to `quotes.module_ids`
- Appends module slug to `quotes.modules` (used by 019 handoff email)
- Returns `{ success: true, deployedAt }`

### Admin Panel (Flutter)
- Pending modules queue already exists — add `deployed_at` display per row
- Show "Deployed {date}" badge when `deployed_at` is set
- No "Deploy" button needed — deployment is triggered from local terminal

---

## Acceptance Criteria

- [ ] `./add-module.sh newsletter` appends to client.json, runs deliver.sh, calls back to Raspucat
- [ ] Script exits cleanly if module already in client.json (idempotent)
- [ ] `client_modules_pending.deployed_at` is set automatically after script completes
- [ ] `quotes.modules` and `quotes.module_ids` updated in Raspucat
- [ ] Admin panel shows deployed timestamp on the pending module row
- [ ] Script validates module-id against known module list before modifying client.json
- [ ] Script handles deliver.sh failure gracefully — does NOT call back to Raspucat if deploy failed

---

## Module ID → Slug Mapping

For updating `quotes.modules` (site feature slugs used by handoff email):

| moduleId (client.json) | slug (quotes.modules) |
|---|---|
| `newsletter` | `newsletter` |
| `testimonials` | `testimonials` |
| `faq` | `faq` |
| `crm` | `crm` |
| `referrals` | `referrals` |
| `gallery` | `gallery` |
| `blog` | `blog` |
| `shop` | `shop` |
| `booking` | `booking` |
| `events` | `events` |
| `subscriptions` | `subscriptions` |

> For most modules, moduleId === slug. Maintain this table if any diverge.

---

## Out of Scope

- Remote/automated deployment (no Management API, no storage buckets, no VPS)
- Stripe webhook re-registration for payment modules (handled manually or via --register-webhooks flag)
- Flutter rebuild automation (client.json change + rebuild still manual if UI changes needed)
- Client notification email on deploy (future feature — portal already shows module status)

---

## Dependencies

- `client_modules_pending` table (existing)
- `client.json` fields `RASPUCAT_API`, `RASPUCAT_QUOTE_ID`, `RASPUCAT_ADMIN_TOKEN` (already present)
- Feature 019 ✅ — `quotes.modules` column exists
- `deliver.sh --skip-build` (existing flag in modular_project)

---

## Notes

- `add-module.sh` must live alongside `deliver.sh` so relative paths work
- The Raspucat callback uses credentials already in client.json — no extra setup needed
- If `RASPUCAT_QUOTE_ID` is empty (older client projects), script should warn but not fail
- Mode changed from STUDIO → FLOW: scope is well-defined and small
