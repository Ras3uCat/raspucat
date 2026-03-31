# 018 — Template Version Tracking

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

## Mode
FLOW

---

## Overview

Each client site is a snapshot of the modular_project template taken at delivery time.
There is currently no record in Raspucat of which template version a client is on. When
you add a new feature, fix a bug, or update an edge function in the master template,
there is no way to know which live clients need the update applied.

This feature stores the template version (git commit hash) on the quote at delivery time,
and surfaces a "Version" indicator in the admin panel so you can see which clients are
behind.

---

## Problem
- No record of which template version each client is running
- "Did I apply that fix to this client?" is answered by checking the client's DELIVERY_LOG.md
  manually — not visible in Raspucat
- As the client roster grows, propagating updates to specific clients becomes unmanageable
  without a central view

---

## Proposed Flow

```
deliver.sh (during delivery)
  └─ Captures: git rev-parse --short HEAD (from modular_project master template)
  └─ POSTs to admin-delivery-progress:
       { quote_id, step: 'deliver_sh_complete', template_version: 'a3f9c12' }

Raspucat stores template_version on quotes row

Admin panel:
  └─ Shows template version on each quote
  └─ If a newer version is available (set by admin), shows "Update available" badge
```

---

## Scope

### Data Model
```sql
ALTER TABLE quotes
  ADD COLUMN IF NOT EXISTS template_version TEXT,         -- git short hash at delivery
  ADD COLUMN IF NOT EXISTS template_delivered_at TIMESTAMPTZ; -- when deliver.sh last ran
```

### deliver.sh additions
- [ ] Capture template version: `TEMPLATE_VERSION=$(git -C /path/to/modular_project rev-parse --short HEAD)`
- [ ] Include in the `admin-delivery-progress` POST payload

### Backend
- [ ] Update `admin-delivery-progress` to accept and store `template_version` + `template_delivered_at`

### Admin Panel (Flutter)
- [ ] Show template version + delivered date on quote detail drawer
- [ ] New admin setting: "Current template version" (admin enters the latest git hash)
- [ ] If `quote.template_version != current_template_version`: show amber "Update available" badge on quote row
- [ ] Quote detail: show which version they're on vs current + a "Mark as updated" button
  (for after you manually apply a patch)

---

## Acceptance Criteria
- [ ] `template_version` written to quote on every deliver.sh run
- [ ] Version visible in quote detail drawer
- [ ] "Update available" badge appears when quote is behind current version
- [ ] Admin can set the current template version in settings
- [ ] "Mark as updated" button allows admin to record a manual patch

---

## Dependencies
- Feature 016 (delivery progress) — version is sent in the same POST
- `RASPUCAT_QUOTE_ID` in `client.json`

---

## Notes
- The git hash is taken from the master template directory, not the client's copy
- deliver.sh must be run from or have access to the modular_project git repo path
  (it already lives there as the master template)
- "Mark as updated" does not auto-set the version to current — admin inputs the exact
  version hash or clicks a "Set to current" button that reads from admin settings
