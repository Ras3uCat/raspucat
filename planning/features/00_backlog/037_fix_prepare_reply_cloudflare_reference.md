# 037 — Fix Stale Cloudflare Reference in prepare-reply

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`prepare-reply` SKILL.md references "Cloudflare Email Worker" as the mechanism that captures
inbound email replies. The actual implementation uses Resend inbound webhooks (feature 031).
Anyone reading the skill will look for a non-existent Cloudflare integration.

---

## Acceptance Criteria
- [ ] All references to "Cloudflare Email Worker" in `prepare-reply` SKILL.md are replaced with "Resend inbound webhook".
- [ ] The description of how `replied_at` / `reply_body` gets populated matches the actual Resend webhook flow.
- [ ] The user-facing error message on line 31 ("check that Cloudflare email routing is active") is updated to "check that Resend inbound webhook is configured".

---

## Scope Control
- [x] Included: Text correction in one skill file
- [ ] NOT Included: Any code changes

---

## Implementation Detail

**File:** `.claude/skills/prepare-reply/SKILL.md` — line 31 only.

Two replacements on the same line:
1. "Cloudflare Email Worker" → "Resend inbound webhook"
2. "check that Cloudflare email routing is active" → "check that Resend inbound webhook is configured"

Verify the full sentence still reads correctly after both replacements.

---

## Edge Cases & QA
- [ ] No other skill files reference "Cloudflare Email Worker" for reply capture.
