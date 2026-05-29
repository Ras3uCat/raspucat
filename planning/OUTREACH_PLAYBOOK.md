# Outreach Playbook — Start to Finish

## Overview

This system takes you from zero knowledge of an industry to a prepared, high-confidence
presentation on the first client call. The discovery call is not a fact-finding mission —
it is a confirmation call. You already have their pain points, their site audit, a blueprint
of what you're building, and a closer deck with pre-filled numbers before you ever pick up
the phone.

**Outreach email:** `hello@raspucat.com` — all outreach sends from here, all replies capture automatically.

---

## Phase 1 — Industry Research (Once Per Industry)

Run these four skills once. They don't change. Save the outputs and never run them again
for the same industry.

### Step 1 — Industry Download

```
/industry-download HVAC Contractors
```

Outputs: pain points, operator language, what they pay for, booking CTA keywords, audit signals.

At the end of the skill, step 12 outputs a sync command. Run it to push the profile to Supabase:

```bash
# Sync profile to Supabase (fast)
! supabase functions invoke admin-leads --project-ref gegwqywgbgzahnftppda \
  --body '{"adminToken":"YOUR_TOKEN","action":"sync-industry","slug":"hvac-contractors",...}'
```

Then run the benchmark separately (hits real sites — takes ~60s):

```bash
! curl -X POST https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-lead-discovery \
  -H "Content-Type: application/json" \
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

This is a standalone skill — no sync command needed after it runs.

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
- Set discovery frequency: 2x/week (set to 0 to pause the cron)
- Save

The industry profile synced in step 1 will appear in the settings panel with benchmark
chips (avg PageSpeed, % on DIY platforms, % have booking CTA). Any target industry
without a synced profile shows an amber warning — that is your signal to run
Industry Download first.

---

### Step 6 — Run Discovery

Admin panel → **Find Leads** button (manual run), or let the daily cron handle it.

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

**Cron schedule:** Supabase pg_cron runs both jobs daily at 10AM UTC — no external
orchestration needed. Frequency is controlled by the `Discovery runs/week` setting in
the admin panel. **Set to 0 to pause.** When paused, the cron fires but the discovery
function returns immediately without making any API calls.

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

```
/prepare-lead
```

Claude queries the lead's audit data and industry profile via MCP automatically, runs
the blueprint builder, then creates a draft email in the Drafts queue.

### Step 8 — Blueprint Builder (runs inside `/prepare-lead`)

Context fed automatically (via MCP): lead's website audit, pain points, industry profile,
benchmark stats, decision maker info, Money Map findings, Ride-Along narrative.

Output: complete software build plan — features, scope, data model, architecture.
This is the spine. Everything else (email, discovery script, closer deck) derives from it.

Saves to: `planning/leads/{client-slug}/blueprint.md`

---

### Step 9 — Review and Send the First Email

After `/prepare-lead` completes, a draft email is created automatically in the Drafts tab.
The email surfaces one specific pain point confirmed by the website audit — not a generic
industry problem, but something visible on their actual site.

The email CTA links to `https://raspucat.com/book?leadId={id}` — when the prospect
books a slot, their lead status auto-updates to `call_booked`.

Example opening: "We noticed your site is built on Wix and scores 38 on mobile — the
average HVAC site in Austin scores 47. Most of your competitors have the same problem,
which is exactly why there's an opening."

**Review the draft. Once approved, hit Send.** Resend delivers it and lead status flips
to `contacted`.

**Automated follow-up drafts:** The daily cron checks for leads in `contacted` status
where `next_followup_at` has passed and creates a new draft for each. These drafts appear
in the Drafts tab for you to review and edit. **Nothing sends automatically** — you approve
each follow-up before it goes out.

---

## Phase 4 — When They Reply

**Trigger:** Lead status changes to `replied`.

Their response is data. What they focus on, what they ask, the numbers they volunteer,
their tone — all of this makes the discovery script and closer deck more targeted than
any pre-built version could be.

The reply body is captured automatically (Cloudflare Email Worker → Supabase). Just run:

```
/prepare-reply
```

Claude pulls their full record and reply body via MCP automatically — no copy-paste.

---

### Step 10 — Discovery Script (runs inside `/prepare-reply`)

Context: industry research + lead audit + their actual email response (auto-pulled).

Output: 8–12 questions tailored to this specific lead. Questions that deepen the pain
points already confirmed on their site and follow the thread of what they said in
their reply.

Saves to: `planning/leads/{client-slug}/discovery-script.md`

---

### Step 11 — Closer Deck + Proposal (runs inside `/prepare-reply`)

Context: blueprint + industry benchmark + lead audit + their email response (auto-pulled).

**Closer Deck** output: 6-slide deck built from what you already know about their business,
with industry averages pre-filled as placeholders for any numbers not yet confirmed.

- Slide 1: Their specific situation (mirrors the pain points back)
- Slide 2: Cost of the problem (quantified from Money Map + their industry)
- Slide 3: The solution (from the blueprint)
- Slide 4: How it works
- Slide 5: Investment (real numbers from custom-plan.md)
- Slide 6: Next step

Saves to: `planning/leads/{client-slug}/closer-deck.md`

**Module + Pricing Recommendation** output: recommended plan, which modules solve their
specific pain points, individual module costs, total setup + monthly price.

Saves to: `planning/leads/{client-slug}/custom-plan.md`

**Full Written Proposal** output: scope of work, timeline, deliverables, investment
summary, next step / signature CTA. Print-ready HTML.

Saves to: `planning/leads/{client-slug}/proposal.html`

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
| `call_booked` | Auto-set when prospect books via the `/book` link in the outreach email |
| `proposal_sent` | Deck sent or presented |
| `closed_won` | Signed |
| `closed_lost` | Passed (set manually) |
| `bounced` | Auto-set by Resend webhook — hard bounce, do not re-contact |
| `unsubscribed` | Auto-set when prospect clicks the unsubscribe link in the email |

---

## The Full Loop at a Glance

```
ONCE PER INDUSTRY
/industry-download  → sync → benchmark (separate curl call)
/ride-along         → save md (no sync needed)
/money-map          → save md
/client-locator     → save md

CONFIGURE
Admin Settings → target industry + city → Save

AUTOMATED (daily cron at 10AM UTC, or manual "Find Leads")
Google Places + Angi → website audit → Apollo → Hunter → scored pipeline
discovery_runs_per_week = 0 → cron fires but discovery skips

MANUAL (score ≥ 60, not yet prepared)
/prepare-lead  → blueprint saved → auto-draft created → review draft → send → contacted

AUTOMATED FOLLOW-UPS
Daily cron checks next_followup_at → creates draft → appears in Drafts tab → admin approves → send

ON REPLY
/prepare-reply → discovery-script + closer-deck + custom-plan + proposal.html (reply auto-pulled)
Closer deck is ready to present. Industry benchmarks fill Slide 2 + 5 as starting numbers.

CONFIRMATION CALL
Open closer-deck.md → present → update numbers live as prospect confirms/corrects them → close

POST-CALL (optional — regenerate with full call notes for a polished send-away)
/discovery-script  → sharper questions if a follow-up call is needed
/closer-deck       → clean final version with confirmed numbers, ready to email

PIPELINE
prospect → contacted → replied → call_booked → proposal_sent → closed_won
```

---

## Skill Quick Reference

### Phase 1 — Industry Research

| Skill | When | Frequency | Requires |
|---|---|---|---|
| `/industry-download` | New industry | Once | Industry name |
| `/ride-along` | After industry download | Once | Industry name |
| `/money-map` | After ride-along | Once | Industry name |
| `/client-locator` | After industry setup | Once | Industry name |

### Phase 3 — Lead Preparation

| Skill | When | Requires |
|---|---|---|
| `/prepare-lead` | Score ≥ 60, not yet prepared | Lead in pipeline (pulled via MCP) |
| `/blueprint-builder` | Standalone: when you have a call transcript and want a full build plan | Discovery call transcript or notes |

### Phase 4 — After Reply / Call Prep

| Skill | When | Requires |
|---|---|---|
| `/prepare-reply` | After lead replies | Lead record + reply body (auto-pulled via Cloudflare → Supabase) |
| `/discovery-script` | Standalone: when `call_booked` and you want to go deeper than the auto-generated version | Industry + company info (admin panel "Copy Discovery Script Prompt" fills this in) |
| `/closer-deck` | Standalone: after the call to produce a polished final version with confirmed numbers | Call notes + company context (admin panel "Copy Closer Deck Prompt" fills in company context) |
| `/seo-strategy` | When a client needs SEO — either full site audit or per-service optimization | Client site or service info |

---

## Notes

- Industry research files live in `planning/industries/`
- Per-lead research files live in `planning/leads/{client-slug}/`
- The Supabase MCP server (configured in `~/.claude/settings.json`) gives Claude Code
  direct read access to leads and industry profiles — no copy-paste required when
  invoking skills
- Blueprint is the spine: email, discovery script, and closer deck all derive from it
- Never run `/prepare-reply` before the lead replies — their response adds context that
  makes the discovery script and closer deck sharper
- **Admin panel skill shortcuts:** At `call_booked` status, the lead detail panel shows
  a "Copy Discovery Script Prompt" button — copies a pre-filled `/discovery-script`
  invocation to your clipboard, ready to paste in Claude. At `proposal_sent`, "Copy
  Closer Deck Prompt" does the same for `/closer-deck` (paste in your call notes to
  produce a clean final version with confirmed numbers for the send-away).
- **Closer deck timing:** `/prepare-reply` generates the deck immediately from the email
  reply — industry benchmarks fill the placeholder numbers. You present this on the
  confirmation call and update the numbers live as the prospect confirms them. The
  standalone `/closer-deck` is for producing a polished final version after the call
  with the real numbers locked in.
- **Bounced leads:** Hard bounces auto-set status to `bounced` via Resend webhook.
  Exclude bounced leads from re-discovery runs — the email address is invalid.
- **Unsubscribed leads:** When a prospect clicks the unsubscribe link in any outreach
  email, a dedicated Edge Function (`public-unsubscribe`) sets their status to
  `unsubscribed` immediately. No manual action needed.
- **`call_booked` automation:** When a prospect clicks the booking CTA in the outreach
  email (`/book?leadId={id}`) and completes a booking, `create-booking` automatically
  updates their lead status to `call_booked`.
- **Re-benchmark cadence:** Re-run `/industry-download` + benchmark sync every 90 days,
  or any time you add a new city. Stale benchmarks weaken the opening line.

---

## Live Infrastructure

| Component | Detail |
|---|---|
| Outreach sender | `hello@raspucat.com` |
| Reply forward | `ras3ucat@gmail.com` |
| CF Email Worker | `raspucat-email-worker` (deployed 2026-05-27) |
| Worker URL | `raspucat-email-worker.skyjumper32.workers.dev` |
| CF routing rule | `hello@raspucat.com` → `raspucat-email-worker` (rule `245256d5e28d454ab45e42c0f963a2f3`) |
| Inbound Edge Function | `inbound-outreach-reply` (Supabase `gegwqywgbgzahnftppda`) |
| Reply capture columns | `outreach_emails.reply_body`, `.reply_html`, `.reply_from` |
| Supabase project | `gegwqywgbgzahnftppda` |
| Outreach cron | Supabase pg_cron — daily 10AM UTC (migration `20260528120000_add_outreach_cron.sql`) |
| Cron auth | `CRON_SECRET` env var on `admin-lead-discovery`; `ADMIN_PASSWORD` for follow-up drafts |

**Reply capture flow:**
```
Prospect replies to hello@raspucat.com
  → Cloudflare Email Worker parses raw email (postal-mime)
  → Forwards to ras3ucat@gmail.com (personal inbox, always delivered)
  → POSTs body to inbound-outreach-reply Edge Function
  → Writes reply_body to outreach_emails, flips lead status to replied
  → /prepare-reply pulls body via MCP — zero copy-paste
```
