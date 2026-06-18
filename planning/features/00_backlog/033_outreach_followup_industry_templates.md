# 033 — Follow-up Emails Use Industry Templates

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`auto-draft-followups` currently generates a hardcoded generic follow-up body regardless of
industry. The industry email template system (feature 032) is completely bypassed. Follow-up
emails should start from the industry template and be marked as a follow-up, falling back to
generic copy only when no template exists for the lead's industry.

---

## User Stories
- As the business owner, I want follow-up emails to match the same industry-specific voice as
  the first email so the sequence feels cohesive, not generic.
- As a recipient, I don't want a follow-up that reads like it was written for a hair salon when
  I run a tattoo shop.

---

## Acceptance Criteria
- [ ] `auto-draft-followups` loads `industry_profiles` for the lead's `industry` field.
- [ ] If `email_body_template` is a non-empty string on the profile, follow-up body uses it with
      `{FIRST_NAME}` and `{COMPANY}` substituted.
- [ ] If `email_subject_template` is a non-empty string on the profile, follow-up subject uses it
      (substituting `{COMPANY}`) with "Re: " always prepended (all drafts from this function are
      follow-ups — step 1 is never generated here).
- [ ] Partial template: if only one of `email_subject_template` / `email_body_template` is set,
      the set field uses the template and the unset field falls back to generic copy independently.
- [ ] If no industry template exists (or lead's `industry` is null/empty), falls back to current
      generic body/subject.
- [ ] New follow-up drafts appear in the Drafts tab with the correct subject.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Template source | `industry_profiles.email_body_template` | Single source of truth, already managed via Templates tab |
| "Re: " prefix | Always prepend for all follow-up drafts | `auto-draft-followups` only creates follow-ups — step 1 is never generated here, so the condition is always true |
| Partial template (only one field set) | Use template for the set field, generic for the unset field | Avoids silently discarding a valid template just because the paired field is missing |
| Empty string templates | Treat `""` same as null — use fallback | An empty template would produce a blank email; falsy check is correct |
| Fallback | Generic copy unchanged | Avoids hard failure when no template synced |

---

## Scope Control
- [x] Included: Load industry template in `auto-draft-followups` and use for body + subject
- [x] Included: Fallback to existing generic copy when no template
- [ ] NOT Included: Per-lead template customization (that's done in the compose panel)
- [ ] NOT Included: Multi-step template variation (all steps use same template with "Re: " prefix)

---

## Prerequisites
- Feature 032 (industry template system) must be deployed to production.
- `industry_profiles` table must have `email_body_template` and `email_subject_template` columns.
- Without these, this feature silently degrades to always using fallback — no error surfaced.

---

## Implementation Detail

**File:** `supabase/functions/admin-outreach-email/index.ts` — `auto-draft-followups` action

Current code (lines ~353–369) generates a hardcoded `subject` and `bodyHtml` inside the loop.

Change: before the per-lead loop, load all `industry_profiles` once. Inside the loop:
```ts
const industryKey = lead.industry?.toLowerCase() ?? '';
const profile = industryKey
  ? industryProfiles.find(
      p => p.name.toLowerCase() === industryKey ||
           p.slug.toLowerCase() === industryKey
    )
  : undefined;
const firstName = (lead.decision_maker_name ?? '').split(' ')[0] || '[Name]';
const company = lead.company_name;

const company = lead.company_name ?? '[Company]';

const subject = profile?.email_subject_template
  ? `Re: ${profile.email_subject_template.replace('{COMPANY}', company)}`
  : `Following up — ${company}`;

const bodyHtml = profile?.email_body_template
  ? profile.email_body_template
      .replace(/\{FIRST_NAME\}/g, firstName)
      .replace(/\{COMPANY\}/g, company)
  : `<p>Hi,</p> ... existing fallback ...`;
```

Load profiles once before loop:
```ts
const { data: industryProfiles } = await supabase
  .from('industry_profiles')
  .select('slug, name, email_subject_template, email_body_template');
```

**No Flutter changes needed.**

---

## Edge Cases & QA
- [ ] Lead with no `decision_maker_name` → uses `[Name]` placeholder, not empty string.
- [ ] Lead with null/undefined `industry` → skips profile lookup, uses generic body + subject.
- [ ] Lead with null/undefined `company_name` → uses `[Company]` placeholder, not "null".
- [ ] Lead whose `industry` doesn't match any profile slug or name → falls back to generic.
- [ ] `email_body_template` is `""` (empty string) → treated as unset, uses generic body.
- [ ] `email_subject_template` is `""` (empty string) → treated as unset, uses generic subject.
- [ ] Only `email_subject_template` is set → template subject used, generic body used.
- [ ] Only `email_body_template` is set → template body used, generic subject used.
- [ ] Industry template contains `{BOOKING_LINK}` / `{DEMO_LINK}` → wrapEmailHtml replaces them at send time (existing behavior, no change needed).
