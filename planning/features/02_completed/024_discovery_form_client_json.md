# 024 — Discovery Form → Auto-Populate client.json

**id:** 024
**title:** Discovery Form → Auto-Populate client.json
**status:** Approved (not yet In Progress)
**mode:** STUDIO

---

## Overview

After a client pays their deposit, they receive an email directing them to their portal. Currently the portal's first stage is `transmitting`. We are adding a new first stage: `awaiting_discovery`. The client must complete a Discovery Form in the portal before the project advances. On submission, the stage advances to `transmitting`, the client receives a confirmation email, and the admin receives a notification. The discovery data is saved to `quotes.discovery_data` (JSONB). When the admin generates `client.json`, the edge function merges discovery fields over `FILL_IN` placeholders — producing an ~80% complete config file.

---

## Architecture Decisions (All Locked)

- **Form location:** Client portal (not admin drawer)
- **Portal stage flow:** `awaiting_discovery` → `transmitting` → `compiling` → `deployed`
- **Submit behavior:** One-time lock. Client sees read-only view after submit with "Contact us to make changes" note.
- **Admin view:** Editable discovery tab in admin quote detail drawer (for corrections/updates after client submits)
- **Feature flags:** Admin drawer only — not shown to client
- **New personalities:** `edgy`, `playful` captured in discovery_data and output to client.json. Presets not yet in modular_project — Option B (capture now, implement in modular_project later). Generator outputs the value; template will handle gracefully.
- **New nav style:** `hamburger` — same Option B treatment
- **Field name bug fix:** Current generator outputs `BRAND_COLOR_PRIMARY`, `BRAND_FONT` etc. These must be renamed to match what modular_project actually reads: `COLOR_PRIMARY`, `COLOR_SECONDARY`, `COLOR_ACCENT`, `COLOR_SURFACE`, `COLOR_ON_SURFACE`, `FONT_PRIMARY`, `FONT_SECONDARY`
- **Deposit email:** Swap "we'll be in touch for discovery session" copy → CTA to complete discovery form in portal
- **Celebrity question:** Admin reference only. Not in client.json. Stored in `discovery_data` under `brand_brief`.

---

## Discovery Form — Complete Question Set

### Section 1: Personality
**"What should customers feel when they land on your site?"**
Radio select — one choice required:
- Luxury & refined → `PERSONALITY: luxury`
- Bold & confident → `PERSONALITY: bold`
- Warm & welcoming → `PERSONALITY: warm`
- Clean & minimal → `PERSONALITY: minimal`
- Professional → `PERSONALITY: corporate`
- Edgy & urban → `PERSONALITY: edgy` *(modular_project TBD)*
- Playful & entertaining → `PERSONALITY: playful` *(modular_project TBD)*

### Section 2: Layout
**"How should your hero section look?"**
- Full bleed image → `HERO_VARIANT: fullbleed`
- Image + text side by side → `HERO_VARIANT: split`
- Centered → `HERO_VARIANT: centered`
- Video background → `HERO_VARIANT: video_bg`

**"Navigation style"**
- Sticky top bar → `NAV_STYLE: sticky`
- Transparent overlay → `NAV_STYLE: overlay`
- Minimal → `NAV_STYLE: minimal`
- Hamburger menu → `NAV_STYLE: hamburger` *(modular_project TBD)*

### Section 3: Colors
5 hex text inputs (stored without `#`, validated as 6-char hex):
- Primary color — buttons, links → `COLOR_PRIMARY`
- Secondary color — secondary UI → `COLOR_SECONDARY`
- Accent color — highlights, hover → `COLOR_ACCENT`
- Background color — page background → `COLOR_SURFACE`
- Text color — usually #FFFFFF or #111111 → `COLOR_ON_SURFACE`

### Section 4: Fonts
2 text inputs (Google Font name):
- Headline font → `FONT_PRIMARY`
- Body / UI font → `FONT_SECONDARY`

### Section 5: Brand Brief (admin reference — NOT in client.json)
- "Describe your brand in 3 words" → `brand_brief.three_words`
- "If your brand were a celebrity, who would it be and why?" → `brand_brief.celebrity`
- "List 1–2 websites you love the look of" (optional) → `brand_brief.inspo_urls`
- "Who is your primary customer?" → `brand_brief.target_customer`
- Short display name (<=12 chars, e.g. "Acme") → `SHORT_NAME` (goes in client.json)

### Section 6: Business
- Phone number → `PHONE`
- Street, City, State, ZIP, Country → `STREET`, `CITY`, `STATE`, `ZIP`, `COUNTRY`
- Business hours: Mon–Sun rows, open time + close time text fields + "Closed" checkbox → `HOURS_JSON`
- Timezone dropdown (US timezones + UTC) → `TIMEZONE`

### Section 7: Online Presence
- Domain name (optional) → `SITE_URL`

### Section 8: SEO
- Search title (60-char counter) → `SEO_TITLE`
- Search description (160-char counter) → `SEO_DESCRIPTION`
- Social share image URL (optional) → `OG_IMAGE`

---

## Scope

### Migration

**`supabase/migrations/20260327000001_discovery_data.sql`**
- Add `discovery_data jsonb NOT NULL DEFAULT '{}'::jsonb` to `public.quotes`
- Add `discovery_submitted_at timestamptz` to `public.quotes`
- Note: `portal_stage` is a text column — `awaiting_discovery` is a new valid value, no enum change needed
- Include `-- rollback:` comments for both columns

### Backend — New Edge Functions

**`supabase/functions/portal-save-discovery/index.ts`**
- Auth: Supabase magic-link session (client auth, RLS scoped to their quote)
- Input: `{ quote_id, discovery_data: {...}, submit?: boolean }`
- On save (draft): PATCH `quotes.discovery_data` only
- On submit (final): PATCH `quotes.discovery_data` + set `discovery_submitted_at = now()` + set `portal_stage = 'transmitting'`
- On submit: fire two emails via Resend:
  1. Client confirmation email — "We've received your discovery form. We'll be in touch shortly to schedule a deep discovery session where we'll align on your vision and goals."
  2. Admin notification email — "Discovery form submitted by [business_name]. Quote ID: [id]." with link to admin panel
- Return `{ ok: true, submitted: true/false }`

**`supabase/functions/admin-save-discovery/index.ts`**
- Auth: ADMIN_PASSWORD header check
- Input: `{ quote_id, discovery_data: {...} }`
- PATCH `quotes.discovery_data` for that quote_id — does NOT change `portal_stage` or `discovery_submitted_at` — admin edits do not re-trigger emails
- Return `200 { ok: true }`; `401` for bad auth; `400` for missing fields

### Backend — Modified Edge Functions

**`supabase/functions/admin-generate-client-json/index.ts`**
- Fix field name bug: rename all brand fields in output to match what modular_project reads:
  - `BRAND_COLOR_PRIMARY` → `COLOR_PRIMARY`
  - `BRAND_COLOR_SECONDARY` → `COLOR_SECONDARY`
  - Remove `BRAND_FONT` → add `FONT_PRIMARY`, `FONT_SECONDARY`
  - Add `COLOR_ACCENT`, `COLOR_SURFACE`, `COLOR_ON_SURFACE` (currently missing)
- Add `SHORT_NAME` to output
- Fetch `discovery_data` alongside existing quote columns
- Merge map (discovery key → client.json key, only if non-empty string / non-null):
  - `PERSONALITY`, `HERO_VARIANT`, `NAV_STYLE`, `HOME_SECTIONS`
  - `COLOR_PRIMARY`, `COLOR_SECONDARY`, `COLOR_ACCENT`, `COLOR_SURFACE`, `COLOR_ON_SURFACE`
  - `FONT_PRIMARY`, `FONT_SECONDARY`
  - `SHORT_NAME`
  - `SITE_URL`, `SEO_TITLE`, `SEO_DESCRIPTION`, `OG_IMAGE`
  - `PHONE`, `STREET`, `CITY`, `STATE`, `ZIP`, `COUNTRY`, `TIMEZONE`, `HOURS_JSON`
- `brand_brief.*` fields are NOT merged into client.json — admin reference only
- Secrets block always stays `FILL_IN`

**`supabase/functions/stripe-webhook/index.ts`**
- In the `deposit_paid` handler:
  - Set `portal_stage = 'awaiting_discovery'` on the quote (currently no stage is set — add this update)
  - Update client email copy:
    - Replace: "We will be in touch shortly to schedule a discovery session..."
    - With: "Your next step is to complete your Discovery Form in the portal — it takes about 5 minutes and sets the foundation for everything we build. Once submitted, we'll schedule a deep discovery session to align on your vision and goals."
    - Add a prominent "Complete Your Discovery Form →" button/link pointing to `/portal`

### Flutter — Portal

**New file:** `lib/app/modules/widgets/portal_discovery_form.dart`
- Widget: `PortalDiscoveryForm`
- Shown when `quote.portal_stage == 'awaiting_discovery'`
- Sections rendered in order: Personality, Layout, Colors, Fonts, Brand Brief, Business, Online Presence, SEO
- Auto-save (debounced 500ms) on any field change → calls `portal-save-discovery` (draft mode)
- Submit button: disabled until PERSONALITY is selected (all other fields optional but encouraged)
- On submit: calls `portal-save-discovery` with `submit: true` → locks form → shows read-only confirmation view
- Read-only state: displays all submitted values with a note "Want to make changes? Contact us."

**Modify:** `lib/app/modules/widgets/portal_dashboard.dart`
- Check `quote.portal_stage`
- If `awaiting_discovery`: show `PortalDiscoveryForm` prominently (full-screen step above other portal content)
- If `discovery_submitted_at` is set and stage is past `awaiting_discovery`: show read-only discovery summary card

**Modify:** `lib/app/controllers/portal_controller.dart`
- Ensure `fetchQuote` SELECT includes `portal_stage`, `discovery_data`, `discovery_submitted_at`
- Add `saveDiscoveryDraft(Map<String, dynamic> data)` → calls `portal-save-discovery` (no submit flag)
- Add `submitDiscovery(Map<String, dynamic> data)` → calls `portal-save-discovery` with `submit: true`

### Flutter — Admin

**New file:** `lib/app/modules/widgets/admin_discovery_tab.dart`
- Widget: `AdminDiscoveryTab`
- Displays all discovery fields as editable inputs (same sections as portal form)
- Loads from `detail['discovery_data']`
- Auto-save (debounced 500ms) → calls `admin-save-discovery`
- Shows `discovery_submitted_at` timestamp at top if submitted
- Feature flags section (admin-only, not in portal): SMS_ENABLED, GDPR_ENABLED, CHATBOT_ENABLED, DIGEST_ENABLED, LOYALTY_ENABLED, GIFT_ENABLED, INTAKE_ENABLED, GOOGLE_AUTH_ENABLED

**Modify:** `lib/app/modules/widgets/admin_detail_content.dart`
- Add `discovery` to `_Tab` enum
- Add "Discovery" tab button with amber dot badge if `discovery_submitted_at` is set and tab not yet viewed in this session
- Route `_Tab.discovery` → `AdminDiscoveryTab()`

**Modify:** `lib/app/controllers/admin_controller.dart`
- Ensure `fetchQuoteDetail` SELECT includes `discovery_data`, `discovery_submitted_at`
- Add `saveDiscoveryData(String quoteId, Map<String, dynamic> data)` → calls `admin-save-discovery`

---

## Acceptance Criteria

### Portal
- [ ] Client portal shows Discovery Form as the primary view when `portal_stage = 'awaiting_discovery'`
- [ ] PERSONALITY is required before submit is enabled; all other fields are optional
- [ ] Form auto-saves (debounced 500ms) to `discovery_data` while client fills it out
- [ ] On submit: `portal_stage` advances to `transmitting`, `discovery_submitted_at` is set
- [ ] After submit: form is locked; client sees read-only view of what they entered
- [ ] "Contact us to make changes" note is visible in read-only state

### Emails
- [ ] Client receives confirmation email on submit referencing deep discovery session
- [ ] Admin receives notification email on submit with business name + quote ID
- [ ] Deposit email CTA updated: prominent "Complete Your Discovery Form →" button/link
- [ ] `portal_stage` set to `awaiting_discovery` when deposit is paid

### Admin
- [ ] Discovery tab visible in quote detail drawer for all quotes
- [ ] Submitted discovery data loads correctly in admin tab
- [ ] Admin can edit any discovery field; changes auto-save without re-triggering client emails
- [ ] Feature flags section visible in admin tab (not in portal form)
- [ ] Amber badge on Discovery tab when client has submitted (until admin views it)
- [ ] `discovery_submitted_at` timestamp shown at top of admin discovery tab

### client.json Generator
- [ ] Field names corrected: `COLOR_PRIMARY`, `COLOR_SECONDARY`, `COLOR_ACCENT`, `COLOR_SURFACE`, `COLOR_ON_SURFACE`, `FONT_PRIMARY`, `FONT_SECONDARY`
- [ ] `SHORT_NAME`, `PERSONALITY`, `HERO_VARIANT`, `NAV_STYLE` added to output
- [ ] All discovery fields merge correctly — non-empty values replace `FILL_IN`
- [ ] `brand_brief.*` fields are NOT included in client.json output
- [ ] Secrets block always `FILL_IN` regardless of discovery data

### Data
- [ ] Migration adds `discovery_data jsonb` and `discovery_submitted_at` to quotes
- [ ] `portal-save-discovery` returns 401 without valid client session
- [ ] `admin-save-discovery` returns 401 without valid admin password
- [ ] Existing quotes (pre-feature) render without errors (`discovery_data` defaults to `{}`)

---

## Edge Cases & QA

- Client submits with only PERSONALITY filled — all other fields must output `FILL_IN` in generated client.json, not empty string or null
- Client refreshes page mid-fill — auto-saved draft must reload correctly from `discovery_data`
- Admin edits discovery data after client submitted — `discovery_submitted_at` must not be cleared
- `portal-save-discovery` called with empty `discovery_data` object — must not overwrite existing data with empty
- Hex color validation: reject inputs that are not exactly 6 hex characters; strip `#` prefix on store, re-add on display
- `HOURS_JSON` with all days marked Closed — must produce valid JSON, not null
- Generator called before client submits — empty `{}` default results in all new fields outputting `FILL_IN`
- Stripe webhook fires twice (idempotency) — `deposit_paid` handler must not double-set `portal_stage` or send duplicate emails
- `edgy` and `playful` PERSONALITY values — generator outputs as-is; modular_project template gracefully falls back (follow-up 027)
- `hamburger` NAV_STYLE — same fallback treatment (follow-up 027)

---

## Dependencies

- `portal_stage` column is text — `awaiting_discovery` requires no migration; stripe-webhook handler sets it directly
- `portal-save-discovery` requires Supabase RLS policy allowing clients to UPDATE their own quote's `discovery_data` and `portal_stage`
- `admin-generate-client-json` must be deployed after migration lands
- No new Dart packages required

---

## Follow-Up Tasks (out of scope for 024)

**027 already exists** in backlog — implements all 9 new personality presets + hamburger nav in modular_project.

When 027 ships, the personality radio in this discovery form must be expanded from 7 → 14 options. Add these 9 new choices (see 027 for archetypes):

- Edgy & raw → `PERSONALITY: edgy`
- Playful & fun → `PERSONALITY: playful`
- Artisan & handcrafted → `PERSONALITY: artisan`
- Calm & wellness → `PERSONALITY: wellness`
- Tech & modern → `PERSONALITY: tech`
- Retro & nostalgic → `PERSONALITY: retro`
- Natural & organic → `PERSONALITY: nature`
- Creative & editorial → `PERSONALITY: creative`
- Nightlife & moody → `PERSONALITY: nightlife`
