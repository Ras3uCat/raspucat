# 009_client_message_board

> **DEPRECATED** — Superseded by `010_client_portal.md`. The no-login secret URL auth model is replaced by proper Supabase Auth (magic link + persistent session). Message board detail has been absorbed into 010.

## Status
- [x] Deprecated

---

## Overview
A per-client message board allowing two-way communication between admin and client without
requiring the client to create an account. Each client gets a unique secret URL tied to their
quote. The admin sees all conversations in the admin dashboard.

---

## The No-Login Problem

Clients don't have accounts. The solution is a **client access token** — a UUID generated
per quote and stored in the `quotes` table. The client's unique portal URL embeds this token:

```
raspucat.com/client/[client_token]
```

Knowing the URL is the auth. No password, no session, no account creation.
This is the same model used by Notion share links, Figma view links, and Loom videos.

**Security posture:** Acceptable for this use case. Clients are paying, known individuals
with an existing relationship. The link is sent privately via email. If a link is ever
compromised, admin can regenerate the token (invalidates the old URL).

---

## User Stories
- As a client, I want to send a message to my developer without creating an account.
- As a client, I want to see the full history of our conversation in one place.
- As admin, I want to see all client messages in the dashboard and reply from there.
- As admin, I want to know when a client has sent a new message (unread badge).

---

## Acceptance Criteria

### Client Portal (`/client/[client_token]`)
- [ ] URL renders a minimal branded page showing the client's business name and message thread.
- [ ] Client can type and submit a message (no login required).
- [ ] Client sees full message history (their messages + admin replies), oldest first.
- [ ] Page is mobile-friendly.
- [ ] Invalid/unknown token shows a generic "link not found" message (no quote data leaked).

### Admin Dashboard — Message Integration
- [ ] Each quote row/detail shows an unread message badge when new client messages exist.
- [ ] Admin can open a message thread per quote and see full history.
- [ ] Admin can type and send a reply from the dashboard.
- [ ] Sending a reply marks all client messages for that quote as read.
- [ ] Unread count is included in the stats bar notification badge.

### Token Management
- [ ] `client_token` (UUID) is auto-generated on quote creation (`DEFAULT gen_random_uuid()`).
- [ ] Admin can regenerate a client token from the Quote Detail Drawer (invalidates old URL).
- [ ] Client portal URL is copyable from the Quote Detail Drawer with one click.

---

## Data Model

### DB Changes

```sql
-- Add client_token to quotes table
ALTER TABLE quotes ADD COLUMN client_token UUID DEFAULT gen_random_uuid() NOT NULL;
CREATE UNIQUE INDEX quotes_client_token_idx ON quotes(client_token);

-- New table: quote_messages
CREATE TABLE quote_messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id    UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  sender      TEXT NOT NULL CHECK (sender IN ('admin', 'client')),
  body        TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  read_at     TIMESTAMPTZ -- null = unread
);
```

### RLS Policies

```sql
-- Client can read/insert messages for their quote only (token matched server-side in edge function)
-- Admin token bypasses RLS via edge function (same pattern as existing admin auth)
-- Public: no direct table access — all reads/writes go through edge functions
```

**Note:** Do not expose `quote_messages` directly via Supabase anon key. Route all client
reads and writes through edge functions that validate the `client_token` server-side.

---

## Architecture

### Flutter Routes
| Route | Widget | Access |
|---|---|---|
| `/client/:token` | `ClientPortalScreen` | Public (token-gated server-side) |

### Edge Functions
| Function | Purpose |
|---|---|
| `client-get-messages` | Validates `client_token`, returns quote business name + message thread |
| `client-send-message` | Validates `client_token`, inserts `sender: 'client'` message |
| `admin-get-messages` | Admin-authed, returns thread for a given `quote_id` |
| `admin-send-reply` | Admin-authed, inserts `sender: 'admin'` message, marks client messages as read |
| `admin-regenerate-token` | Admin-authed, generates new `client_token` for a quote |

### Client Portal Flow
```
[Client receives email with portal link]
        ↓
[Opens raspucat.com/client/[token]]
        ↓
[Edge fn validates token → returns quote + messages]
        ↓
[Client reads thread, types message, submits]
        ↓
[Edge fn validates token → inserts message]
        ↓
[Admin sees unread badge in dashboard]
        ↓
[Admin replies → client refreshes portal to see reply]
```

---

## Design Decisions
| Decision | Choice | Rationale |
|---|---|---|
| Auth model | Secret URL (client_token) | No account friction for client; same model as Notion/Figma share links |
| Token scope | One token per quote | Each quote is an independent engagement; tokens are isolated |
| Token regeneration | Admin-only | If link is compromised, admin can invalidate without client involvement |
| Real-time | No (pull-to-refresh / page reload) | Avoids Supabase Realtime complexity for MVP; clients don't expect live chat |
| Notifications to client | Out of scope for MVP | Admin replies don't trigger email to client yet (see future path below) |
| Portal branding | Minimal — brand mark + message thread only | Client portal is functional, not a full product UI |

---

## Future Path (Out of Scope for MVP)
- Email notification to client when admin replies (Supabase edge function + Resend/SendGrid)
- Email notification to admin when client sends a message
- Read receipts visible to both parties
- File/image attachments in messages
- Replace secret URL with Supabase magic link auth for proper session management

---

## Edge Cases & QA
- [ ] Expired or regenerated token returns 404-style response, not a server error.
- [ ] Empty message body is rejected (client and admin side).
- [ ] Message thread is ordered oldest-first, auto-scrolls to bottom on load.
- [ ] Portal URL still works after quote status changes (fully paid, subscription active, etc.).
- [ ] Regenerating token immediately invalidates the previous URL.
