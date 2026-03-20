# Feature: Client Portal
**ID:** 010
**Mode:** STUDIO
**Status:** Complete
**Priority:** High

---

## Overview
A post-purchase portal for clients who have completed the deposit payment. The portal link is delivered in the deposit confirmation email (via Resend). Clients authenticate once via magic link, then maintain a persistent Supabase session — no repeated email logins required.

**Route:** `/portal` (protected route, unauthenticated users redirected to login)
**Future:** May graduate to `portal.raspucat.com` subdomain

---

## Authentication

### First Access
Magic link sent in the deposit confirmation email. Supabase default magic link TTL is **1 hour** — if expired, the client can request a new link from the `/portal/login` screen (email input → new magic link sent via Resend).

### Subsequent Visits
Persistent Supabase session (JWT stored locally). Supabase handles automatic token refresh — no re-login required unless the session is explicitly invalidated or the refresh token expires (default: 1 week).

### Session Expiry
On expired session, the app silently redirects to `/portal/login` with a soft prompt: _"Your session has expired — enter your email to get a new link."_ No hard error screen.

### Pre-Payment Access
If a user hits `/portal` without a valid session, they are redirected to `/portal/login`. The portal does not expose a "payment required" holding page to unauthenticated users (prevents enumeration).

### No Password Required
Supabase Auth handles all session management. No passwords stored.

---

## Project Status Stages
Three manual stages, set by admin in the admin panel:

| Stage | Meaning |
|---|---|
| **Transmitting** | Deposit received — project is queued |
| **Compiling** | Development is actively in progress |
| **Deployed** | Project is live |

---

## Client Portal Screens & Features

### Navigation
**Desktop/Tablet:** Persistent left sidebar (Material 3 Navigation Rail) with section icons + labels, project status pill at top, and plan name.
**Mobile:** Bottom navigation bar (Material 3 Navigation Bar) — max 4 primary items, overflow in a "More" menu. Sidebar collapses fully below tablet breakpoint.

### 1. Dashboard
- Current project status pill (`Transmitting` / `Compiling` / `Deployed`)
- Quick links to all portal sections
- Plan summary (what they purchased)

### 2. Project Details
- Plan name, modules included, purchase date
- Breakdown of what was bought

### 3. Invoices & Payment History
- List of all payments made (deposit, add-ons, etc.)
- Pulled from Stripe via Supabase (`stripe_customer_id` on `quotes`)

### 4. File Exchange (Bidirectional)
- **Client → Us:** Upload assets (logos, copy, brand files, etc.)
- **Us → Client:** Deliver files/deliverables for client download
- Supabase Storage, scoped per client (RLS enforced)

**Constraints:**
- Max file size: **50 MB** per file
- Allowed types: images (`jpg`, `png`, `svg`, `webp`), documents (`pdf`), archives (`zip`), fonts (`ttf`, `otf`, `woff`, `woff2`)
- Storage path: `portal-files/{quote_id}/client/` (uploads) · `portal-files/{quote_id}/admin/` (deliverables)
- Files retained indefinitely unless manually deleted by admin

**`portal_files` schema:**
```sql
CREATE TABLE portal_files (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id     UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  uploaded_by  TEXT NOT NULL CHECK (uploaded_by IN ('admin', 'client')),
  file_name    TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  mime_type    TEXT NOT NULL,
  size_bytes   BIGINT NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT now()
);
```

### 5. Message Board
Threaded two-way messaging between the client and the Raspucat team. Supersedes `009_client_message_board.md` (deprecated — old design used no-login token URL; this uses proper Supabase Auth session).

**Client side:**
- View full message thread (oldest first, auto-scrolls to bottom on load)
- Compose and submit a new message
- Empty message body rejected client-side
- Unread admin replies shown with a visual indicator (dot/badge)
- Mobile-friendly

**Admin side:**
- Unread message badge on client row in admin panel
- Open full message thread per client from the Quote Detail Drawer
- Compose and send a reply — marks all client messages as read
- Unread count included in admin stats bar notification badge

**Data model:**
```sql
CREATE TABLE portal_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id        UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  sender          TEXT NOT NULL CHECK (sender IN ('admin', 'client')),
  body            TEXT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT now(),
  read_at         TIMESTAMPTZ,       -- null = unread by admin
  client_read_at  TIMESTAMPTZ        -- null = unread by client
);
```

**RLS:** Clients can only read/write messages tied to their own `quote_id`. Enforced via Supabase RLS — client's authenticated UID matched to their quote row via `quotes.user_id`.

**Real-time:** No for MVP (page refresh / pull-to-refresh). Avoids Supabase Realtime complexity.

**Future:** Email notification to client when admin replies (Resend). File/image attachments in messages.

### 6. Approve Deliverables
- Admin can mark items as "Awaiting Approval"
- Client clicks approve or request revision with optional note
- Revision rounds are uncapped for MVP

**Data model:**
```sql
CREATE TABLE portal_deliverables (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id      UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  file_id       UUID REFERENCES portal_files(id) ON DELETE SET NULL,
  title         TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'awaiting_approval', 'approved', 'revision_requested')),
  revision_note TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);
```

### 7. Add Modules
- Same module selection flow as the admin "Add Module" panel
- Simplified checkout: confirm card on file (`stripe_customer_id` on `quotes`) or enter new card
- **Payment failure:** If charge fails (declined/expired card), client sees an inline error with options to retry or enter a new card. No module is added until payment succeeds.
- On payment success:
  - Client receives Resend confirmation email (themed, on-brand)
  - Admin receives Resend notification email
  - Admin panel shows a badge/pill on the client row: **"Feature Pending"**

---

## Admin Panel Changes
- **"Feature Requested" pill** on client rows — two colors: gold (unacknowledged), teal (acknowledged, not yet live). Pill disappears only when all add-ons are marked live.
- **Acknowledge** button in Quote Detail Drawer → marks module seen, switches pill to teal
- **Mark Live** button in Quote Detail Drawer → sets `live_at`, inserts module into `quote_modules`, pill disappears
- Ability to manually toggle project stage (`Transmitting` / `Compiling` / `Deployed`)
- File upload interface for delivering files to clients
- Deliverable approval management

---

## Backend / Data Requirements

### Supabase Auth
- Magic link + session persistence
- Magic link TTL: 1 hour (Supabase default)
- Session refresh TTL: 1 week (Supabase default)
- Resend magic link available from `/portal/login`

### RLS
Row Level Security enforced on all portal tables. The `quotes` table must have a `user_id UUID REFERENCES auth.users(id)` column, populated when the magic link is first claimed. All portal RLS policies join via `quotes.user_id = auth.uid()`.

> **Required migration:** Add `user_id UUID REFERENCES auth.users(id)` column to `quotes` table.

### Storage
- Bucket: `portal-files` (private — no public access)
- Structure: `{quote_id}/client/` and `{quote_id}/admin/`
- RLS: clients can read/write only their own `{quote_id}/` prefix

### Stripe
- Payment history retrieved per customer via `quotes.stripe_customer_id`
- Module add-on payments use Stripe Payment Intents with saved payment method
- Payment failure surfaces inline — no silent failures

### Resend
- Two new email templates: client add-on confirmation, admin add-on notification
- Existing template: magic link (already in deposit confirmation email)

### New DB Tables (migrations required)
- `portal_files` — file exchange (schema above)
- `portal_messages` — message board (schema above)
- `portal_deliverables` — approval workflow (schema above)
- `client_modules_pending` — tracks purchased-but-not-implemented add-ons

**`client_modules_pending` schema:**
```sql
CREATE TABLE client_modules_pending (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id        UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  module_id       UUID NOT NULL REFERENCES modules(id),
  purchased_at    TIMESTAMPTZ DEFAULT now(),
  acknowledged_at TIMESTAMPTZ,  -- null = unseen by admin (gold pill)
  live_at         TIMESTAMPTZ   -- null = not yet live; set triggers quote_modules insert
);
```

**Add-on module lifecycle:**
| State | Admin pill | Portal status |
|---|---|---|
| `acknowledged_at = null` | **Feature Requested** (gold — unseen) | Queued |
| `acknowledged_at` set, `live_at = null` | **Feature Requested** (teal — in progress) | In Progress |
| `live_at` set | Pill gone | Module appears in active modules |

**Admin drawer actions (Pending Modules section):**
- Unacknowledged → **Acknowledge** button (gold) — marks seen, starts work
- Acknowledged, not live → **Mark Live** button (teal) — sets `live_at`, inserts into `quote_modules`, refreshes

**Edge function needed:**
| Function | Purpose |
|---|---|
| `admin-mark-module-live` | Sets `live_at = now()` on `client_modules_pending`; inserts row into `quote_modules`; logs to `quote_events` |
| `admin-get-pending-modules` (update) | Return `unacknowledged_counts` and `in_progress_counts` separately (both where `live_at IS NULL`); per-quote list filter `live_at IS NULL` |

---

## Acceptance Criteria
- [x] Deposit email contains a working magic link to `/portal`
- [x] Expired magic link prompts client to request a new one from `/portal/login`
- [x] Client lands in portal and session persists across browser refreshes
- [x] Expired session silently redirects to `/portal/login` with soft prompt
- [x] Client can view their plan, status, and payment history
- [x] Project status displays correct stage: `Transmitting`, `Compiling`, or `Deployed`
- [x] Client can upload files (max 50 MB, allowed types enforced); admin can see and download them
- [x] Admin can upload deliverable files; client can download and approve/request revision
- [x] Client sees unread indicator when admin has replied to a message
- [x] Client can send messages; admin responds from admin panel
- [x] Client can add modules via simplified Stripe checkout
- [x] Payment failure shows inline error with retry/new card option
- [x] Both client and admin receive Resend emails on module purchase
- [x] Admin panel shows "Feature Pending" pill on client row after module purchase
- [x] Admin can manually set project stage to `Transmitting`, `Compiling`, or `Deployed`
- [x] All data is RLS-scoped — clients cannot access other clients' data

---

## Dependencies
- `009_client_message_board.md` — deprecated, absorbed into this feature
- Stripe integration (existing)
- Resend email templates (existing infrastructure)
- Admin panel client detail drawer (existing)
- **Migration required:** `quotes.user_id UUID REFERENCES auth.users(id)`

---

## Out of Scope (for now)
- Subdomain `portal.raspucat.com`
- Client self-service cancellation
- Automated stage transitions
- Real-time message updates (post-MVP)
- Email notification to client on admin reply (post-MVP)
- File/image attachments in messages (post-MVP)
