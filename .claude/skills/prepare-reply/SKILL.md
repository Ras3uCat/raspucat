---
name: prepare-reply
description: Prepares the full pre-call research package when an outreach lead has replied. Automatically pulls the lead record and reply body from Supabase via MCP (no copy-paste), then generates: discovery script, closer deck, custom-plan.md (module + pricing recommendation), and proposal.html (full written scope of work). Trigger phrases include "prepare reply", "they replied", "[company] replied", "build the call prep", "get the deck ready", or any request to prepare for a call after a prospect has responded.
---

# Prepare Reply

When a lead replies, this skill pulls their record and reply body automatically, then builds the full pre-call research package in one command.

## What This Skill Does

**Input:** A lead name or ID (lead must have status `replied` with a `reply_body` stored in Supabase)

**Output:**
1. `planning/leads/{client-slug}/discovery-script.md` — tailored question sequence for the call
2. `planning/leads/{client-slug}/closer-deck.md` — 6-slide HTML presentation
3. `planning/leads/{client-slug}/custom-plan.md` — module + pricing recommendation (real numbers)
4. `planning/leads/{client-slug}/proposal.html` — full written scope of work (print-ready)

---

## Step 1 — Pull the Full Lead Context via MCP

Query Supabase for:
- The lead's full record (all audit fields, score, pain points, decision maker, industry)
- The `reply_body` from `outreach_emails` where `lead_id` matches and `replied_at` is populated
- The original email draft that was sent (subject, body)
- The industry profile for context
- The blueprint from `planning/leads/{lead-id}/blueprint.md` if it exists

The reply body is captured automatically when inbound email arrives via Cloudflare Email Worker. If `reply_body` is null, tell the user: "Reply body not yet captured — check that Cloudflare email routing is active, or paste their reply directly."

---

## Step 2 — Analyze the Reply

Before generating anything, extract signal from the reply:
- What did they focus on? (cost, timing, skepticism, specific pain they confirmed)
- What numbers did they volunteer? (employees, revenue, existing tool costs)
- What is their tone? (guarded / curious / ready to buy)
- What objections surfaced? (already have a solution, bad timing, need to check with partner)
- What did they NOT mention that you expected?

This analysis is the raw material for all four outputs.

---

## Step 3 — Custom Plan Recommendation

Based on the blueprint and the lead's confirmed pain points, write `custom-plan.md`:

**Content:**
- Recommended plan tier (Starter / Pro / Premium) with justification
- Selected modules that solve their specific pain points, one per line:
  - Module name
  - What problem it solves for this client specifically
  - Individual module price (use current Raspucat pricing)
- Setup total, deposit, balance
- Monthly fee (subscription plan price)
- One paragraph: "Why this plan" — explains the recommendation in plain language

**Purpose:** This document feeds Slide 5 (Investment) of the closer deck with real numbers instead of `[PRICE]` placeholders. Never use `[PRICE]` or `[AMOUNT]` — commit to real numbers from the pricing sheet.

Save to: `planning/leads/{client-slug}/custom-plan.md`

---

## Step 4 — Full Written Proposal

Generate `proposal.html` — a print-ready, client-facing document:

**Sections:**
1. **Cover** — Client name, prepared date, "Prepared by Raspucat"
2. **The Problem** — Their current situation in their own language (mirror the pain points back). Reference the website audit data where it supports the narrative (score, platform, missing features).
3. **The Solution** — What we're building and why it solves their specific problem. Pull from the blueprint's "Core Features" section.
4. **How It Works** — Simplified explanation of the build + delivery process (3–4 bullet points). Include timeline estimate.
5. **Deliverables** — Bulleted list of what they receive at the end of the engagement.
6. **Investment** — Pull from `custom-plan.md`. Show plan tier, modules, setup total, monthly fee, deposit amount, balance.
7. **Next Step** — One clear CTA: "To move forward, reply with your availability for a 30-minute onboarding call, or [deposit link]."

**Styling:** Inline CSS. Match the visual style of `brand_brief_report.html` and `competitor_report.html` — clean, professional, print-ready. "Prepared by Raspucat" footer on every page. Dark header bar, clean body typography, table for investment breakdown.

Save to: `planning/leads/{client-slug}/proposal.html`

---

## Step 5 — Build the Discovery Script

Follow the discovery-script skill output structure (Call Frame → Rapport → Context → Problem-Finding → Dollar-Quantifying → Soft Close → Listen-For Cheat Sheet → Objections).

Adjustments based on the reply:
- If they volunteered specific pain → skip early funnel questions and go to dollar quantification
- If they were guarded → extra rapport questions, lighter opening questions
- If they mentioned a specific number → build dollar-quantifying section around confirming and expanding that number
- If they mentioned an objection → include handling note in the Objections section

Save to: `planning/leads/{client-slug}/discovery-script.md`

---

## Step 6 — Build the Closer Deck

Follow the closer-deck skill output structure (6 slides: Where You Are Today → What This Is Costing You → What's Possible → How It Works → The Investment → Next Step).

**Slide 5 (Investment):** Use real numbers from `custom-plan.md` — not `[PRICE]`. Show plan tier, key modules, setup total, deposit, monthly fee.

Key inputs:
- **Slide 1:** Website audit data (PageSpeed score, platform, missing CTA) + numbers they volunteered in the reply
- **Slide 2:** Industry Money Map figure adjusted for their market/size
- **Slide 3:** Conservative recovery estimate (20–30% of lost revenue)
- **Slide 4:** Blueprint features section
- **Slide 6:** One clear CTA

Where numbers are not yet confirmed, use industry averages with "(to confirm on call)" note.

Save to: `planning/leads/{client-slug}/closer-deck.md`

---

## Step 7 — Confirm and Summary

```
Research package ready for [Company Name]:

Custom Plan:       planning/leads/{lead-id}/custom-plan.md
  Recommended:     [Plan tier] — $[setup] setup, $[monthly]/mo
  Key modules:     [comma-separated]

Proposal:          planning/leads/{lead-id}/proposal.html
  Ready to send post-call or share in Slide 6

Discovery Script:  planning/leads/{lead-id}/discovery-script.md
  Key focus:       [1-2 things their reply told you to probe]
  Watch for:       [most likely objection]

Closer Deck:       planning/leads/{lead-id}/closer-deck.md
  Cost figure:     $[X]/month
  Confirm on call: [1-2 numbers still unverified]
```

---

## What Comes Next

- Review the discovery script — know the question sequence cold
- Review the closer deck — know which numbers are confirmed vs. estimated
- Send the proposal AFTER the call once the numbers are confirmed
- After the call: update lead status to `call_booked` or `proposal_sent`

## When to Use This Skill

✅ Lead status is `replied` and `reply_body` is stored in Supabase
✅ You have not yet prepared for this specific reply

❌ Don't run before the lead replies — the reply context is the entire point
❌ Don't run if the reply is an unsubscribe or auto-responder — check intent first
