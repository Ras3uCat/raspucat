# 039 — Sync prepare-reply Outputs to Admin Panel

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`prepare-reply` generates `custom-plan.md` and `proposal.html` locally but has no sync step.
`sync-lead-reports.sh` also doesn't include them. The admin panel Reports tab can't display
them. Admins must manually open local files to see the confirmed plan or proposal.

This feature also disambiguates the two "custom plan" files that exist in the pipeline:
- `custom-plan-draft.md` (from `prepare-lead`) — internal pre-call pricing estimate, never sent
- `custom-plan.md` (from `prepare-reply`) — confirmed plan with agreed numbers, feeds closer-deck

---

## User Stories
- As the business owner, after running `prepare-reply` I want to see the confirmed plan and
  proposal in the admin panel so I can review them without opening local files.
- As a developer running the pipeline, I want clear labeling of draft vs. confirmed plan so I
  don't accidentally overwrite the pre-call estimate with post-call numbers.
- As the business owner, I want to distinguish the pre-call draft from the post-call confirmed
  plan in the admin panel so I understand the progression from estimate to confirmed scope.

---

## Acceptance Criteria
- [ ] `prepare-reply` SKILL.md has a Step N that syncs `custom-plan.md` and `proposal.html`
      to Supabase via the `sync-reports` action on `admin-leads`.
- [ ] `sync-lead-reports.sh` is updated to accept `--proposal` and `--custom-plan` flags
      (explicit flags chosen — see Design Decisions). Uploads `proposalHtml` and
      `customPlanMd` to the renamed columns.
- [ ] `prepare-lead` sync call is updated to write to `custom_plan_draft_md` (renamed column)
      instead of the old `custom_plan_md` key — verified not to overwrite post-call data.
- [ ] `closer-deck` skill and any code reading `custom_plan_md` from Supabase is audited and
      updated to use the new column name. No closer-deck breakage after rename.
- [ ] Admin panel Reports tab shows the synced proposal and custom plan. Confirmed (not assumed)
      that existing conditional rendering handles new columns when non-null.
- [ ] `proposal_html` is treated as trusted skill-generated content (not user input). Display
      method in admin panel is noted in implementation comments. No unsanitized user-controlled
      HTML is accepted via this path.
- [ ] `admin-leads` Edge Function is updated to accept `customPlanMd` and `proposalHtml`
      in the `sync-reports` action payload and redeployed after changes.
- [ ] Both `prepare-lead` and `prepare-reply` skill files clarify the distinction between
      `custom-plan-draft.md` and `custom-plan.md` in a short callout.
- [ ] Re-running `prepare-reply` for the same lead overwrites `custom_plan_md` and
      `proposal_html` (last-write-wins). Behavior is confirmed acceptable by QA.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Column name | Separate DB columns: `custom_plan_draft_md`, `custom_plan_md`, `proposal_html` | Avoids overwriting pre-call estimate with post-call plan |
| Sync mechanism | `sync-reports` action (already exists) | Consistent with prepare-lead flow |
| Admin panel | Existing Reports tab adds new tabs | Needs explicit confirmation before implementation — not assumed |
| Flag interface | Explicit `--proposal` and `--custom-plan` flags on `sync-lead-reports.sh` | Avoids ambiguity over auto-detection; keeps script callers explicit |
| Idempotency | Last-write-wins on re-run | Overwriting is safe — confirmed plan supersedes any prior version |
| `proposal_html` trust level | Trusted skill-generated content, not user input | Skill controls the HTML source; no sanitization needed, but display method must be documented |

---

## Scope Control
- [x] Included: DB migration — rename `custom_plan_md` → `custom_plan_draft_md`, add `custom_plan_md` and `proposal_html` columns
- [x] Included: `sync-lead-reports.sh` update (explicit `--proposal` / `--custom-plan` flags)
- [x] Included: `prepare-reply` SKILL.md sync step added
- [x] Included: `prepare-lead` sync call updated to use renamed `custom_plan_draft_md` key
- [x] Included: `closer-deck` audit for `custom_plan_md` column references
- [x] Included: `admin-leads` Edge Function update + redeploy
- [x] Included: Admin panel conditional rendering confirmed (not assumed)
- [x] Included: Disambiguation callout in both prepare-lead and prepare-reply skills
- [ ] NOT Included: Retroactive backfill of `custom_plan_draft_md` for leads that had no prior custom plan draft

---

## Implementation Detail

**Migration:**
```sql
-- Rename existing column so prepare-lead draft is clearly labeled
ALTER TABLE public.leads
  RENAME COLUMN custom_plan_md TO custom_plan_draft_md;

-- Add post-call confirmed plan and proposal columns
ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS custom_plan_md TEXT,
  ADD COLUMN IF NOT EXISTS proposal_html TEXT;

-- rollback:
-- ALTER TABLE public.leads RENAME COLUMN custom_plan_draft_md TO custom_plan_md;
-- ALTER TABLE public.leads DROP COLUMN IF EXISTS custom_plan_md;
-- ALTER TABLE public.leads DROP COLUMN IF EXISTS proposal_html;
```

**`sync-lead-reports.sh`:** Add explicit `--proposal <path>` and `--custom-plan <path>` flags.
Upload content to `proposalHtml` and `customPlanMd` payload keys respectively.

**`prepare-lead` sync call:** Update payload key from `customPlanMd` → `customPlanDraftMd`
to match the renamed column.

**`admin-leads` sync-reports action:** Accept `customPlanMd`, `proposalHtml`, and
`customPlanDraftMd` (for prepare-lead). Write to corresponding columns. Deploy after changes.

**`closer-deck` audit:** Grep for `custom_plan_md` in skill files and any Edge Functions.
Update all references to use new column name.

**`prepare-reply` SKILL.md:** Add after the final file generation step:
```
Sync outputs to Supabase:
! ./scripts/sync-lead-reports.sh {lead-id} {client-slug} $ADMIN_TOKEN \
    --custom-plan outputs/{client-slug}/custom-plan.md \
    --proposal outputs/{client-slug}/proposal.html
```
Token source: `$ADMIN_TOKEN` env var (see `.env.local`).

---

## Edge Cases & QA
- [ ] Old leads that had `custom_plan_md` populated before the rename → migration handles via RENAME. Verify data intact post-migration.
- [ ] Reports tab in admin panel shows new tabs only when columns are non-null — confirm with actual admin panel code, not assumption.
- [ ] `prepare-lead` still writes `custom-plan-draft.md` locally and syncs to `custom_plan_draft_md` column — verify sync-reports.sh uses the renamed column key after update.
- [ ] `closer-deck` runs successfully end-to-end after column rename — no missing data errors.
- [ ] Re-running `prepare-reply` twice for the same lead: second run overwrites first, no errors, no duplicate rows.
- [ ] `proposal_html` displayed in admin panel via safe rendering path (not raw `innerHTML` on user-controlled content) — document the display method used.
