# 038 — send-batch Idempotency Check

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`send-batch` fetches all unsent drafts (`sent_at IS NULL`) and sends them all. If the button
is clicked twice in quick succession, or if the action is retried after a partial failure, any
draft that received a `resend_id` on the first run but wasn't yet marked `sent_at` (due to a
race or partial failure) will be sent a second time. Recipients receive duplicate emails.

---

## Acceptance Criteria
- [ ] `send-batch` skips any email row where `resend_id IS NOT NULL`.
- [ ] Duplicate send is impossible on sequential retries (normal case).
- [ ] Behavior for the normal case (first send, `resend_id = null`) is unchanged.
- [ ] `send-batch` response includes a `skipped` count alongside `sent` and `failed`.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Guard | Skip rows where `resend_id IS NOT NULL` | resend_id is set iff Resend accepted the email |
| DB filter | Also add `WHERE resend_id IS NULL` to the draft-fetch query | Defense-in-depth; avoid fetching rows that will be skipped anyway |
| Concurrent send window | Accepted risk — no transaction/atomic lock | Single-admin usage makes true concurrent sends extremely unlikely; cost of a SQL transaction outweighs risk |

---

## Scope Control
- [x] Included: One-line guard in send-batch loop
- [x] Included: `WHERE resend_id IS NULL` added to draft-fetch query
- [ ] NOT Included: UI-level double-submit prevention (separate concern)
- [ ] NOT Included: SQL-level atomic lock for true concurrent safety (out of scope given single-admin usage)

---

## Implementation Detail

**File:** `supabase/functions/admin-outreach-email/index.ts` — `send-batch` action

In the per-email loop:
```ts
for (const email of drafts) {
  const lead = email.leads as { ... };
  if (!lead?.email) { failed++; continue; }
  if (email.resend_id) { skipped++; continue; }  // ← add this guard
  // ... rest of send logic
}
```

Update the return to include `skipped` count:
```ts
return json({ sent, failed, skipped });
```

---

## Edge Cases & QA
- [ ] First-time send (`resend_id = null`) → proceeds normally, email is sent and `resend_id` written.
- [ ] Second sequential call after partial success → emails with `resend_id` set are skipped; the rest proceed.
- [ ] All emails already sent → `sent = 0`, `skipped = N`, `failed = 0`.
- [ ] Concurrent calls (two rapid taps) → both may send the same email if the first UPDATE hasn't committed; accepted risk per Design Decisions above.
- [ ] UPDATE fails after Resend accepts → `resend_id` stays null; email is re-sent on next retry. This is the preferred failure mode (duplicate > lost send).
- [ ] Draft-fetch query returns only `resend_id IS NULL` rows — confirm filter is present in Supabase query, not just the loop guard.
