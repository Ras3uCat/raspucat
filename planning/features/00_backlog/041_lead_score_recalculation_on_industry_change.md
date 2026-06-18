# 041 — Score Recalculates When Industry Changes

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

**Mode: FLOW**

---

## Overview
The `update` action in `admin-leads` recalculates a lead's `score` column only when contact
fields (email, website, phone) change. Changing a lead's `industry` doesn't trigger
recalculation, even though industry drives the ICP-match component of `calculateScore()`
(`supabase/functions/admin-leads/index.ts:34`).

The secondary bug: even when recalculation does run, the call at line 141 passes
`industry: existing.industry` — so a payload that changes both `email` and `industry`
would recalculate against the *old* industry.

---

## Acceptance Criteria
- [ ] Updating a lead's `industry` field triggers score recalculation in the `update` action.
- [ ] The `score` value in the `update` response equals `calculateScore({ email, website, phone, industry: newIndustry })` — i.e., uses the incoming `industry` value, not the existing one.
- [ ] No change to behavior when industry is not part of the update payload.

---

## Scope Control
- [x] Included: Add `industry` to the fields that trigger score recalculation
- [x] Included: Pass `mapped.industry ?? existing.industry` into `calculateScore` (fixes latent bug)
- [ ] NOT Included: Score audit trail or change log

---

## Implementation Detail

**File:** `supabase/functions/admin-leads/index.ts` — `update` action (~line 133)

**Step 1 — Rename and expand the condition:**
```ts
// Before
if (mapped.email !== undefined || mapped.website !== undefined || mapped.phone !== undefined) {

// After
const scoreFieldsChanged =
  mapped.email !== undefined ||
  mapped.website !== undefined ||
  mapped.phone !== undefined ||
  mapped.industry !== undefined;
if (scoreFieldsChanged) {
```

**Step 2 — Fix the `calculateScore` call to use the incoming industry:**
```ts
mapped.score = calculateScore({
  email:    (mapped.email    ?? existing.email)    as string,
  website:  (mapped.website  ?? existing.website)  as string,
  phone:    (mapped.phone    ?? existing.phone)     as string,
  industry: (mapped.industry ?? existing.industry) as string, // was: existing.industry only
});
```

No DB migration required — `score` column already exists.

---

## Edge Cases & QA
- [ ] Updating only `notes` → score unchanged.
- [ ] Updating `industry` + `email` → score recalculated once using new values for both.
- [ ] Updating only `industry` → score recalculates against new industry ICP match.
- [ ] Lead with no website/email/phone but industry change → score recalculates (may still be low, reflects current state).

**Test file:** `supabase/functions/admin-leads/` — add `update` action tests covering the above cases.
