# 015 — client.json Generator

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

## Mode
FLOW

---

## Overview

When a client completes their purchase on Raspucat, all the information needed to pre-fill
a `client.json` already exists on the `quotes` row — plan, modules, management tier, billing
cycle, business name, client email. Currently you re-enter all of this manually when setting
up the client directory.

This feature adds a **"Generate client.json"** button to the admin quote detail drawer. It
outputs a downloadable, pre-filled `client.json` with everything Raspucat knows, leaving only
secrets and domain-specific values for you to fill in.

---

## Problem
- Client picks plan + modules + management on Raspucat → you manually re-enter the same
  choices into `client.json` when setting up the modular_project directory
- Error-prone: wrong module list = missing migrations on first deliver.sh run
- Time cost: 15–30 min of duplicated data entry per client

---

## Data Mapping — Raspucat quote → client.json

| client.json field | Source |
|---|---|
| `CLIENT_NAME` | `quotes.business_name` |
| `CLIENT_SLUG` | derived from `quotes.business_name` (lowercase, hyphens) |
| `MODULES` | `quotes.module_ids` → mapped to module slug names |
| `RASPUCAT_QUOTE_ID` | `quotes.id` |
| `STRIPE_MODE` | `"standard"` default; `"connect_multi_staff"` if management tier includes it |
| `BUSINESS_NAME` | `quotes.business_name` |
| Billing cycle comment | injected as a comment — `monthly` / `annual` / `onetime` |
| All secrets | left as placeholder strings: `"FILL_IN"` |
| All brand fields | left as placeholder strings: `"FILL_IN"` |

---

## Scope

### Backend (Supabase Edge Functions)
- [ ] New edge function `admin-generate-client-json`:
  - Auth: admin only (ADMIN_PASSWORD check)
  - Input: `{ quote_id }`
  - Fetch quote + plan + modules from Supabase
  - Map module IDs to modular_project module slugs (stored as a mapping constant)
  - Return a JSON string of the pre-filled `client.json`

### Admin Panel (Flutter)
- [ ] Add **"Generate client.json"** button to quote detail drawer
- [ ] On tap: call `admin-generate-client-json`, show result in a dialog with a copy button
- [ ] Dialog also shows a checklist of fields still needing manual values (secrets, domain, colours, fonts)

---

## Module ID → client.json mapping

Raspucat sells modules as bundles for pricing simplicity, but the modular_project keeps
every module independent. The generator expands each bundle into its component parts.

> **Important:** the modular_project modules are fully independent. A client can have
> `shop` without `booking`, or `gallery` without `blog`. The bundle names in Raspucat
> (e.g. "Blog & Gallery") are just the common pairing sold together — the generator
> notes which components are included. If a future client only wants one part of a bundle,
> that is handled by creating a custom quote in Raspucat with individual module pricing
> rather than the bundle.

| Raspucat module_id | client.json MODULES expansion | Note |
|---|---|---|
| `blog_gallery` | `blog` + `gallery` | Both included — either can be omitted manually post-generation |
| `booking_shop` | `booking` + `shop` | Both included — either can be omitted manually post-generation |
| `stripe` | — | (Stripe is always required if booking or shop present) |
| `stripe_connect` | — | `STRIPE_MODE: connect_multi_staff` |
| `tip_gratuity` | — | (booking add-on, configured in Admin settings post-delivery) |
| `pwa_notifications` | — | `PWA_NOTIFICATIONS_ENABLED: true` (if modular_project supports it) |
| `stats_digest` | — | (admin analytics — always available if booking) |
| `ai_chatbot_lite` | — | (not in modular_project — future module) |
| `ai_chatbot_full` | — | (not in modular_project — future module) |
| `sms_reminders` | — | `SMS_ENABLED: true` |
| `loyalty_referrals` | — | `LOYALTY_ENABLED: true`, add `referrals` to MODULES |
| `google_reviews` | — | `REVIEWS_ENABLED: true` |
| `native_apps` | — | `BUNDLE_ID: FILL_IN`, `APPLE_TEAM_ID: FILL_IN` (annotated as required) |
| `pdf_invoices` | — | (not in modular_project — future module) |
| `multi_location` | — | (not in modular_project — future module) |
| `custom_menu` | — | (not in modular_project — future module) |
| `gated_content` | — | (not in modular_project — future module) |

> Modules marked "not in modular_project" generate a comment in the output JSON noting
> the feature needs to be built or handled separately.

---

## Acceptance Criteria
- [ ] "Generate client.json" button visible on active/deposit_paid quotes
- [ ] Output includes correct MODULE list matching purchased modules
- [ ] `RASPUCAT_QUOTE_ID` pre-filled with quote UUID
- [ ] All secret fields show `"FILL_IN"` placeholder — never expose real secrets
- [ ] Copy button copies the full JSON to clipboard
- [ ] Dialog lists which fields still need manual values

---

## Dependencies
- Existing quotes + modules data model
- Feature 013 (`client_email_slug`) — `CLIENT_SLUG` derivation logic can be shared

---

## Notes
- The generated file is a starting point, not a final product — brand colours, fonts,
  domain, and all secrets still need manual input
- This saves the most time on module list and business identity fields which are 100%
  derivable from the purchase
