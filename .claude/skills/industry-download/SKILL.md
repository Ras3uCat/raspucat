---
name: industry-download
description: Downloads an entire industry into your brain in 30 seconds. Use this skill when the user names a niche or industry and wants to become an instant expert — covers pain points, language, where they hang out, what they pay for, and the perfect software solution to sell them. Trigger phrases include "industry download", "get me up to speed on [industry]", "download the [niche] industry", "make me an expert on [industry]", or any request to research a specific niche before outreach, discovery calls, or building software.
---

# Industry Download

Become an instant insider. Download an entire industry into your brain in 30 seconds so you can sound credible on your first call, ask the right questions, and know exactly what software to build.

## What This Skill Does

**Input:** Any niche or industry (auto shops, dental offices, HVAC contractors, fire inspectors, real estate teams, etc.)

**Output:** Complete operator-level intelligence — what they do all day, what they hate, what they pay for, what they say, and the exact gap in the market you can fill.

You go from outsider to insider before you ever pick up the phone.

## Why This Skill Exists

The #1 thing that kills first calls is sounding like an outsider. Saying "client" instead of "customer." Saying "scheduling system" instead of "DVI flow." One wrong term and the business owner mentally checks out.

This skill fixes that in one prompt. It pulls real language from real forums, real subreddits, real industry communities — and hands you the operator's vocabulary, frustrations, and dream outcomes.

## How to Use This Skill

When the user activates this skill with an industry, do the following:

0. **Check for an existing profile.** Before doing any research:
   - Convert the industry name to a slug: lowercase, spaces to hyphens, remove special chars.
     Example: "HVAC Contractors" → `hvac-contractors`
   - Run: `ls planning/industries/` and check if `{slug}.md` exists.
   - If it exists, read the `researched_at` field from its YAML frontmatter.
   - Tell the user: "I found an existing {name} profile from {date}. Refresh it? (y/n)"
   - If they say no, display the file content and stop.

1. **Confirm the industry is specific enough.** "Small businesses" is too broad. "Auto shops with 3-15 bays" is good. Push back if it's too vague.
2. **Run web research.** Search Reddit, Facebook groups, industry forums, trade publications, and YouTube to gather real language and pain points. Do not invent generic answers — pull from real sources.
3. **Output the full report in the exact structure below.** Do not skip sections. Each one matters.

## Output Structure

Deliver the report in this exact order. Use markdown headers. Be specific — vague answers are useless.

### 1. Industry Overview
- Number of businesses in the US (approximate)
- Average annual revenue per business
- Average employee count
- Recession-proof? (yes/no/sort-of)
- 2026 reality check: what's actually happening in this industry right now

### 2. Where They Hang Out Online
List specific places with names, links where possible, and active member counts.

- **Subreddits** (with subscriber count)
- **Facebook Groups** (with member count)
- **Industry forums** (specific URLs)
- **LinkedIn Groups**
- **YouTube channels they watch**
- **Podcasts they listen to**
- **Annual conferences** (with dates and locations)
- **Trade publications** (specific names)

### 3. Pain Points Ranked by Money Lost
Rank the top 10 pain points by how much money or time they cost. Each entry must include:
- The pain in their language
- What it actually costs them per month or per year
- Why existing solutions don't fix it

### 4. Language Dictionary
This is the most important section. Pull directly from forums and Reddit.

- **Industry terms** they use daily (with definitions)
- **Acronyms** specific to the field
- **Pain phrases** — verbatim things they say when frustrated
- **Success phrases** — verbatim things they say when winning
- **Outsider red flags** — terms that mark you as not one of them, with the correct alternative

### 5. What They Already Pay For
List the existing software, services, and vendors this industry already pays for. Include:
- Specific company names
- Approximate monthly cost
- What problem each one solves (or fails to solve)

This section kills the "but would they pay for this?" objection in one glance.

### 6. What Keeps Them Up at Night
Top 5 fears, ranked. Use their language, not corporate language.

### 7. Dream Outcome
What does a perfect day look like for them? What would they pay $10K to make true?

### 8. Market Gaps
Specific software, features, integrations, or services that don't exist yet — or exist but suck. This is where your opportunity lives.

### 9. The Perfect Software Solution
Based on everything above, recommend:
- **The core problem to solve first** (the painful, expensive one)
- **MVP feature list** (3-5 features max)
- **Phase 2 features** (what to add later)
- **Pricing recommendation** (with ROI math justifying it)
- **Positioning angle** (one sentence: "The only X built specifically for Y")

### 10. Go-to-Market Cheat Sheet
- **Where to find them** (specific platforms with links)
- **Opening message template** (using their language)
- **Expected objections and responses** (3-5 of them)
- **Proof they need to see** before they'll pay

## After Generating the Report

**11. Save to disk.** Write the full report to `planning/industries/{slug}.md` using this exact
frontmatter block at the top (before any markdown content). Derive the values from the report.
Include `email_subject_template` and `email_body_template` — generate them as part of this step
using the research data (language from Section 4, top pain point from Section 3 #1).

```
---
slug: {slug}
name: {Full Industry Name}
researched_at: {YYYY-MM-DD}
pain_points:
  - no_booking_cta       # include if booking/scheduling is a documented pain point
  - poor_mobile          # include if mobile experience is documented as lacking
  - diy_platform         # include if DIY website builders are common in this industry
  - slow_site            # include if site performance is a documented issue
  - no_ssl               # include if security/trust signals are lacking
  # Add industry-specific slugs for any pain points unique to this niche
  # Slug format: lowercase_with_underscores, max 30 chars
booking_cta_keywords:
  - schedule
  - book
  - appointment
  - quote
  - estimate
  # Add industry-specific scheduling verbs found in Section 4 Language Dictionary
audit_signals:
  seo_keywords:
    - []  # 3–5 terms that should appear on any legitimate site in this industry
  red_flags:
    - []  # HTML/content patterns that indicate website neglect in this industry
email_subject_template: "Quick question about {COMPANY}'s website"
email_body_template: |
  Hi {FIRST_NAME},

  We are Cytarah and Ryan, co-owners of Raspucat. We build custom websites that combine modern
  design and smart functionality, tailored specifically to the businesses behind them.

  [Industry-specific 2-sentence connection using verbatim language from Section 4 + personal angle]

  [1-2 sentence pain point using the top item from Section 3, in their language]

  We've already put together a complimentary research package for your business containing a
  brand brief, competitor analysis, and brand alignment review tailored to {COMPANY}.

  If interested, we'd love to walk you through what we found. You can simply reply to this
  email, or book a free Website Audit & Strategy Session here:
  {BOOKING_LINK}

  You can also explore a live demo of what we build, the full experience and admin pages included:
  {DEMO_LINK}
---
```

The `[bracketed]` sections in `email_body_template` must be replaced with real content from
the report — they are not literal text. The placeholders `{FIRST_NAME}`, `{COMPANY}`,
`{BOOKING_LINK}`, `{DEMO_LINK}` must remain as-is; they are substituted at send time.

**12. After saving, show these two commands** (paste both in sequence). The first syncs the
full profile (including the email template) to Supabase; the second samples 15 real websites
and stores benchmark stats. Replace `YOUR_TOKEN` with the admin token.

```bash
! supabase functions invoke admin-leads --project-ref gegwqywgbgzahnftppda \
  --body '{"adminToken":"YOUR_TOKEN","action":"sync-industry","slug":"{slug}","name":"{Full Name}","painPoints":[{pain_points as JSON array}],"bookingCtaKeywords":[{keywords as JSON array}],"auditSignals":{audit_signals as JSON object},"researchedAt":"{YYYY-MM-DD}","emailSubjectTemplate":"{email_subject_template}","emailBodyTemplate":"{email_body_template as escaped JSON string}"}'

! curl -s -X POST https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-lead-discovery \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og" \
  -d '{"adminToken":"YOUR_TOKEN","action":"benchmark-industry","slug":"{slug}"}'
```

The benchmark command takes ~60 seconds (auditing 15 live sites with PageSpeed). Once it
completes, the industry profile in the admin settings panel will show the benchmark stats and all
future lead scores for this industry will be compared against the industry average.

---

## Pro Tips for Better Output

- **Use real quotes from real forums.** If you find a Reddit post where someone says "I'm drowning in paperwork," put it in the Language Dictionary verbatim.
- **Quantify everything.** "Loses money" is useless. "Loses $5K-$15K per month" is gold.
- **Skip generic SaaS advice.** This is for finding niche, boring, profitable opportunities — not building the next ChatGPT.
- **Look for complaint threads.** Reddit posts titled "Why does X suck?" or "What do you hate about your job?" are pain-point goldmines.

## When to Use This Skill

✅ Before any cold outreach to a new industry
✅ Before any discovery call
✅ Before deciding what software to build
✅ Before pricing a project
✅ Anytime you're entering an industry you've never worked in

❌ Don't use for industries you already know cold
❌ Don't use for super broad markets ("small businesses" is not an industry)

## Remember

You're not trying to become a 20-year veteran of this industry. You're trying to sound like someone who's been around it long enough to ask the right questions and propose the right solution.

This skill gets you 80% of the way there. Real conversations get you the last 20%.

**Outsider to insider. 30 seconds. Then you make the call.**
