# Feature: Admin Dashboard

**Mode:** STUDIO
**Status:** COMPLETE
**Priority:** Medium

## Problem

The current admin page is a minimal quote list with two bulk actions (charge balance, start subscription). It lacks visibility into business health, search/filtering, and operational tools that would make day-to-day management faster.

## Current Implementation (as of 2026-03-17)

### Auth
- Password input → stored as `_adminToken` string in `AdminController`
- Auth verified by calling `admin-list-quotes` and checking for `{'error': 'Unauthorized.'}`; wrong password clears the token
- Token is passed as `adminToken` in the body of every edge function call

### Quote data fields (from `admin-list-quotes` response)
`id`, `client_name`, `client_email`, `business_name`, `status`, `plan_id`, `deposit_cents`, `balance_cents`, `management_option_id` (raw ID, not resolved name), `billing_cycle`, `subscription_started_at`, `stripe_payment_method_id`

> **Gap:** No subscription amount field returned — MRR stats bar will require `admin-list-quotes` to also return a `subscription_amount_cents` field (or a dedicated `admin-get-stats` function).

### Controller state pattern
`quoteState: RxMap<String, Map<String, dynamic>>` — per-quote keys: `chargingBalance`, `startingSub`, `chargeMsg`, `subMsg`. Mutations via `_setQuoteState(quoteId, key, value)` which copies the map and calls `.refresh()`. All new per-quote actions MUST follow this exact pattern — add new keys to the same map.

### Action guards (client-side)
- **Charge Balance:** `status == 'deposit_paid' && balance_cents > 0`
- **Start Subscription:** `billing_cycle != 'onetime' && subscription_started_at == null && stripe_payment_method_id != null`

### Known gaps in current UI
- Status badge only renders for `deposit_paid` / `fully_paid` — `pending` quotes show no badge
- `management_option_id` displayed as raw ID, not resolved human-readable name
- `_fmt()` rounds to nearest dollar (no cents) — fine for deposits/balances, may matter for subscription display
- No search, no filters, no stats, no navigation between sections

## Proposed Enhancements

### 1. Stats Bar (KPI Header)
- Total active clients (fully_paid + subscription active)
- Pending balances (sum of `balance_cents` where status = `deposit_paid`)
- MRR estimate (sum of monthly subscription amounts)
- Renders as a row of metric cards at the top of the dashboard

### 2. Search & Filter
- Text search by client name or email
- Status filter chips: All / Deposit Paid / Fully Paid
- Billing cycle filter: All / Monthly / Yearly (annual) / Handover (onetime)
- Filters are local (no new API calls)

### 3. Quote Status Pipeline View
- Tab or toggle to switch between List View and Pipeline View
- Pipeline columns: `pending` → `deposit_paid` → `fully_paid`
- Drag-and-drop or status-change button to move quotes between stages (calls a new `admin-update-quote-status` edge function)

### 4. Quote Detail Drawer / Expanded Row
- Tap a quote row to expand an inline detail view (or slide-in drawer on wide screens)
- Shows: full modules list, selected management option, billing cycle, Stripe payment method last 4, created_at timestamp
- Action to copy Stripe customer ID / checkout link

### 5. Create / Edit Quote
- "New Quote" button opens a modal pre-filled with the plan configurator data model
- Edit existing quote: update plan, modules, pricing, billing cycle before deposit is taken
- Only allowed while `status == 'pending'`

### 7. Subscription Management
- Per-quote: Cancel Subscription button (calls new `admin-cancel-subscription` edge function)
- Shows next billing date pulled from Stripe metadata or subscription field
- Visual indicator: days until next charge

### 8. Mid-Engagement Add-On (One-Time Module Purchase)
A client 4 months in can request a new module (e.g. Google Reviews). This is a **one-time charge** — it does not touch their management subscription at all.

**How it works:**
- Modules are one-time setup fees, not recurring items
- The client's `stripe_payment_method_id` is already on file from their original quote
- Admin triggers a new `stripe.paymentIntents.create()` for the module's a la carte price, confirmed off-session against their saved payment method
- On payment success: insert a new row into `quote_modules` linking the module to the quote

**Admin UI needed:**
- "Add Module" button in the Quote Detail Drawer (guard: quote must be `fully_paid` or active subscription)
- Modal showing modules not already on the quote, each with a la carte price
- Confirm → calls `admin-add-module` edge function → charges payment method → inserts `quote_modules` row → logs to `quote_events`

**Edge function needed:**
| Function | Purpose |
|---|---|
| `admin-add-module` | Creates a Stripe `PaymentIntent` for the module price using the quote's `stripe_payment_method_id` (off-session, `confirm: true`); on success inserts row into `quote_modules` and `quote_events` |

**DB impact:** No schema changes needed — `quote_modules` already links quotes to modules.

**Stripe note:** Off-session charges require the payment method to have been set up with `setup_future_usage: 'off_session'` during original checkout. Confirm this is set in the existing Stripe Checkout session config before implementing.

### 9. Activity Log
- Per-quote expandable log showing timestamped events:
  - Quote created
  - Deposit paid
  - Balance charged
  - Subscription started/cancelled
- Sourced from a new `quote_events` table or Supabase audit log

### 10. Notification Badges
- Flag quotes that have been in `deposit_paid` state for > 7 days without balance charged
- Highlight subscriptions due within 3 days
- Badge count in nav header

## Acceptance Criteria

- [x] Stats bar shows live KPIs on dashboard load
- [x] Text search filters by client name or email in real-time without additional API calls
- [x] Status filter chips (All / Deposit Paid / Fully Paid) correctly narrow quote list
- [x] Billing cycle filter chips (All / Monthly / Yearly / Handover) correctly narrow quote list
- [x] Pipeline view renders all quotes in correct columns
- [x] Quote Detail Drawer opens on row tap; shows all required fields (modules, management option name, billing cycle, Stripe last 4, created_at)
- [x] Quote Detail Drawer uses slide-in drawer on wide screens; inline expand on narrow screens
- [x] Create quote modal saves via `admin-create-quote` and quote appears in list on success
- [x] Edit quote modal only available when `status == 'pending'`; saves via `admin-update-quote` and refreshes list
- [x] Cancel subscription calls edge function and updates UI
- [x] "Add Module" button appears in Quote Detail Drawer for fully paid / active quotes
- [x] Add module flow calls `admin-add-module`, charges saved payment method as a one-time PaymentIntent, and refreshes quote modules
- [x] Add module event is logged to `quote_events`
- [x] Activity log displays per-quote event timeline
- [x] Stale-quote badges appear correctly based on date thresholds
- [x] Notification badge count is visible in nav header and updates on fetch
- [x] Pending status badge renders on `AdminQuoteRow` for `pending` quotes
- [x] MRR stat correctly normalizes annual subscriptions (÷ 12) and excludes one-time plans
- ~~[ ] App-resume triggers automatic re-fetch of quotes and stats~~ _(removed — caused excessive refreshes on tab focus; manual refresh button available instead)_

## Architecture Notes

### Controller
- Keep `AdminController` as single controller; extend `quoteState` map with new per-quote keys (`cancellingSubscription`, `cancelMsg`, `updatingStatus`, `statusMsg`) following the existing `_setQuoteState` pattern
- Add separate `RxMap adminStats` observable for KPI header — fetch in parallel with `fetchQuotes()`
- If controller exceeds 300 lines: split into `AdminDashboardController` (stats, search, filters) + `AdminQuoteController` (per-quote actions)
- Stale-quote detection (`isStale`) is a **client-side computed getter** in `AdminQuoteController`, not server-side. Logic: `status == 'deposit_paid' && DateTime.now().difference(depositPaidAt).inDays > 7`. Set `isStale: true` flag in `quoteState` map after fetch.
- **`deposit_paid_at` gap:** This field does not exist in the current `admin-list-quotes` response. Add it to the `admin-list-quotes` update (server-side join from `quote_events` where `event_type = 'deposit_paid'`, or as a direct column on the quotes table). Stale detection cannot be implemented until this field is available.
- `_fmt()` currently rounds to nearest dollar (no cents). Subscription amounts may be non-round — update `_fmt()` to support optional cent display before rendering subscription fields.

### Edge functions needed
| Function | Purpose |
|---|---|
| `admin-update-quote-status` | Move quote between `pending → deposit_paid → fully_paid` (forward-only; server must reject backward transitions) |
| `admin-cancel-subscription` | Cancel Stripe subscription; update `subscription_started_at` / status |
| `admin-get-stats` | Return `{ active_clients, pending_balance_cents, mrr_cents }` |
| `admin-list-quotes` (update) | Add `subscription_amount_cents` field + join `management_option` name (resolve server-side, not via client lookup map) |
| `admin-add-module` | Create off-session Stripe `PaymentIntent` for module a la carte price; on success insert into `quote_modules` + `quote_events` |
| `admin-create-quote` | Create a new quote record with plan, modules, pricing, billing cycle; returns new quote ID |
| `admin-update-quote` | Update an existing quote's plan/modules/pricing; server must enforce `status == 'pending'` before applying changes |
| `admin-get-quote-detail` | Return full quote detail including resolved Stripe payment method last 4 (via Stripe API, server-side) and full module list |

### Stats: MRR Calculation
- MRR = sum of `subscription_amount_cents` for active subscriptions, normalized to monthly:
  - `monthly` billing cycle: full amount counts toward MRR
  - `annual` billing cycle: `amount ÷ 12` counts toward MRR
  - `onetime` plans: excluded from MRR entirely
- Use dedicated `admin-get-stats` edge function (not client-side aggregation). Rationale: avoids re-loading all quotes just for stats, scales as quote volume grows.

### Pagination
- For now: load all quotes on mount (no pagination).
- Add offset-based pagination (`page` param in `admin-list-quotes`) when quote count exceeds 100. Flag this as a deferred task.

### Auth Security
- Admin token is compared server-side only. Never store in `SharedPreferences` or any persistent client-side storage.
- Current behavior: token is lost on app restart (each session requires re-entry) — this is a **known UX tradeoff**, not a bug.
- Future path: replace plain token with Supabase Auth + `app_metadata.role = 'admin'`. Out of scope for this pass — revisit only if multi-admin support or compliance becomes a requirement.

### Automations
| Trigger | Action |
|---|---|
| App resumes from background | Auto-refresh: re-fetch quotes + stats |
| Fetch completes | Compute `isStale` flag for all `deposit_paid` quotes older than 7 days |
| Start subscription / charge balance action | Optimistic UI: show loading state immediately; revert on error |

### Quote Detail Drawer
- `management_option_id` resolved to human-readable name via server-side join in `admin-list-quotes` (see Edge Functions section above — do not use a client-side lookup map)
- Stripe payment method last 4 requires `stripe_payment_method_id` to be resolved via Stripe API — do this server-side in the detail edge function, not client-side

### Edit Quote guard
- Edit action: only render edit icon on `AdminQuoteRow` when `status == 'pending'` (client-side gate)
- Server-side: edge function must also enforce `status == 'pending'` before accepting edits

### Status badge fix
- Add `pending` status rendering to `AdminQuoteRow` (currently only `deposit_paid` / `fully_paid` are handled)
- Suggested color: `EColors.textSecondary` for pending
- Add acceptance criterion for pending badge (see Acceptance Criteria below)

### DB migrations needed
- `quote_events` table for activity log:
  - Columns: `id uuid PK`, `quote_id uuid FK → quotes.id`, `event_type text`, `created_at timestamptz DEFAULT now()`, `metadata jsonb`
  - Index: `CREATE INDEX ON quote_events (quote_id)` — required for per-quote log queries
- If `deposit_paid_at` is stored as a column (vs derived from `quote_events`): `ALTER TABLE quotes ADD COLUMN deposit_paid_at timestamptz`

## Related Features
- **`009_client_message_board`** — per-client message thread. Admin side (unread badges, reply UI) is part of that feature but integrates into this dashboard. Build 009 alongside or after this feature.

## Out of Scope

- Client-facing portal
- Email/SMS notifications to clients
- Multi-admin roles / permissions (single admin token for now)
