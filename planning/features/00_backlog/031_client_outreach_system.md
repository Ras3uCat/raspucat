# 031_client_outreach_system

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

**Mode:** STUDIO

---

## Overview

A repeatable client acquisition system for finding and converting web design clients. Two parts:
(1) 7 Claude Code sales skills installed in `.claude/skills/` for interactive use, and (2) an
Outreach CRM tab in the admin panel — lead database, email tracking via Resend, pipeline stages,
and a draft-review queue before sending.

Primary outreach channel: community-based (Facebook groups, Reddit, forums via `/client-locator`).
Cold email via secondary channel using `outreach.ras3ucat.com` subdomain.

---

## The 7 Skills (installed at `.claude/skills/`)

Use these in order for each new vertical:

| Step | Skill | When to Use |
|---|---|---|
| 1 | `/industry-download` | Before any outreach — become an industry insider |
| 2 | `/ride-along` | Build empathy — day-in-the-life of the business owner |
| 3 | `/money-map` | Pick the one painful, buildable, recurring problem |
| 4 | `/client-locator` | Find WHERE they hang out online + outreach scripts |
| — | Go post/DM in communities, book a discovery call | — |
| 5 | `/discovery-script` | Before the call — exact questions to ask |
| 6 | `/blueprint-builder` | After the call — transcript → Claude Code build spec |
| 7 | `/closer-deck` | After the call — transcript → 6-slide HTML presentation |

---

## User Stories
- As admin, I want to add leads manually and track them through a pipeline.
- As admin, I want to compose email drafts, review them, then send in a batch.
- As admin, I want to see when leads open or click my emails.
- As admin, I want phone numbers auto-extracted from reply emails.
- As admin, I want "Copy Prompt" buttons to pre-fill Discovery Script and Closer Deck skills with a lead's data.

---

## Acceptance Criteria

- [ ] 7 skills installed and invocable in Claude Code sessions
- [ ] `leads`, `outreach_emails`, `outreach_settings` tables exist with RLS enabled
- [ ] Admin panel has an "Outreach" tab (index 3)
- [ ] Lead pipeline view: all stages, score badge, last-contact date
- [ ] Manual lead add/edit form works; score auto-calculated
- [ ] Settings panel: industries, cities, cadence (emails/run, runs/week, follow-up days)
- [ ] Email compose panel: subject + body, saved as draft (`sent_at = NULL`)
- [ ] Draft review queue: Ryan reviews drafts, approves, clicks "Send Batch"
- [ ] Emails sent from `ryan@outreach.ras3ucat.com` with unsubscribe + booking CTA
- [ ] Resend webhook updates `opened_at` / `clicked_at` on outreach emails
- [ ] Inbound reply webhook updates `replied_at` + extracts phone number from body
- [ ] Unsubscribe sets lead status to `unsubscribed`
- [ ] "Copy Prompt" button on Call Booked stage copies pre-filled Discovery Script prompt
- [ ] "Copy Prompt" button on Proposal stage copies pre-filled Closer Deck prompt
- [ ] All files stay under 300 lines

---

## Architecture

### DB Tables
- `leads` — company, contact info, status, score, source, notes, follow-up scheduling
- `outreach_emails` — per-email tracking with Resend IDs, sequence step, open/click/reply timestamps
- `outreach_settings` — singleton config row

### Edge Functions
| Function | Auth | Purpose |
|---|---|---|
| `admin-leads` | adminToken | CRUD on leads table, score calculation |
| `admin-outreach-email` | adminToken | Draft creation, send, send-batch, settings CRUD |
| `resend-outreach-webhook` | Resend-Signature | Open/click/bounce + inbound reply + phone extraction |

### Flutter Files (new)
- `lib/app/data/models/lead_model.dart`
- `lib/app/data/repositories/outreach_repository.dart`
- `lib/app/controllers/admin_outreach_controller.dart`
- `lib/app/modules/widgets/admin_outreach_widget.dart`
- `lib/app/modules/widgets/_outreach_pipeline_view.dart`
- `lib/app/modules/widgets/_outreach_settings_panel.dart`
- `lib/app/modules/widgets/_lead_detail_panel.dart`
- `lib/app/modules/widgets/_outreach_compose_panel.dart`

### Flutter Files (modified)
- `lib/app/modules/screens/admin_screen.dart` — add Outreach tab (index 3)
- `lib/app/controllers/admin_controller.dart` — init + setToken + loadSettings

---

## Dependencies
- Resend: `outreach.ras3ucat.com` subdomain verified + MX record for inbound (one-time DNS setup)
- Supabase secret: `RESEND_WEBHOOK_SECRET`

### One-Time DNS Setup (before deploying)
1. Add `outreach.ras3ucat.com` as verified sending domain in Resend dashboard
2. Add Resend's inbound MX record to `outreach.ras3ucat.com` DNS
3. Configure Resend inbound webhook URL → `resend-outreach-webhook` Edge Function

---

## Implementation Order
1. Copy 7 skills to `.claude/skills/` ✅
2. DB migration
3. `admin-leads` Edge Function + pipeline view + manual lead entry
4. `admin-outreach-email` draft/settings + compose panel + settings panel
5. `admin-outreach-email` send/send-batch
6. `resend-outreach-webhook` (outbound: open/click/bounce)
7. `resend-outreach-webhook` (inbound: reply + phone extraction)
8. "Copy Prompt" buttons for Discovery Script + Closer Deck

---

## Verification
1. Run `/client-locator` in Claude Code for "HVAC" → verify community playbook output
2. DB migration → verify 3 new tables in Supabase dashboard
3. Settings panel → configure cadence + industries → verify `outreach_settings` row
4. Manually add a test lead → verify score calculated, appears in pipeline view
5. Compose email draft → verify `outreach_emails` row with `sent_at = NULL`
6. Approve + send batch → verify email received in inbox from `ryan@outreach.ras3ucat.com`
7. Open the email → verify `opened_at` populated via Resend webhook
8. Reply with a phone number in body → verify `leads.phone` populated, `status = 'replied'`
9. Unsubscribe link → verify `leads.status = 'unsubscribed'`
10. "Copy Prompt" (Call Booked) → verify clipboard contains pre-filled discovery script prompt
