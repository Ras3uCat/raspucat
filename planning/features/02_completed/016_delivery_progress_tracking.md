# 016 — Delivery Progress Tracking

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

## Mode
STUDIO

---

## Overview

The modular_project `deliver.sh` runs 6 automated steps, but the full delivery process has
~20 additional manual tasks (Supabase auth config, Stripe webhook registration, cron
scheduling, asset replacement, QA, etc.). These are currently tracked in a markdown file
only — there is no visibility in Raspucat's admin panel on where a client's build is up to.

This feature surfaces the full delivery checklist inside the Raspucat admin panel, tailored
to each client's module set, with steps that can be ticked off as you work through them.

---

## Problem
- No visibility in Raspucat on where a client's delivery is up to
- Manual tasks are tracked in a markdown file that isn't per-client
- Easy to miss steps, especially for module-specific ones (Stripe webhook for shop vs events)
- No history of when a client was delivered or what was done

---

## Proposed Flow

```
Admin creates quote + client purchases
  └─ Delivery tab opens for the first time → checklist rows initialized in delivery_progress
       based on modules in quotes.module_ids (lazy init on first load)

deliver.sh POSTs completion events to admin-delivery-progress (with adminToken)
  └─ Upserts: deliver_sh_complete, stripe_webhooks_registered (if --register-webhooks used)

Admin manually checks off remaining steps in Raspucat admin panel
  └─ JWT hook, crons, QA, master user, handover
```

---

## Delivery Checklist Phases (module-aware)

### Phase 1 — Setup
- [ ] Discovery call complete
- [ ] Supabase account created (`{slug}@raspucat.com`)
- [ ] client.json generated and filled in ← links to feature 015

### Phase 2 — Deploy
- [ ] deliver.sh run successfully ← auto-checked via deliver.sh POST
- [ ] Stripe webhooks registered ← auto-checked if deliver.sh run with `--register-webhooks` (feature 017); otherwise manual
- [ ] JWT custom claims hook registered in Supabase Auth → Hooks
- [ ] Supabase Auth Site URL + Redirect URLs set to live domain
- [ ] Auth email templates customised
- [ ] Deployed to hosting + DNS pointed
- [ ] www redirect confirmed

### Phase 3 — Post-Deploy
- [ ] Favicon + PWA icons replaced
- [ ] OG image uploaded and URL set
- [ ] Master user created and role set to `master`
- [ ] Supabase 2FA enabled
- [ ] Test data cleared
- [ ] Search Console property verified + sitemap submitted
- [ ] UptimeRobot monitor active ← auto-checked via feature 007 (manual until 007 ships)

### Phase 4 — QA
- [ ] End-to-end smoke test passed

### Phase 5 — Handover
- [ ] Handover email sent ← auto-checked when handover email fires (manual until feature 011 ships)

### If `booking` in modules (appended to Phase 2 / QA)
- [ ] STRIPE_SK set in Supabase secrets (test key)
- [ ] STRIPE_WEBHOOK_SECRET set in Supabase secrets
- [ ] QA: test booking end-to-end
- [ ] Stripe test → live key switchover
- [ ] Stripe webhook re-registered (live mode)

### If `shop` in modules
- [ ] STRIPE_SHOP_WEBHOOK_SECRET set in Supabase secrets
- [ ] QA: test shop checkout end-to-end

### If `events` in modules
- [ ] STRIPE_EVENTS_WEBHOOK_SECRET set in Supabase secrets
- [ ] QA: test event ticket purchase end-to-end

### If `gallery` in modules
- [ ] Supabase Storage bucket created and set to Public

### If `newsletter` in modules
- [ ] QA: test newsletter subscribe + welcome email

### Crons — If `booking` in modules
- [ ] `expire-pending-bookings` cron scheduled (`*/30 * * * *`)
- [ ] `send-reminders` cron scheduled (`0 10 * * *`)

### Crons — If `booking` + `REVIEWS_ENABLED`
- [ ] `send-review-requests` cron scheduled (`0 12 * * *`)

---

## Scope

### Data Model

```sql
-- Migration: 20260321000002_delivery_progress.sql

CREATE TABLE delivery_progress (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id   UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  step       TEXT NOT NULL,
  checked    BOOLEAN NOT NULL DEFAULT false,
  checked_at TIMESTAMPTZ,
  checked_by TEXT DEFAULT 'admin',   -- 'admin' | 'system' (auto-checked)
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (quote_id, step)            -- prevent duplicate rows; enables upsert
);

-- Column needed for feature 020 (remote module redeploy)
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS supabase_project_ref TEXT;
```

### Backend (Supabase Edge Functions)

**`admin-delivery-progress`**
- Auth: `adminToken` vs `ADMIN_PASSWORD` (same pattern as all other admin functions)
  - deliver.sh includes `"adminToken": "$RASPUCAT_ADMIN_TOKEN"` in POST body
  - Flutter admin panel sends same token for manual check/uncheck
- Input variants:
  - `{ quote_id, step, adminToken }` — mark a single step checked/unchecked
  - `{ quote_id, step, adminToken, checked: false }` — explicit uncheck (default: true)
  - `{ quote_id, adminToken, init: true, module_ids: [...] }` — initialize all rows for a quote
- Upserts into `delivery_progress` on `(quote_id, step)` conflict
- For `deliver_sh_complete` step: also writes `supabase_project_ref` to `quotes` row
- Does NOT call `admin-update-portal-stage` directly — portal stage is a separate concern

> **Note:** `admin-update-portal-stage` already exists. Portal stage is updated directly
> inside `admin-delivery-progress`: `deliver_sh_complete` → `compiling`,
> `smoke_test_passed` → `deployed`.

### deliver.sh integration

After successful completion, deliver.sh POSTs to `admin-delivery-progress`:

```bash
if [ -n "${RASPUCAT_QUOTE_ID:-}" ] && [ -n "${RASPUCAT_API:-}" ]; then
  curl -sf -X POST "${RASPUCAT_API}/functions/v1/admin-delivery-progress" \
    -H "Content-Type: application/json" \
    -d "{
      \"adminToken\": \"${RASPUCAT_ADMIN_TOKEN}\",
      \"quote_id\": \"${RASPUCAT_QUOTE_ID}\",
      \"step\": \"deliver_sh_complete\",
      \"supabase_project_ref\": \"${SUPABASE_PROJECT_REF}\"
    }" || echo "⚠️  Raspucat progress POST failed (non-blocking)"
fi
```

- Only fires if both `RASPUCAT_QUOTE_ID` and `RASPUCAT_API` are set in `client.json`
- `RASPUCAT_ADMIN_TOKEN` also required in `client.json`
- Silently skips if unreachable — non-blocking, build continues regardless
- If `--register-webhooks` was used, also POSTs `stripe_webhooks_registered` step

### client.json additions

Add three optional fields (generated as `"FILL_IN"` by the client.json generator):

```json
"RASPUCAT_API": "https://<your-raspucat-project>.supabase.co",
"RASPUCAT_QUOTE_ID": "FILL_IN",
"RASPUCAT_ADMIN_TOKEN": "FILL_IN"
```

These are already in the admin-generate-client-json output checklist; update the generator
(feature 015) to include them in the JSON body itself.

### Admin Panel (Flutter)

- New **"Delivery"** tab in the quote detail drawer
- On first open: if no `delivery_progress` rows exist for the quote, call `admin-delivery-progress`
  with `init: true` and `module_ids` from the quote — this populates all applicable step rows
- Shows checklist grouped by phase (Setup / Deploy / Post-Deploy / QA / Handover)
- Module-specific steps shown/hidden based on `quotes.module_ids`
- Auto-checked steps (`checked_by = 'system'`) shown with system icon + timestamp, non-interactive
- Manual steps: checkbox, tap to toggle (sends check or uncheck to edge function)
- Progress bar: `checked_count / total_steps` for this quote's applicable steps
- When all steps checked: green "Delivered ✓" badge replaces progress bar

---

## Acceptance Criteria
- [ ] Checklist initialized on first Delivery tab open (lazy, based on `module_ids`)
- [ ] `UNIQUE(quote_id, step)` enforced — upsert on conflict, no duplicate rows
- [ ] `deliver.sh` auto-checks `deliver_sh_complete` when `RASPUCAT_QUOTE_ID` + `RASPUCAT_API` + `RASPUCAT_ADMIN_TOKEN` are set
- [ ] `stripe_webhooks_registered` auto-checked when `--register-webhooks` succeeds
- [ ] Admin can manually check and uncheck steps
- [ ] System-auto-checked steps are non-interactive in the UI (no checkbox)
- [ ] `supabase_project_ref` written to `quotes` row on `deliver_sh_complete`
- [ ] `portal_stage` updated to `'compiling'` on `deliver_sh_complete`, `'deployed'` on `smoke_test_passed`
- [ ] Module-specific steps only appear for relevant modules
- [ ] Progress bar reflects applicable steps only (not all possible steps)
- [ ] Checklist persists across sessions (stored in Supabase)

---

## Dependencies
- Feature 015 — client.json generator (needs `RASPUCAT_API`, `RASPUCAT_QUOTE_ID`, `RASPUCAT_ADMIN_TOKEN` added to output)
- Feature 017 — `--register-webhooks` flag (for `stripe_webhooks_registered` auto-check) ✅ complete
- Feature 007 — `admin-register-site` auto-checks `site_registered` / `monitor_created` ⏳ not yet implemented — these steps remain manual until 007 ships
- Feature 011 — cancellation handoff auto-checks `handover_email_sent` ⏳ not yet implemented — remains manual until 011 ships

---

## Notes
- deliver.sh POST is fire-and-forget — a failed POST does not block the build
- Checklist step keys (e.g. `deliver_sh_complete`, `jwt_hook_registered`) are the canonical step identifiers stored in `delivery_progress.step` — Flutter generates the display label and phase from these keys client-side
- Cron scheduling and JWT hook registration cannot be automated (Supabase dashboard only) — these remain manual steps but are now tracked
- Admin CAN uncheck manual steps (e.g. to re-do a QA step); system steps cannot be unchecked from the UI
