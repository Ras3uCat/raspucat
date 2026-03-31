Scaffold a new client delivery project: $ARGUMENTS

**Context:** This command orchestrates the handoff from a Raspucat quote to a live client project
using the modular_project template at `~/Documents/development/flutter_apps/dev/modular_project/`.

Load `.claude/skills/client-delivery/SKILL.md` before proceeding.

---

**Step 1 — Verify quote is ready**
- Confirm RASPUCAT_QUOTE_ID is known
- Confirm "Generate client.json" was clicked in Raspucat admin
- Confirm deposit has been paid (quote status: deposit_paid)

**Step 2 — Run new-client.sh**
```bash
cd ~/Documents/development/flutter_apps/dev/modular_project
./new-client.sh
```
When prompted, provide:
- Client name and slug (from Raspucat quote)
- Supabase project ref, URL, anon key (from new Supabase project)
- RASPUCAT_QUOTE_ID (from Raspucat admin)
- RASPUCAT_API (Raspucat Supabase URL)
- RASPUCAT_ADMIN_TOKEN (your admin token)

**Step 3 — Fill remaining client.json fields**
Open `clients/{slug}/execution/frontend/app/client.json` and complete:
- Branding: PERSONALITY, COLOR_*, FONT_*, HERO_VARIANT, NAV_STYLE
- Contact: PHONE, STREET, CITY, STATE, ZIP, COUNTRY, HOURS_JSON
- SEO: SEO_TITLE, SEO_DESCRIPTION, OG_IMAGE, SITE_URL
- Email: RESEND_KEY, FROM_EMAIL
- Payments: STRIPE_PK (if applicable)
- Feature flags as agreed with client

**Step 4 — Run deliver.sh**
```bash
cd clients/{slug}/execution/frontend/app
./deliver.sh
```
This will auto-report back to Raspucat when complete.

**Step 5 — Complete manual checklist**
- Register JWT custom claims hook in Supabase Auth → Hooks
- Set Auth redirect URLs in Supabase Auth → URL Configuration
- Push STRIPE_SK to Supabase secrets (if payments)
- Schedule cron jobs in Supabase dashboard
- Create storage buckets (gallery, course-videos, etc.) if needed
- Deploy build/web/ to Netlify or Vercel
- Start Resend domain verification (takes 24h)

**Step 6 — Mark complete in Raspucat**
- Tick off delivery steps in Raspucat admin delivery checklist
- Upload deliverables for client review in portal
- Charge balance payment when ready
