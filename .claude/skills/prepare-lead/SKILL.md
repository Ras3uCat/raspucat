---
name: prepare-lead
description: Prepares a complete client intelligence package for any qualified lead or new web client. Pulls the record automatically via Supabase MCP, runs a 7-step flow (site audit → industry research → blueprint → brand brief → competitor intel → brand alignment → discovery pre-population), then creates a draft outreach email for outreach leads. Works on both acquisition paths. Trigger phrases include "prepare lead", "prepare [company name]", "build the research package", "prepare client [name]", "run prepare-lead", or any request to generate the intelligence package for a lead or new client.
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
6. Draft outreach email in the Drafts queue (NOT sent — requires your approval)

---

## Step 1 — Enhanced Website Audit

If a `business_website` URL is available, run a full site audit. Extract:

**Platform detection:** Check for Wix, Squarespace, Weebly, Shopify, WordPress indicators in meta tags, script src URLs, or CSS class patterns.

**PageSpeed score:** Use the PageSpeed Insights API (or estimate from known hosting platform) if available.

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

If the industry IS already profiled: load it and continue.

If the industry is NOT yet profiled:
1. Run `/industry-download` for the industry
2. Run `/ride-along` for the industry
3. Run `/money-map` for the industry
4. Run `/client-locator` for the industry
5. Sync the profile to Supabase `industry_profiles`
6. Save industry files to `planning/industries/{slug}.md`

---

## Step 3 — Blueprint Builder

Using the confirmed pain points from the audit + the industry profile:

- Only include features that address pain points **confirmed by the site audit**. Do not invent problems.
- If no booking CTA: booking automation is the core feature
- If slow PageSpeed / DIY platform: rebuild + performance is the project
- If missing contact/phone: lead capture is the core feature

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

## Step 7 — Write discovery_prefill to Quote

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

**Outreach path only:** After Step 7, proceed to Step 8 (draft email). Skip Step 8 for web path.

---

## Step 8 — Draft Outreach Email (Outreach Path Only)

Write a personalized cold outreach email. Rules:

**Subject line:**
- `[Company name] — [specific finding]` (e.g., "McCullough Heating — 38 on mobile")
- Or a question about a specific problem visible on their site

**Opening line:** Reference one specific thing found on their site. Never open with a compliment or a generic claim.

**Body (3–4 sentences max):**
- What the problem is costing them (Money Map number)
- What you built to solve it (1 sentence from the blueprint)
- What the outcome looks like

**CTA:** "Book a 15-minute call" — link to `{SITE_URL}/book`

Call `admin-outreach-email` Edge Function with `action: draft` to save it to the Drafts queue. Do NOT send it.

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
| `discovery_prefill` on quote | Pre-populated discovery form data |

**Outreach path also:** Draft email in Drafts queue (pending your approval).

## When to Use This Skill

✅ Outreach lead has score ≥ 60 and has NOT been prepared yet
✅ Web client just paid deposit — prepare before discovery form is sent
✅ Industry profile is synced (runs automatically if not)

❌ Don't run if the full report suite already exists in `planning/leads/{client-slug}/`
❌ Don't run on outreach leads below score 60
