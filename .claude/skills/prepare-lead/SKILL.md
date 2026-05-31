---
name: prepare-lead
description: Prepares a complete client intelligence package for any qualified lead or new web client. Pulls the record automatically via Supabase MCP, runs an 8-step flow (site audit → industry research → blueprint → brand brief → competitor intel → brand alignment → custom plan draft → discovery pre-population), then creates a draft outreach email for outreach leads. Works on both acquisition paths. Trigger phrases include "prepare lead", "prepare [company name]", "build the research package", "prepare client [name]", "run prepare-lead", or any request to generate the intelligence package for a lead or new client.
---

# Prepare Lead

Generates the full client intelligence package — regardless of whether the client came through outreach or signed up directly through the website.

## What This Skill Does

**Input:** A lead name / lead ID (outreach path) OR a quote ID / client name (web path)

**Output (both paths):**
1. `planning/leads/{client-slug}/blueprint.md` — software build plan
2. `planning/leads/{client-slug}/brand_brief_report.html` — brand brief from site audit
3. `planning/leads/{client-slug}/competitor_intel.md` + `competitor_report.html`
4. `planning/leads/{client-slug}/brand_alignment.md` + `brand_alignment_report.html`
5. `discovery_prefill` jsonb written to the quote record

**Outreach path only:**
6. `planning/leads/{client-slug}/custom-plan-draft.md` — internal plan recommendation (NOT sent to lead)
7. Draft outreach email in the Drafts queue (NOT sent — requires your approval)

---

## Step 1 — Enhanced Website Audit

If a `business_website` URL is available, run a full site audit. Extract:

**Platform detection:** Check for Wix, Squarespace, Weebly, Shopify, WordPress indicators in meta tags, script src URLs, or CSS class patterns.

**PageSpeed score:** Use the PageSpeed Insights API (or estimate from known hosting platform) if available. Note the raw score now — it will be compared against the industry benchmark in Step 2 once the industry profile is loaded.

**Logo detection (priority order):**
1. `<meta property="og:image">` — often the best quality
2. `<link rel="icon">` / `<link rel="shortcut icon">` — fallback
3. Any `<img>` with src matching `/logo`, `logo.png`, `logo.svg`, or `brand` in the path

Surface the best candidate as `logo_url`. This will pre-fill the logo field in the discovery form — the client confirms or replaces it.

**Color extraction:**
- CSS custom properties (`--color-primary`, `--brand-color`, etc.)
- Dominant colors from og:image if available
- Inline style or stylesheet hex values on header/nav elements

**Font detection:**
- Google Fonts `<link>` tags (extract family name)
- CSS `font-family` declarations on `body` or `h1`

**Booking CTA presence:** Look for keywords: "book", "schedule", "appointment", "reserve", "get a quote" in visible link text, buttons, or nav items.

**Contact info extraction:** Phone numbers (patterns: XXX-XXX-XXXX, (XXX) XXX-XXXX), street address, city/state/zip from footer or contact page.

**Hours extraction:** JSON-LD `openingHoursSpecification`, or text patterns like "Mon–Fri: 8am–5pm" in footer or About page.

**Tagline extraction:** `<h1>` text from homepage and `<meta name="description">` content.

If `business_website` is not provided, skip the audit steps and continue with industry-only data.

---

## Step 2 — Industry Research (Auto-run if Not Yet Profiled)

Check `industry_profiles` in Supabase for a matching `slug` based on the lead's `industry` field.

If the industry IS already profiled: load ALL fields and extract the following for use downstream:

**From `pain_points[]`:**
- Which pains are confirmed by the site audit? (missing booking CTA, slow speed, DIY platform)
- Flag the top 2 confirmed pains — these anchor the blueprint and email

**From `money_map_md`:**
- Find the **picked problem** (the one ranked #1 at the end of the money map)
- Extract the specific dollar figure attached to it (e.g., "$1,800/month in missed bookings")
- This number goes into: email body, Closer Deck Slide 2, and the proposal's Problem section

**From `ride_along_md`:**
- Extract 3–5 vocabulary words the owner uses that differ from generic business language
  (e.g., "no-shows" not "missed appointments", "walk-ins" not "new customers")
- Note the biggest friction moments from their day (italicized inner thoughts sections)
- These drive: email opening line, discovery script rapport section, proposal Problem section

**From `client_locator_md`:**
- Note which platform this lead likely came from (Facebook group, referral, Google search)
- This informs the email tone — a Facebook group lead responds differently than a Google search lead

**From `audit_signals.benchmark`:**
Load the benchmark object from the industry profile. If present, extract:
- `avg_pagespeed` — the industry average PageSpeed score across sampled sites
- `pct_with_booking_cta` — share of sites in this industry that have a booking CTA (0.0–1.0)
- `pct_diy_platform` — share of sites on Wix/Squarespace/Weebly/GoDaddy
- `pct_https` — share with HTTPS
- `sample_size` + `sampled_at` — for credibility framing

Use these benchmarks to contextualize the lead's site audit findings:
- If their PageSpeed is below `avg_pagespeed`: flag the gap (e.g., "41 vs. industry avg 65 — 24 points below")
- If `pct_with_booking_cta` is high (> 60%) and this site lacks one: call it out as an outlier ("most shops in this space have online booking — yours doesn't")
- If `pct_diy_platform` is low (< 30%) and this site IS on a DIY platform: they stand out badly among peers
- If benchmark is missing: note it and proceed without comparison framing

These comparisons go into: the blueprint's Problem section, the email body (Step 8), and the discovery pre-fill notes.

If the industry is NOT yet profiled:
1. Run `/industry-download` for the industry
2. Run `/ride-along` for the industry
3. Run `/money-map` for the industry
4. Run `/client-locator` for the industry
5. Sync the profile to Supabase `industry_profiles` (including all narrative fields)
6. Save industry files to `planning/industries/{slug}.md`

---

## Step 3 — Blueprint Builder

Using site audit signals + industry narrative data together:

- Only include features that address pain points **confirmed by the site audit**. Do not invent problems.
- If no booking CTA: booking automation is the core feature
- If slow PageSpeed / DIY platform: rebuild + performance is the project
- If missing contact/phone: lead capture is the core feature

**Apply ride-along vocabulary throughout:** Name features the way the owner names their problems.
Write "eliminate no-shows with automated reminders" not "appointment notification system."
The blueprint's Problem section should read like their inner monologue from the ride-along — not a technical spec.

**Anchor the core feature to the money map's picked problem.** If the money map identified
"missed after-hours leads" as the #1 problem worth $X/month, that becomes Feature #1 in the
blueprint. The dollar figure appears in the Problem section.

Follow the standard blueprint output structure:
> Project Overview → Target Users → Problem → Core Features → Phase 2 → Tech Stack → Database Schema → Implementation Phases → Kickoff Prompt

Save to: `planning/leads/{client-slug}/blueprint.md`

---

## Step 4 — Brand Brief Report

Generate a pre-filled brand brief from the site audit signals:

- **Colors:** Detected primary/secondary colors (label them, show hex)
- **Fonts:** Detected font families
- **Business type:** From `industry` field or checkout `business_type`
- **Tagline / tone:** From extracted h1 + meta description
- **Preliminary personality:** Infer from industry + detected design choices (modern, professional, warm, bold, etc.)

Output as `brand_brief_report.html` — inline CSS, print-ready, matching the styling of `competitor_report.html` and `brand_alignment_report.html`. Include a "Prepared by Raspucat" footer.

Fields that can't be inferred from the site audit are marked `[Client to confirm]` — they will be completed when the discovery form is submitted.

Save to: `planning/leads/{client-slug}/brand_brief_report.html`

---

## Step 5 — Competitor Intelligence Report

Using the lead's `industry` + `city`:

- Identify 3–5 direct competitors in the same city/market
- Audit each competitor's site: platform, PageSpeed, booking CTA presence, features
- Note what each competitor does well and where they fall short
- Summarize the opportunity gap

Output: `competitor_intel.md` (raw analysis) + `competitor_report.html` (print-ready client-facing version, same style as brand_brief_report.html).

Save to: `planning/leads/{client-slug}/competitor_intel.md` and `competitor_report.html`

---

## Step 6 — Brand Alignment Report

Gather inspiration sources:
- If `discovery_prefill.inspo_urls` already populated (from a prior discovery form submission): use those
- Otherwise: use the 2–3 strongest competitor URLs from Step 5 as inspiration sources

Run the brand alignment analysis: for each source URL, extract visual style, color palette, layout patterns, and UX choices. Synthesize into a coherent brand direction that differentiates from competitors while borrowing what works.

Output: `brand_alignment.md` (analysis) + `brand_alignment_report.html` (print-ready, same style).

Save to: `planning/leads/{client-slug}/brand_alignment.md` and `brand_alignment_report.html`

---

## Step 7 — Custom Plan Draft (Internal — Outreach Path Only)

Generate `custom-plan-draft.md` — an internal pricing recommendation built from the blueprint and confirmed audit signals. This document is **never sent to the lead**. Its purpose is to arm you for the call before anyone replies.

**Query the `plans` and `modules` tables from Supabase** to get current real pricing. Never hardcode prices.

**Plan tier selection:**
- Pick the tier whose `ideal_for` description best matches the lead's industry and confirmed problems
- Justify the tier in one sentence tied directly to the money map's #1 problem — not a generic description

**Module selection — only include modules that solve confirmed pain points:**
For each selected module, write one line:
```
- [Module name] ($X setup) — [what problem it solves, in ride-along vocabulary]
```

Do not include modules for problems the site audit did not confirm. If the site has a booking CTA, don't lead with booking unless the audit shows it's broken or deposit-free.

**Pricing block:**
```
Plan:          [Tier name] — $[setup_price] setup / $[monthly_price]/mo
Modules:
  [Module]     +$[price]
  [Module]     +$[price]
  ...
─────────────────────────────
Setup total:   $[sum]
Monthly:       $[monthly_price]/mo
Deposit (50%): $[setup/2]
Balance:       $[setup/2]
```

**"Why this plan" paragraph (3–4 sentences):**
- Connect the tier recommendation directly to the money map's dollar figure
- Reference the 2 strongest audit signals that justify the modules chosen
- Note which module directly addresses the #1 confirmed pain
- Note anything to confirm or adjust on the call (e.g., "Stripe Connect worth raising if artists split commissions")

**Label at top of file:**
```
> ⚠️ INTERNAL ONLY — Do not share with lead. Refine with prepare-reply after they respond.
```

Save to: `planning/leads/{client-slug}/custom-plan-draft.md`

---

## Step 8 — Sync Reports to Supabase (Both Paths)

After all report files are saved locally, sync them to Supabase so they are viewable in the
Admin Panel → lead detail → Reports tab. Use the `sync-reports` action on `admin-leads`.

Output these commands for the user to run (replace `YOUR_TOKEN` and `{lead-id}`):

```bash
! ./scripts/sync-lead-reports.sh {lead-id} {client-slug} YOUR_TOKEN
```

This script reads all five files from `planning/leads/{client-slug}/` and pushes them in one
request. Once synced, the lead detail panel will show a **Reports** section with tabs for
Blueprint, Brand Brief, Competitor, Brand Alignment, and Custom Plan.

If the script isn't available, output individual `! curl` commands using the `sync-reports`
action on `https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-leads` with fields
`blueprintMd`, `brandBriefHtml`, `competitorHtml`, `brandAlignmentHtml`, `customPlanMd`.

---

## Step 9 — Write discovery_prefill to Quote

Assemble the `discovery_prefill` jsonb from all extracted signals and write it to the quote record via the Supabase MCP:

```json
{
  "business_website": "https://...",
  "logo_url": "https://...",
  "color_primary": "#XXXXXX",
  "color_secondary": "#XXXXXX",
  "font_primary": "Montserrat",
  "phone": "512-555-0100",
  "city": "Austin",
  "state": "TX",
  "zip": "78701",
  "hours": "Mon–Fri 8am–5pm",
  "tagline": "Austin's Trusted HVAC Pros"
}
```

Also write `logo_url` directly to `quotes.logo_url` so it's available in `admin-generate-client-json`.

**Outreach path only:** After Step 8, proceed to Step 9 (draft email). Skip Steps 7 and 9 for web path.

---

## Step 9 — Draft Outreach Email (Outreach Path Only)

Write a personalized cold outreach email. Every line should be specific to this business — not templated.

**Subject line (pick one):**
- `[Company name] — [specific site finding]` (e.g., "River City Ink — 41 on mobile")
- A question using their industry vocabulary from the ride-along (e.g., "How many walk-ins did you lose last week?")
- The money map dollar figure reframed as a question (e.g., "Is [Company] leaving $1,400/month on the table?")
- A benchmark comparison if the gap is striking (e.g., "River City Ink — 24 points below average")

**Opening line:** Reference one specific thing found on their site. Never open with a compliment.
Use ride-along vocabulary — call it what they call it, not what a developer would call it.

**Body (3–4 sentences max):**
1. Name the problem using the money map's picked problem + dollar figure
   (e.g., "Most [industry] shops in [city] lose around $X/month to missed after-hours leads...")
2. Reference the site audit signal that confirms this is their specific problem — and if a benchmark
   gap exists, use it: (e.g., "Your site scores 41 on mobile speed — the average [industry] shop
   scores 65 — and there's no way to book online when a visitor lands.")
3. One sentence on what you built to solve it — in plain language, no jargon
4. What the outcome looks like in their terms (more walk-ins, fewer no-shows, less phone tag)

**CTA:** "Book a 15-minute call" — link to `{SITE_URL}/book?leadId={lead_id}`

**Internal notes to extract** (from the planning document — these appear in the `// INTERNAL NOTES` section of the Drafts tab and are never sent to the lead):
- Subject line reasoning: which option was chosen and why (e.g., "Chose no-show angle over PageSpeed opener — owner feels it daily")
- Delivery blockers: missing email address, preferred contact channel, any platform details to withhold from the subject
- Call prep flags: anything to raise in the discovery call that the email doesn't address (e.g., cash-only deposit flow, commission splits)
- Benchmark hook available: note the strongest comparative stat for use if doing A/B testing

Call `admin-outreach-email` Edge Function with `action: draft`, passing:
- `leadId`, `subject`, `bodyHtml`
- `notes`: the extracted internal notes as a plain-text string (bullet points separated by newlines)

Do NOT send it.

Confirm: "Draft created — review it in the Drafts tab before sending."

---

## Output Summary

After this skill completes:

| File | Contents |
|---|---|
| `blueprint.md` | Full software build plan |
| `brand_brief_report.html` | Pre-filled brand brief (client-facing) |
| `competitor_intel.md` | Raw competitor analysis |
| `competitor_report.html` | Print-ready competitor report |
| `brand_alignment.md` | Brand alignment analysis |
| `brand_alignment_report.html` | Print-ready brand alignment report |
| `custom-plan-draft.md` | Internal plan + pricing recommendation (outreach path only — never sent) |
| `discovery_prefill` on quote | Pre-populated discovery form data |

**Outreach path also:** Draft email in Drafts queue (pending your approval).

## When to Use This Skill

✅ Outreach lead has score ≥ 60 and has NOT been prepared yet
✅ Web client just paid deposit — prepare before discovery form is sent
✅ Industry profile is synced (runs automatically if not)

❌ Don't run if the full report suite already exists in `planning/leads/{client-slug}/`
❌ Don't run on outreach leads below score 60
