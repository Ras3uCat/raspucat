# Outreach Playbook — Start to Finish

## The Model

By the time you get on a call with a prospect, you already have:
- Their site audited (platform, PageSpeed, pain points)
- Their industry researched (language, benchmarks, cost of the problem)
- A blueprint of what you're building for them
- A discovery script tailored to their reply
- A closer deck with real numbers
- A written proposal ready to send

The "discovery call" is a confirmation call. You present. They confirm. You close.

---

## PHASE 1 — Industry Setup (Once Per Industry)

Run the full pipeline once per industry. Never re-run for an existing industry unless refreshing
stale data — the skill checks for an existing profile and asks before overwriting.

### In Claude Code — one command does everything:

```
/industry-setup HVAC Contractors
```

This chains all four skills in sequence and handles the Supabase sync automatically:

| Step | Skill | Output file |
|---|---|---|
| 1 | `/industry-download` | `planning/industries/hvac-contractors.md` |
| 2 | Sync + benchmark | Profile live in Supabase, Find Leads unblocked |
| 3 | `/ride-along` | `planning/industries/hvac-contractors-ride-along.md` |
| 4 | `/money-map` | `planning/industries/hvac-contractors-money-map.md` |
| 5 | `/client-locator` | `planning/industries/hvac-contractors-client-locator.md` |

The benchmark step (step 2) audits 15 live sites and takes ~60 seconds. The skill will pause and
ask you to run the two `!` commands before continuing.

> **Skip this phase** if you already have the industry profiled — `/industry-setup` will detect
> the existing files and ask before re-running.

---

## PHASE 2 — Configure Targeting

### Admin Panel → Outreach → Settings tab

1. Under **TARGET INDUSTRIES** — type your industry and press Enter to add it
   - If the chip shows an amber warning icon: no profile synced — run Phase 1 first
   - Green chip = profile synced and ready

2. Under **TARGET CITIES** — type `Austin, TX` and press Enter

3. Under **DISCOVERY** — set runs/week (2 recommended)

4. Click **Save Settings**

The benchmark stats appear under each industry profile:
`Avg speed: 41 · 62% on DIY · 18% have booking CTA · n=15 · 2026-05-28`

---

## PHASE 3 — Find Leads

### Admin Panel → Outreach → Pipeline tab

Click **Find Leads** in the top-right header.

What runs automatically (30–90 seconds):
- Google Places pulls up to 20 businesses per industry/city
- Angi scrapes the same city for additional leads
- Every site is audited: platform, PageSpeed vs. industry benchmark, viewport, booking CTA
- Pain points matched against the synced industry profile
- High-score leads (≥60) get Apollo org enrichment and Hunter decision maker lookup
- Cron also runs this automatically every day at 10AM UTC (Supabase pg_cron) — the button is for manual runs. Set discovery runs/week to 0 in Settings to pause the cron.

When it finishes: the pipeline fills with scored, labeled leads.

### Reading the pipeline

Each lead row shows:
- **Company name** + source badges: `G` (Google) `A` (Angi)
- **Score** — green ≥70, orange 40–69, red <40
- **Pain point tags** — amber chips: `No booking`, `Slow site`, `Wix/DIY site`, etc.
- **Status** — current stage in the pipeline
- **Last contact** — relative time since last email

**Prioritize leads with:**
- Score ≥ 60 with 2+ pain point tags
- Decision maker name visible (click to open — shows in Contact section)
- Multi-source badges (G + A = seen on both platforms)

### Clicking into a lead

Click any row to open the detail panel. Shows:
- Contact section: decision maker name/title, website, phone, email, source badges
- Pain point tags from the website audit
- Notes field (free-text, auto-saves on blur)
- Status dropdown + action buttons (send email, mark replied, etc.)

---

## PHASE 4 — Prepare the Lead

**Trigger:** Lead has score ≥ 60 and has not been prepared yet.

### In Claude Code:

```
/prepare-lead McCullough Heating & Air
```

Claude pulls the full lead record automatically via Supabase MCP — no copy-paste needed.
Then runs a 7-step flow:

1. Enhanced website audit (platform, PageSpeed, logo, colors, fonts, contact info)
2. Industry research (loads existing profile, or runs Phase 1 if missing)
3. Blueprint — software build plan based on confirmed pain points only
4. Brand brief report — pre-filled from site audit signals
5. Competitor intel — 3–5 competitors in the same city, audited
6. Brand alignment report — visual direction based on competitors + audit
7. Draft outreach email — written to the Drafts queue (NOT sent — awaits your approval)

**Output files saved to** `planning/leads/mccullough-heating/`:
- `blueprint.md`
- `brand_brief_report.html`
- `competitor_intel.md` + `competitor_report.html`
- `brand_alignment.md` + `brand_alignment_report.html`

---

## PHASE 5 — Review and Send the Email

### Admin Panel → Outreach → Drafts tab

The draft email from `/prepare-lead` appears here. It is NOT sent yet.

Review it:
- Subject line references a specific finding from their site
- Opening line calls out one specific visible problem (not a generic claim)
- Body is 3–4 sentences max: problem cost → what you built → outcome
- CTA: "Book a 15-minute call" → your booking link

**To send:** click the send icon on the draft row.
**To edit:** click the draft to open the compose panel, edit, then send.

After sending: lead status automatically changes to `contacted`.

**Automated follow-up drafts:** the daily cron checks for leads where `next_followup_at`
has passed and creates a new draft — it appears in the Drafts tab. Nothing sends
automatically. You review, edit if needed, then send.

---

## PHASE 6 — When They Reply

### Admin Panel → Outreach → Pipeline tab

Lead status changes to `replied`. Click the lead row to open the detail panel and read
the reply in the email thread.

Their response is data. What they focus on, the numbers they volunteer, their tone —
all of this sharpens the discovery script and closer deck.

### In Claude Code:

```
/prepare-reply McCullough Heating & Air
```

Claude pulls the lead record AND the reply body automatically from Supabase — no
copy-paste needed. Runs a 6-step flow:

1. Pull full context: lead record, reply body, original email, industry profile, blueprint
2. Analyze the reply: what they focused on, numbers volunteered, tone, objections surfaced
3. Custom plan recommendation: plan tier + modules + real pricing (no placeholders)
4. Full written proposal (proposal.html) — print-ready, client-facing
5. Discovery script — question sequence adjusted for what the reply revealed
6. Closer deck — 6-slide HTML presentation with real numbers from the custom plan

**Output files saved to** `planning/leads/mccullough-heating/`:
- `custom-plan.md` — plan tier, modules, setup total, monthly fee
- `proposal.html` — full written scope of work (send post-call)
- `discovery-script.md` — call question sequence
- `closer-deck.md` — 6-slide presentation

**Summary printed to Claude Code:**
```
Research package ready for McCullough Heating & Air:

Custom Plan:   Starter — $2,400 setup, $197/mo
Key modules:   Booking automation, Mobile rebuild, Lead capture

Proposal:      planning/leads/.../proposal.html
Discovery:     Key focus: confirm monthly call volume + average job value
               Watch for: "already have a website guy"
Closer Deck:   Cost figure: ~$3,800/mo in missed bookings
               Confirm on call: actual call volume, close rate
```

---

## PHASE 7 — The Confirmation Call

This is not a discovery call. You already did the discovery. This is a presentation call.

**Before the call — review:**
- `discovery-script.md`: know the question sequence cold
- `closer-deck.md`: know which numbers are confirmed vs. estimated

**Open with something specific:**
> "We found your site scores 38 on mobile — the average HVAC site in Austin scores 47.
> You've also got no online booking. Based on typical HVAC call volume in Austin, we
> estimated you're losing around $3,800/month in missed after-hours requests.
> Does that feel close?"

They confirm or correct the number. You update the deck in real time.
Present the solution. Close on the first call.

**Do NOT send the proposal during the call.** Save it for after.

---

## PHASE 8 — After the Call

### Admin Panel → Outreach → Pipeline tab

Update the lead status:
- Call happened, moving forward → `proposal_sent`
- Signed → `closed_won`
- Passed → `closed_lost`

**Send the proposal:**

The `proposal.html` from `/prepare-reply` is a complete, print-ready written scope of
work. Open it in Chrome, export as PDF, and email it as a follow-up within 24 hours.

---

## Status Reference

| Status | What it means | What triggers it |
|---|---|---|
| `prospect` | Discovered, not yet contacted | Auto — on discovery |
| `contacted` | First email sent | Auto — on send |
| `replied` | They responded | Auto — on reply capture |
| `call_booked` | Confirmation call scheduled | Auto — when prospect books via /book link in email; or set manually |
| `proposal_sent` | Deck/proposal sent or presented | Manual |
| `closed_won` | Signed | Manual |
| `closed_lost` | Passed | Manual |
| `bounced` | Hard bounce — email invalid | Auto — Resend webhook |
| `unsubscribed` | Opted out | Auto — unsubscribe link in email |

---

## Full Loop at a Glance

```
ONCE PER INDUSTRY (in Claude Code)
/industry-setup {Industry Name}
→ runs industry-download + sync + benchmark + ride-along + money-map + client-locator

ADMIN PANEL — Settings tab
Add industry + city → Save

ADMIN PANEL — Pipeline tab (cron daily 10AM UTC + manual)
Find Leads → pipeline fills with scored, audited leads

CLAUDE CODE — score ≥ 60, not yet prepared
/prepare-lead [company name]
→ blueprint + brand brief + competitor intel + brand alignment + draft email

ADMIN PANEL — Drafts tab
Review draft → Send → status: contacted

WHEN THEY REPLY — admin panel shows status: replied
/prepare-reply [company name]
→ custom plan + proposal + discovery script + closer deck

CONFIRMATION CALL
Present closer deck → confirm numbers → close

AFTER CALL
Send proposal.html → update status → closed_won
```

---

## Skill Quick Reference

| Skill | When | Notes |
|---|---|---|
| `/industry-setup` | New industry | Chains all 4 skills + sync + benchmark. One command, full pipeline. |
| `/industry-download` | Advanced — refresh single file | Also called by `/industry-setup`. Run solo to refresh an existing profile. |
| `/ride-along` | Advanced — refresh single file | Solo run to regenerate the narrative only. |
| `/money-map` | Advanced — refresh single file | Solo run to re-rank problems after market changes. |
| `/client-locator` | Advanced — refresh single file | Solo run to update prospecting platforms. |
| `/prepare-lead` | Score ≥ 60, pre-email | Pulls lead from Supabase via MCP automatically. |
| `/prepare-reply` | After lead replies | Pulls lead + reply body automatically. Generates all 4 pre-call files. |
| `/blueprint-builder` | When you have a call transcript | Standalone — converts a transcript into a build spec. |
| `/discovery-script` | At `call_booked` — want sharper questions | Admin panel "Copy Discovery Script Prompt" fills in context. |
| `/closer-deck` | After the call — final version with confirmed numbers | Admin panel "Copy Closer Deck Prompt" fills in context. Paste call notes. |
| `/seo-strategy` | Client needs SEO | Full site audit or per-service optimization. |

---

## File Structure

```
planning/
├── OUTREACH_PLAYBOOK.md          ← this file
├── industries/
│   ├── hvac-contractors.md
│   ├── hvac-contractors-ride-along.md
│   ├── hvac-contractors-money-map.md
│   └── hvac-contractors-client-locator.md
└── leads/
    └── mccullough-heating/
        ├── blueprint.md
        ├── brand_brief_report.html
        ├── competitor_intel.md
        ├── competitor_report.html
        ├── brand_alignment.md
        ├── brand_alignment_report.html
        ├── custom-plan.md
        ├── proposal.html
        ├── discovery-script.md
        └── closer-deck.md
```

---

## Notes

- The Supabase MCP (`~/.claude/settings.json`) gives Claude Code direct read access to
  leads and industry profiles — no copy-paste required when invoking skills
- `/prepare-lead` auto-runs industry research if the profile is missing
- Never run `/prepare-reply` before the lead replies — the reply context is the point
- Send the proposal AFTER the call once numbers are confirmed on the call
- `proposal.html`, `competitor_report.html`, `brand_brief_report.html`, and
  `brand_alignment_report.html` are all print-ready — open in Chrome → export PDF
