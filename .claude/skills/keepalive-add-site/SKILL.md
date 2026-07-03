---
name: keepalive-add-site
description: Registers a Supabase project with the supabase-keepalive Cloudflare Worker so it gets pinged on a daily cron and never auto-pauses on the free tier. Use whenever a new or existing client project's Supabase instance needs to start (or stop) being kept alive. Trigger phrases include "add [project] to keepalive", "keep [project]'s supabase alive", "register a database with the keepalive worker", "stop pinging [project]", or any request to change which Supabase projects the keepalive worker covers.
---

# Keepalive: Add a Site

Adds one Supabase project to the `supabase-keepalive` Cloudflare Worker's KV config
(`cloudflare/supabase-keepalive/`). The Worker's cron fans out to every entry in KV — adding
a site is a KV write, not a redeploy.

## Required Inputs
- **Site name** — short identifier, e.g. `raspucat`, `street_post`
- **Supabase project URL** — `https://<ref>.supabase.co`
- **Supabase anon key** — the public `anon` key (never the `service_role` key)

If any of these are missing, ask the user before proceeding — do not guess a project ref or
reuse another site's key.

## Steps
1. `cd cloudflare/supabase-keepalive`
2. `npm install` (first time only)
3. `./add-site.sh <name> <url> <anon-key>`
4. Confirm the output lists the new site name alongside existing ones.

## Removing a Site
`npx wrangler kv:key delete --binding=SITES_KV <name>`

## Notes
- The anon key is safe to pass on the command line / commit to KV — it's the public key meant
  for client embedding, not the `service_role` key.
- No `wrangler deploy` is needed after adding or removing a site; only the Worker's own code
  changes require a redeploy.
- First-time setup for this Worker (KV namespace creation, initial deploy) is documented in
  `cloudflare/supabase-keepalive/wrangler.toml`.
