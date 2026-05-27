# Outreach Playbook — Start to Finish

## Overview

This system takes you from zero knowledge of an industry to a prepared, high-confidence
presentation on the first client call. The discovery call is not a fact-finding mission —
it is a confirmation call. You already have their pain points, their site audit, a blueprint
of what you're building, and a closer deck with pre-filled numbers before you ever pick up
the phone.

---

## Phase 1 — Industry Research (Once Per Industry)

Run these four skills once. They don't change. Save the outputs and never run them again
for the same industry.

### Step 1 — Industry Download

```
/industry-download HVAC Contractors
```

Outputs: pain points, operator language, what they pay for, booking CTA keywords, audit signals.

At the end of the skill, step 12 outputs two commands. Run both:

```bash
# Sync profile to Supabase (fast)
! supabase functions invoke admin-leads --project-ref gegwqywgbgzahnftppda \
  --body '{"adminToken":"YOUR_TOKEN","action":"sync-industry","slug":"hvac-contractors",...}'

# Benchmark 15 real sites in this industry (~60s)
! curl -X POST https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-lead-discovery \
  -H "Authorization: Bearer ANON_KEY" \
  -d '{"adminToken":"YOUR_TOKEN","action":"benchmark-industry","slug":"hvac-contractors"}'
```

Saves to: `planning/industries/hvac-contractors.md`

---

### Step 2 — Ride-Along

```
/ride-along HVAC Contractors
```

Outputs: 1,200–1,800 word first-person day-in-the-life narrative. Timestamps, internal
monologue, dollar leakage, the dream system. This is where you get the language — the
exact phrases owners use, the moments where money leaks, the emotional texture of their day.

Run step 12 sync command when the skill finishes.

Saves to: `planning/industries/hvac-contractors-ride-along.md`

---

### Step 3 — Money Map

```
/money-map HVAC Contractors
```

Stack this on steps 1 and 2. Filters everything through one lens: what is painful,
expensive, Claude-buildable, and charges recurring revenue?

Output: one specific problem worth attacking with a quantified dollar figure.
Example: "HVAC companies lose $3K–$8K/month in missed after-hours booking requests."

This number becomes your pitch thesis for everything that follows.

Saves to: `planning/industries/hvac-contractors-money-map.md`

---

### Step 4 — Client Locator

```
/client-locator HVAC Contractors
```

Outputs: top 5 platforms where HVAC owners hang out (Facebook groups with member counts,
subreddits, forums, LinkedIn groups), platform-specific outreach scripts, and a 7-day
action plan for warm outreach.

Use this alongside the automated pipeline for warm outreach — DM prospects before the
email sequence touches them.

Saves to: `planning/industries/hvac-contractors-client-locator.md`

---

## Phase 2 — Configure & Discover

### Step 5 — Configure Targeting

Admin panel → Settings tab:
- Add target industry: `HVAC contractors`
- Add target city: `Austin, TX`
- Set discovery frequency: 2x/week
- Save

The industry profile synced in step 1 will appear in the settings panel with benchmark
chips (avg PageSpeed, % on DIY platforms, % have booking CTA). Any target industry
without a synced profile shows an amber warning — that is your signal to run
Industry Download first.

---

### Step 6 — Run Discovery

Admin panel → **Find Leads** button.

What runs automatically:
1. Google Places pulls up to 20 businesses per industry/city pair
2. Angi scrapes the same city for additional leads
3. Every site is audited: platform (Wix/WordPress/custom), PageSpeed vs. industry
   benchmark, viewport meta, booking CTA presence
4. Pain points matched against the industry profile's `pain_points[]`
5. High-score leads (≥ 60) get Apollo org enrichment (tech stack confirmation,
   DIY platform detection)
6. Hunter.io looks up decision maker name + title by domain

When it finishes, the pipeline fills with scored, source-badged, pain-point-labeled leads.

Cron runs automatically Mon + Thu at 9am. The "Find Leads" button triggers a manual run.

---

### Step 7 — Prioritize the Pipeline

Pipeline view → sort by score descending.

Prioritize leads with:
- Score ≥ 60 with 2+ pain point tags (Slow site, No booking, Wix/DIY)
- Decision maker name populated (Hunter found them)
- Multi-source badges (G + A) — seen on both Google and Angi

Click into any lead to see: full website audit, decision maker name/title, all pain
points matched, notes field.

---

## Phase 3 — Prepare the Research Package

**Trigger:** Lead has score ≥ 60 and has not been prepared yet.

This is run manually (or via the "Prepare" button on the lead row). With the Supabase MCP
wired into Claude Code, just say:

```
Prepare a blueprint for McCullough Heating & Air
```

Claude will query the lead's audit data and industry profile automatically, then run
through the blueprint builder.

### Step 8 — Blueprint Builder

```
/blueprint-builder
```

Context fed automatically (via MCP): lead's website audit, pain points, industry profile,
benchmark stats, decision maker info, Money Map findings, Ride-Along narrative.

Output: complete software build plan — features, scope, data model, architecture.
This is the spine. Everything else (email, discovery script, closer deck) derives from it.

Saves to: `planning/leads/{lead-id}/blueprint.md`

---

### Step 9 — Send the First Email

The email is written from the blueprint. It surfaces one specific pain point confirmed
by the website audit — not a generic industry problem, but something visible on their
actual site.

Example opening: "We noticed your site is built on Wix and scores 38 on mobile — the
average HVAC site in Austin scores 47. Most of your competitors have the same problem,
which is exactly why there's an opening."

Lead status → `contacted`. Automated follow-ups send at the configured interval
(default: 3 days, 2 max) until they reply.

---

## Phase 4 — When They Reply

**Trigger:** Lead status changes to `replied`.

Their response is data. What they focus on, what they ask, the numbers they volunteer,
their tone — all of this makes the discovery script and closer deck more targeted than
any pre-built version could be.

With MCP wired, say:

```
McCullough replied — prepare the discovery script and closer deck.
Here's their response: [paste their reply]
```

Claude pulls their full record automatically and adds their reply as additional context.

---

### Step 10 — Discovery Script

```
/discovery-script
```

Context: industry research + lead audit + their actual email response.

Output: 8–12 questions tailored to this specific lead. Questions that deepen the pain
points already confirmed on their site and follow the thread of what they said in
their reply.

Saves to: `planning/leads/{lead-id}/discovery-script.md`

---

### Step 11 — Closer Deck

```
/closer-deck
```

Context: blueprint + industry benchmark + lead audit + their email response.

Output: 6-slide deck built from what you already know about their business, with
industry averages pre-filled as placeholders for any numbers not yet confirmed.

- Slide 1: Their specific situation (mirrors the pain points back)
- Slide 2: Cost of the problem (quantified from Money Map + their industry)
- Slide 3: The solution (from the blueprint)
- Slide 4: How it works
- Slide 5: Investment
- Slide 6: Next step

Saves to: `planning/leads/{lead-id}/closer-deck.md`

---

## Phase 5 — The Confirmation Call

This is not a discovery call. You already did the discovery. This is a presentation call
where you confirm your numbers, build rapport, and close.

You arrive with:
- Their name and title (Hunter)
- Their site's specific pain points (website audit)
- How they compare to their peers (industry benchmark)
- A blueprint of what you are building for them
- A closer deck with pre-filled numbers from their industry
- Questions from the discovery script to confirm assumptions

**How to open:** "We found your site scores 38 on mobile and has no booking CTA. Based
on typical HVAC volume in Austin, we estimated you're losing around $4K/month. Does
that feel close?"

They confirm or correct the number. You update the deck in real time. You present
the solution and close on the first call.

---

## Phase 6 — Track + Follow Through

Update lead status in the pipeline as the relationship progresses:

| Status | Meaning |
|---|---|
| `prospect` | Discovered, not yet contacted |
| `contacted` | First email sent |
| `replied` | They responded — trigger research package |
| `call_booked` | Confirmation call scheduled |
| `proposal_sent` | Deck sent or presented |
| `closed_won` | Signed |
| `closed_lost` | Passed |

---

## The Full Loop at a Glance

```
ONCE PER INDUSTRY
/industry-download  → sync → benchmark
/ride-along         → save md
/money-map          → save md
/client-locator     → save md

CONFIGURE
Admin Settings → target industry + city → Save

AUTOMATED (cron Mon/Thu or manual "Find Leads")
Google Places + Angi → website audit → Apollo → Hunter → scored pipeline

MANUAL (score ≥ 60, not yet prepared)
/blueprint-builder  → save md → send email → mark contacted

ON REPLY
/discovery-script + /closer-deck → built from reply context → save md

CONFIRMATION CALL
Present deck → confirm numbers → close

PIPELINE
prospect → contacted → replied → call_booked → proposal_sent → closed_won
```

---

## Skill Quick Reference

| Skill | When | Frequency |
|---|---|---|
| `/industry-download` | New industry | Once |
| `/ride-along` | After industry download | Once |
| `/money-map` | After ride-along | Once |
| `/client-locator` | After industry setup | Once |
| `/blueprint-builder` | Score ≥ 60, pre-email | Per qualified lead |
| `/discovery-script` | After lead replies | Per reply |
| `/closer-deck` | After lead replies | Per reply |

---

## Notes

- Industry research files live in `planning/industries/`
- Per-lead research files live in `planning/leads/{lead-id}/`
- The Supabase MCP server (configured in `~/.claude/settings.json`) gives Claude Code
  direct read access to leads and industry profiles — no copy-paste required when
  invoking skills
- Blueprint is the spine: email, discovery script, and closer deck all derive from it
- Never run discovery-script or closer-deck before the lead replies — their response
  adds context that makes both sharper
