---
id: 032
title: Unified Client Intelligence
mode: STUDIO
status: completed
created: 2026-05-27
activated: 2026-05-28
completed: 2026-05-28
---

# Unified Client Intelligence

## Problem

Two acquisition paths produce clients with radically different intelligence depth before any build begins:

- **Outreach-acquired:** industry profile, website audit (platform/PageSpeed/booking CTA), pain points, decision maker, blueprint — but zero branding data, no competitor report, no brand alignment.
- **Website-acquired:** plan + module selection, payment info, discovery form (delayed, post-deposit) — but zero industry classification, no pain point audit, no site diagnostics, no decision maker, no competitor data.

The three reports that feed every modular_project build (brand_brief, competitor_intel, brand_alignment) require inputs that neither path reliably collects. Website clients get them eventually, manually. Outreach clients never get them after converting.

## Goal

Every paying client — regardless of acquisition channel — ends up with the same intelligence package before the modular_project build starts.

---

## The Unified Flow

```
1a OUTREACH PATH                    1b WEBSITE PATH
Lead discovered (score ≥60)         Client selects plan + submits deposit
                                     (business_website + business_type at checkout)
         ↓                                      ↓
         ←————————— 2. /prepare-lead ————————→
         blueprint + brand_brief + comp_intel + brand_alignment
         logo detected + discovery form pre-populated
         industry research auto-runs if not yet profiled
                          ↓
         ┌────────────────┴────────────────────┐
         │ OUTREACH ONLY                        │ WEB ONLY
         │ 3. Draft email (with /book link)     │ 5b. Confirmation email
         │    → admin approves → Resend sends   │     + portal link
         │           ↓                          │
         │ 4. Reply or calendar booked:         │
         │    /prepare-reply runs:              │
         │    discovery-script + closer-deck    │
         │    + custom-plan.md + proposal.html  │
         │           ↓                          │
         │ 5a. "Convert to Client" button       │
         │     portal opened (awaiting_deposit) │
         │     dashboard shows deposit CTA      │
         └────────────────┬────────────────────┘
                          ↓
         6. DISCOVERY FORM (both paths)
            Pre-populated from site audit
            Logo field pre-filled for client to confirm
            Client edits / adds inspo URLs
            Changes diffed + highlighted in admin panel
            Admin can rerun brand_alignment on demand
                          ↓
         7. DELIVERY (same from here — modular_project)
```

---

## Acceptance Criteria

### Data & Schema
- [ ] `quotes` table has new columns: `outreach_lead_id`, `business_website`, `business_type`, `industry`, `pain_points[]`, `website_audit` jsonb, `decision_maker_name`, `decision_maker_title`, `logo_url`, `discovery_prefill` jsonb, `discovery_changes` jsonb, `reports_status` jsonb
- [ ] `portal_stage` check constraint includes `awaiting_deposit`
- [ ] Migration is timestamped and includes rollback comment

### Checkout Form (Web Path)
- [ ] Checkout form collects `business_website` (optional URL) and `business_type` (text / short dropdown)
- [ ] Both fields written to `quotes` at quote creation
- [ ] `create-payment-intent` and `admin-create-quote` accept + store new fields

### `/prepare-lead` Skill (Both Paths)
- [ ] Step 1: Enhanced website audit — logo detection (og:image, link[rel=icon], /logo.*), color palette, fonts, contact info, hours, tagline extraction
- [ ] Step 2: Industry research auto-runs if `industry` not in `industry_profiles`
- [ ] Step 3: Blueprint builder uses audit data + industry profile
- [ ] Step 4: Brand brief report generated from audit signals
- [ ] Step 5: Competitor intelligence report generated (uses industry + city)
- [ ] Step 6: Brand alignment report generated (uses competitor URLs if no inspo URLs yet)
- [ ] Step 7: `discovery_prefill` jsonb written to quote with all extracted fields
- [ ] All reports saved to `planning/leads/{client-slug}/`
- [ ] For outreach path: draft email created with `/book` link in Drafts queue

### Outreach Email — `/book` Link
- [ ] Public `/book` route exists on the web app — shows available sessions without auth
- [ ] Booking availability Edge Function has a public (unauthenticated) read endpoint
- [ ] Outreach email draft includes the booking URL

### `/prepare-reply` Skill (Outreach Path — Step 4)
- [ ] Generates `custom-plan.md`: recommended plan + modules + pricing (real numbers, not `[PRICE]`)
- [ ] Generates `proposal.html`: scope of work, timeline, deliverables, investment, next step CTA (print-ready inline CSS)
- [ ] `custom-plan.md` content feeds Closer Deck Slide 5 (Investment)
- [ ] Both files saved to `planning/leads/{client-slug}/`

### `admin-convert-lead-to-quote` Edge Function (Outreach Path — Step 5a)
- [ ] Takes `leadId` + plan/module selection + adminToken
- [ ] Creates `quotes` record with all lead intelligence pre-populated
- [ ] Sets `portal_stage: 'awaiting_deposit'`
- [ ] Creates Supabase Auth user, sends magic link email
- [ ] Sends conversion email: plan summary + deposit link + portal access
- [ ] Updates lead status to `closed_won`
- [ ] Returns `{ quoteId, portalUrl, depositUrl }`

### Portal — `awaiting_deposit` Stage
- [ ] Portal is fully accessible at `awaiting_deposit` stage (all tabs visible)
- [ ] Dashboard shows prominent "Complete your deposit to begin" CTA with payment button
- [ ] Discovery form is accessible and submittable before deposit
- [ ] Deposit payment available directly from the dashboard (Stripe Checkout or saved card)

### Portal Discovery Form — Pre-population + Logo
- [ ] On first load, form reads `discovery_prefill` and renders pre-filled values
- [ ] Logo field shows detected logo URL with a preview image; client can confirm or replace
- [ ] Client can edit any field and add inspo URLs
- [ ] On submit: diff computed vs. `discovery_prefill`, stored in `quotes.discovery_changes`

### Admin Panel — Discovery Diff + Rerun
- [ ] Quote detail view shows "Discovery Updated" badge when `discovery_changes` is non-null
- [ ] Diff viewer shows field-by-field comparison (what was pre-filled vs. what client submitted)
- [ ] "Rerun Brand Alignment" button triggers re-run of `/inspo` step with new inspo URLs

### `admin-generate-client-json`
- [ ] Generated `client.json` includes: `INDUSTRY`, `PAIN_POINTS`, `BUSINESS_WEBSITE`, `DECISION_MAKER_NAME`, `DECISION_MAKER_TITLE`, `PAGESPEED_SCORE`, `WEBSITE_PLATFORM`, `LOGO_URL` when these fields are populated on the quote

---

## Implementation Order

1. Migration (`quotes` new columns + `awaiting_deposit` stage)
2. Checkout form updates (`business_website` + `business_type`)
3. `admin-convert-lead-to-quote` Edge Function
4. Portal `awaiting_deposit` stage + dashboard deposit CTA
5. Portal discovery form: pre-population + logo field + change tracking
6. Admin panel: discovery diff viewer + Rerun button
7. Public `/book` route + availability endpoint
8. Update `/prepare-lead` skill (7-step expansion)
9. Update `/prepare-reply` skill (custom-plan + proposal)
10. Update `admin-generate-client-json`
11. Flutter UI: "Convert to Client" button in outreach pipeline (`_lead_detail_actions.dart`)

---

## Files to Create / Modify

| File | Action |
|---|---|
| `supabase/migrations/YYYYMMDDHHMMSS_add_client_intelligence_fields.sql` | NEW |
| `supabase/functions/admin-convert-lead-to-quote/index.ts` | NEW |
| `supabase/functions/admin-create-quote/index.ts` | MODIFY |
| `supabase/functions/create-payment-intent/index.ts` | MODIFY |
| `supabase/functions/admin-generate-client-json/index.ts` | MODIFY |
| `supabase/functions/admin-update-quote/index.ts` | MODIFY (discovery_changes) |
| `lib/app/modules/screens/portal_discovery_form.dart` | MODIFY |
| `lib/app/modules/screens/checkout_screen.dart` | MODIFY |
| `lib/app/modules/widgets/_lead_detail_actions.dart` | MODIFY |
| `lib/app/modules/widgets/admin_quote_detail_*.dart` | MODIFY (diff viewer + rerun) |
| `.claude/skills/prepare-lead/SKILL.md` | MODIFY (7-step expansion) |
| `.claude/skills/prepare-reply/SKILL.md` | MODIFY (custom-plan + proposal) |

---

## Decisions Locked

| Decision | Choice |
|---|---|
| Calendar / booking link | Existing raspucat booking system — public `/book` route |
| Custom plan output | Both: `custom-plan.md` (module + pricing) AND `proposal.html` (full scope) |
| Portal access before deposit | Full access + submit allowed; deposit CTA in dashboard |
| Logo detection UX | Pre-filled field in client discovery form (client confirms or replaces) |

---

## Notes

- `discovery_prefill` is read-only from the client's perspective — it's what we learned from their site. `discovery_data` is what they submitted. Both are stored.
- Industry research (`/industry-download` etc.) only runs once per industry — check `industry_profiles` first.
- If `business_website` is not provided at checkout, `/prepare-lead` skips the audit steps and works with industry-only data.
- The proposal.html should match the visual style of the brand_brief_report.html and competitor_report.html (inline CSS, print-ready, "Prepared by Raspucat" footer).
