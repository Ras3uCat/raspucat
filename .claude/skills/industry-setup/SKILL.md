---
name: industry-setup
description: Runs the complete PHASE 1 industry research pipeline for a new niche in a single command. Chains industry-download → sync + benchmark → ride-along → money-map → client-locator in sequence. Use this skill when the user wants to fully profile a new industry before running lead discovery. Trigger phrases include "industry setup", "set up [industry]", "profile [industry]", "run phase 1 for [industry]", or any request to do the full industry research pipeline from scratch.
---

# Industry Setup

Run the complete PHASE 1 research pipeline for a new industry in one go. All four skills, all
outputs saved, profile synced to Supabase — ready for lead discovery when you're done.

## What This Skill Does

**Input:** An industry name (e.g., "HVAC Contractors", "Auto Shops", "Dental Offices")

**Output:**
- `planning/industries/{slug}.md` — full industry profile
- `planning/industries/{slug}-ride-along.md` — day-in-the-life narrative
- `planning/industries/{slug}-money-map.md` — ranked problems + picked target
- `planning/industries/{slug}-client-locator.md` — prospecting playbook
- Industry profile synced to Supabase (enables Find Leads button for this industry)
- Benchmark stats populated (15 live sites audited, scoring calibrated)

## Steps

Run each step in full before moving to the next. Do not abbreviate any skill output.

---

### STEP 1 — Industry Download

Invoke the `/industry-download` skill for the provided industry name.

Run it exactly as if the user had typed `/industry-download {Industry Name}` — produce the
complete report through all 12 numbered steps with no shortcuts.

At the end of the report, the skill outputs two bash commands (step 12). You will use those
exact command strings in Step 2. Capture the slug, name, painPoints, bookingCtaKeywords,
auditSignals, and researchedAt values from the generated report so they are available for the
sync command.

---

### STEP 2 — Sync + Benchmark

After the Industry Download report is saved, execute the two step 12 commands.

**Tell the user:**
> "Industry profile saved. Running Supabase sync and benchmark now — the benchmark audits 15
> live sites and takes ~60 seconds."

Run both commands directly using the Bash tool (substitute real slug, name, and values from Step 1).
The admin token is stored in project memory — look it up rather than asking the user.

**Sync (includes overviewMd so the Overview tab shows content):**
```bash
OVERVIEW=$(cat planning/industries/{slug}.md | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")
curl -s -X POST https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-leads \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og" \
  --data-raw "{\"adminToken\":\"ADMIN_TOKEN\",\"action\":\"sync-industry\",\"slug\":\"{slug}\",\"name\":\"{Full Name}\",\"painPoints\":[...],\"bookingCtaKeywords\":[...],\"auditSignals\":{...},\"researchedAt\":\"{YYYY-MM-DD}\",\"overviewMd\":$OVERVIEW}"
```

**Benchmark (~60s):**
```bash
curl -s -X POST https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-lead-discovery \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og" \
  -d "{\"adminToken\":\"ADMIN_TOKEN\",\"action\":\"benchmark-industry\",\"slug\":\"{slug}\"}"
```

Wait for the user to confirm both commands ran before continuing to Step 3.

---

### STEP 3 — Ride-Along

Invoke the `/ride-along` skill for the same industry.

Run it exactly as if the user had typed `/ride-along {Industry Name}` — produce the complete
1,200-1,800 word narrative with all four mechanics (chronological timestamps, italicized inner
thoughts, dollar leakage thread, dream system close).

Save output to: `planning/industries/{slug}-ride-along.md`

After saving, sync the narrative to Supabase by outputting this command for the user to run:

```bash
! supabase functions invoke admin-leads --project-ref gegwqywgbgzahnftppda \
  --body '{"adminToken":"YOUR_TOKEN","action":"sync-industry","slug":"{slug}","name":"{Full Name}","rideAlongMd":"<full file content as escaped JSON string>"}'
```

---

### STEP 4 — Money Map

Invoke the `/money-map` skill for the same industry.

Run it exactly as if the user had typed `/money-map {Industry Name}` — produce the complete
ranked problem list with all five filters applied, ending with one clear pick and rationale.

Save output to: `planning/industries/{slug}-money-map.md`

After saving, sync to Supabase:

```bash
! supabase functions invoke admin-leads --project-ref gegwqywgbgzahnftppda \
  --body '{"adminToken":"YOUR_TOKEN","action":"sync-industry","slug":"{slug}","name":"{Full Name}","moneyMapMd":"<full file content as escaped JSON string>"}'
```

---

### STEP 5 — Client Locator

Invoke the `/client-locator` skill for the same industry.

Run it exactly as if the user had typed `/client-locator {Industry Name}` — produce the complete
prospecting playbook with named platforms, member counts, and platform-tailored outreach scripts.

Save output to: `planning/industries/{slug}-client-locator.md`

After saving, sync to Supabase:

```bash
! supabase functions invoke admin-leads --project-ref gegwqywgbgzahnftppda \
  --body '{"adminToken":"YOUR_TOKEN","action":"sync-industry","slug":"{slug}","name":"{Full Name}","clientLocatorMd":"<full file content as escaped JSON string>"}'
```

---

### STEP 6 — Completion Summary

After all five steps are done, output a summary:

```
✓ PHASE 1 COMPLETE — {Industry Name}

Files saved:
  planning/industries/{slug}.md
  planning/industries/{slug}-ride-along.md
  planning/industries/{slug}-money-map.md
  planning/industries/{slug}-client-locator.md

Supabase:
  Profile synced — Find Leads button is now unblocked for this industry
  Benchmark stats populated from 15 live sites
  Ride-along, money map, and client locator narratives stored in Supabase
  All content viewable in Admin Panel → Outreach → Industries tab

Next steps:
  Admin Panel → Outreach → Settings → add "{Industry Name}" to Target Industries
  Then click Find Leads to run discovery
```

---

## Skip Logic

Before running Step 1, check if the profile already exists:

1. Convert the industry to a slug: lowercase, spaces → hyphens, remove special chars.
   Example: "HVAC Contractors" → `hvac-contractors`
2. Run `ls planning/industries/` and look for `{slug}.md`.
3. If found, read the `researched_at` field from its frontmatter.
4. Tell the user: "I found an existing {name} profile from {date}. Re-run the full setup? (y/n)"
5. If they say no, list the existing files and stop.
6. If they say yes, proceed with the full pipeline.

---

## Notes

- Each skill must be run in full — do not summarize or compress output.
- The sync command in Step 2 is what unblocks the Find Leads button in the admin panel. Do not skip it.
- The benchmark takes ~60 seconds — tell the user to wait before moving to Step 3.
- Admin token is not stored in this skill — ask the user if not provided and they haven't run it before.
