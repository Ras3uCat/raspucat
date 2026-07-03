# 043 — Supabase Keep-Alive — Prevent Free-Tier Auto-Pause

**Skill:** `backend-dev`
**Depends on:** Nothing — implemented as a Cloudflare Worker in this repo, alongside the existing `raspucat-email-worker` (`cloudflare/email-worker/`)

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

**Deployed:** `https://supabase-keepalive.skyjumper32.workers.dev`, cron `0 8 * * *` daily.
KV namespace `SITES_KV` (id `c4b7f2b315564476ae770e2a7c96c047`) contains `raspucat` and `street_post`.
`street_post/.github/workflows/supabase-keep-alive.yml` deleted (uncommitted in that repo — user to commit there).

**Deviation from original design:** pinging bare `/rest/v1/` with the anon key 401s on both
projects — that root path requires the `service_role`/secret key, not anon. Switched to
`GET {url}/auth/v1/health` with the anon key, confirmed 200 on both raspucat and street_post
before deploying.

## Overview
Every client project uses its own Supabase account on the Free tier, which auto-pauses after 7 days with no API activity. This already caused a real outage on 2026-07-03 — the demo site loaded, but the Supabase project hostname returned NXDOMAIN because it had paused.

This item was originally drafted under `template_1` as a per-project GitHub Actions cron job, but that approach doesn't scale and depends on the client project's own account/CI. Moved here to **raspucat** because raspucat is the master site and already owns the shared Cloudflare account used for Pages hosting and the email worker — this keepalive job belongs at the account level, not duplicated per client project.

Longer-term this should cover every site on the account with the same free-tier-pause risk (~15-20 sites total exist across `flutter_apps/`), but the exact list hasn't been confirmed yet — several projects have ambiguous/duplicate Supabase refs (e.g. the "red dot" family) or only exist as shelved `.zip` archives. **Scope for this pass is deliberately limited to the 2 confirmed live projects: `raspucat` and `street_post`.** Add the rest later, one config entry at a time, once each project's current live ref is confirmed with the user.

Cloudflare's Free plan allows only **5 Cron Triggers per account** (confirmed via [Cloudflare Workers limits docs](https://developers.cloudflare.com/workers/platform/limits/)) — not per Worker — so the design must still be **one Worker, one Cron Trigger, fanning out to a config list of Supabase projects** in a single `scheduled()` invocation, so growing the list later never costs another Cron Trigger.

`street_post` already has its own working keepalive at `street_post/.github/workflows/supabase-keep-alive.yml` (daily GitHub Actions cron pinging `euexfcedohjawgntsska.supabase.co`). That workflow should be **retired and folded into this Worker** once the Worker is live, so there's one system to maintain instead of two.

**Implementation location:** `cloudflare/supabase-keepalive/`, following the same structure as the existing `cloudflare/email-worker/` (`wrangler.toml` + `src/index.ts`).

## Acceptance Criteria
- [x] Single Worker (`supabase-keepalive`) with **one** Cron Trigger in `wrangler.toml` (`[triggers] crons = ["0 8 * * *"]`).
- [x] `scheduled()` handler loops over a config list of `{ name, url, anonKey }` entries and sends a lightweight `GET {url}/auth/v1/health` request with the `apikey` header for each. No write operations.
- [x] Initial config list contains exactly 2 entries:
  - `raspucat` — `gegwqywgbgzahnftppda` (`https://gegwqywgbgzahnftppda.supabase.co`)
  - `street_post` — `euexfcedohjawgntsska` (`https://euexfcedohjawgntsska.supabase.co`)
- [x] Config list stored in Cloudflare KV (`SITES_KV`) — not hardcoded per-site logic, so adding a new confirmed site later is a one-line `add-site.sh` call, not a new deploy.
- [x] Per-site failures (non-2xx) are logged individually via `console.error` (visible in `wrangler tail`) so one dead project doesn't mask failures in the rest.
- [x] `street_post/.github/workflows/supabase-keep-alive.yml` deleted now that the new Worker is confirmed working.
- [x] Stays well within Free plan limits: 1 of 5 account-wide Cron Triggers used, request volume negligible against the 100,000 requests/day cap.
- [x] Confirmed the ping succeeds (200) on both projects with the anon key — full confirmation that this resets Supabase's inactivity clock still pending observation over the next 7+ days.
- [x] Deployed via `wrangler deploy` using the already-authenticated CLI session (account `skyjumper32@gmail.com`, account ID `61ee775758122837364be8b5f7cdb563`) — no GitHub Actions involved for raspucat/street_post going forward.

## Follow-up
- [ ] Watch that raspucat/street_post's Supabase projects don't auto-pause over the next 1-2 weeks to confirm `/auth/v1/health` pings actually reset the inactivity clock.
- [ ] Use the `keepalive-add-site` skill to register more of the ~15-20 other sites once each one's live Supabase ref is confirmed (several have ambiguous/duplicate refs today — see Overview).
