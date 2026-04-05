---
id: 028
title: Logo Upload + Auto Favicon/OG Generation
mode: STUDIO
status: completed
---

# Feature 028 — Logo Upload + Auto Favicon/OG Generation

## Goal
Admin uploads the client's logo once → deliver.sh auto-generates all favicon/PWA icon sizes
→ `favicon_replaced` delivery step is auto-checked. OG image is a separate upload (better
quality than auto-generating from the logo). `og_image_set` auto-checks on that upload.

---

## Current State
- `LOGO_URL` in `generate-client-json` is hardcoded `'FILL_IN'` (line 119) — not read from DB
- `prepare.sh` replaces tokens in HTML/manifest but does NOT touch icons/favicons
- `favicon_replaced` and `og_image_set` are fully manual delivery steps
- No `logo_url` column on `quotes` table (confirmed — no migration exists)
- Existing storage bucket: `portal-files` (client-facing). Logo uploads need a separate
  admin-only bucket: `admin-assets`

---

## Desired Flow
1. Admin uploads logo in admin detail panel → stored in Supabase Storage (`admin-assets` bucket)
2. Public URL saved to `quotes.logo_url`
3. `generate-client-json` reads `quotes.logo_url` → writes to `LOGO_URL` in client.json
4. `prepare.sh` downloads `LOGO_URL` → generates favicon + PWA icons via ImageMagick
5. deliver.sh detects generated icons → reports `favicon_replaced` to Raspucat (auto-check)
6. Admin separately uploads OG image → `quotes.og_image_url` → `og_image_set` auto-checked

---

## Part A — Storage Bucket + DB

### Migration
```sql
-- Add logo_url and og_image_url to quotes
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS og_image_url text;

-- Admin-assets bucket (public read, service_role write — no user RLS needed)
INSERT INTO storage.buckets (id, name, public)
VALUES ('admin-assets', 'admin-assets', true)
ON CONFLICT (id) DO NOTHING;
```

> Bucket is public-read so the URL is directly usable in client.json without signed URLs.
> Writes are protected by the Edge Function which validates `adminToken`.

---

## Part B — Upload Edge Function

New: `supabase/functions/admin-upload-asset/index.ts`

- Accepts: `adminToken`, `quoteId`, `field` (`logo` | `og_image`), `fileBase64`, `mimeType`, `fileName`
- Validates admin token
- Uploads to `admin-assets/logos/{quoteId}/{fileName}` or `admin-assets/og/{quoteId}/{fileName}`
- Gets public URL from Supabase Storage
- Updates `quotes.logo_url` or `quotes.og_image_url`
- Returns `{ url }`

> Alternative: use Supabase Storage client directly from Flutter with service role key.
> Rejected — service role key must never be in Flutter client. Edge Function is correct.

---

## Part C — Admin UI

In `admin_detail_content.dart` (Details tab), add two upload rows below the existing fields:

```
[ Logo ]         [current preview or placeholder]  [Upload]
[ OG Image ]     [current preview or placeholder]  [Upload]  1200×630
```

- Clicking Upload opens a file picker (`dart:html` `FileUploadInputElement`)
- Reads as base64, POSTs to `admin-upload-asset`
- On success: shows thumbnail preview + auto-checks the relevant delivery step via
  `ctrl.autoCheckDeliveryStep(quoteId, 'favicon_replaced')` / `'og_image_set'`

> `favicon_replaced` auto-checked on logo upload (prepare.sh will handle generation on next
> deliver.sh run). This is a slight optimism — if they re-run deliver.sh without ImageMagick
> it won't actually replace. Accept this trade-off; the warning in deliver.sh covers it.

---

## Part D — generate-client-json update

In `admin-generate-client-json/index.ts`, replace:
```ts
LOGO_URL: 'FILL_IN',
```
with:
```ts
LOGO_URL: quote.logo_url ?? 'FILL_IN',
OG_IMAGE: quote.og_image_url ?? 'FILL_IN',
```

Also select `logo_url, og_image_url` in the quotes query.

---

## Part E — prepare.sh Favicon Generation

Add after the existing token-replacement block:

```bash
# ── Favicon + PWA icon generation ─────────────────────────────────────────────
LOGO_URL_VAL=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('LOGO_URL',''))" 2>/dev/null || echo "")

if [[ -n "$LOGO_URL_VAL" && "$LOGO_URL_VAL" != "FILL_IN" ]]; then
  if command -v convert &>/dev/null; then
    TMP_LOGO=$(mktemp /tmp/logo_XXXXXX)
    COLOR_SURFACE=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('COLOR_SURFACE','000000'))" 2>/dev/null || echo "000000")
    if curl -sf "$LOGO_URL_VAL" -o "$TMP_LOGO"; then
      convert "$TMP_LOGO" -resize 32x32     "$WEB_DIR/favicon.png"
      convert "$TMP_LOGO" -resize 192x192   "$WEB_DIR/icons/Icon-192.png"
      convert "$TMP_LOGO" -resize 512x512   "$WEB_DIR/icons/Icon-512.png"
      # Maskable: 10% safe-zone padding using brand surface colour
      convert "$TMP_LOGO" -resize 154x154 -gravity center \
        -background "#$COLOR_SURFACE" -extent 192x192 "$WEB_DIR/icons/Icon-maskable-192.png"
      convert "$TMP_LOGO" -resize 410x410 -gravity center \
        -background "#$COLOR_SURFACE" -extent 512x512 "$WEB_DIR/icons/Icon-maskable-512.png"
      green "Favicons + PWA icons generated from LOGO_URL"
      touch /tmp/.favicon_generated_${CLIENT_SLUG}  # flag file for deliver.sh
    else
      warn "Could not download LOGO_URL — favicons not replaced."
    fi
    rm -f "$TMP_LOGO"
  else
    warn "ImageMagick not found — favicons not replaced. Install: brew install imagemagick"
  fi
else
  warn "LOGO_URL not set — favicons not replaced."
fi
```

> **Why a flag file?** `prepare.sh` runs as a subprocess of deliver.sh (`bash prepare.sh`),
> so shell variables set inside it are not visible to deliver.sh. A temp flag file
> `/tmp/.favicon_generated_{slug}` is the clean solution.

---

## Part F — deliver.sh Reporting

`prepare.sh` runs as a subprocess so `FAVICON_GENERATED` won't propagate. Check the flag file:

```bash
# After prepare.sh call, in the Raspucat reporting block:
if [[ -f "/tmp/.favicon_generated_${CLIENT_SLUG}" && "$RASPUCAT_REPORTED" == true ]]; then
  rm -f "/tmp/.favicon_generated_${CLIENT_SLUG}"
  curl -sf -X POST "${RASPUCAT_API}/functions/v1/admin-delivery-progress" \
    -H "Content-Type: application/json" \
    -d "{\"adminToken\":\"${RASPUCAT_ADMIN_TOKEN}\",\"quoteId\":\"${RASPUCAT_QUOTE_ID}\",\"action\":\"upsert\",\"step\":\"favicon_replaced\",\"checked\":true,\"checked_by\":\"system\"}" \
    2>/dev/null && green "favicon_replaced reported" || true
fi
```

---

## Part G — Delivery Step Updates (Flutter)

In `admin_delivery_section.dart`, mark as `isAuto: true`:
- `favicon_replaced`
- `og_image_set`

---

## OG Image Decision — Resolved: Separate Upload

OG images are 1200×630 marketing banners. Auto-generating from a logo produces poor results.
Admin uploads it separately — same flow as logo but different field. `og_image_set` auto-checks
on that upload in the admin UI (Part C).

---

## Acceptance Criteria
- [ ] `admin-assets` storage bucket created via migration (public read)
- [ ] `quotes.logo_url` and `quotes.og_image_url` columns exist
- [ ] `admin-upload-asset` Edge Function uploads file and updates quote
- [ ] Logo upload UI visible in admin detail (Details tab)
- [ ] OG image upload UI visible in admin detail with 1200×630 label
- [ ] `generate-client-json` outputs real URL (not FILL_IN) when logo/OG are uploaded
- [ ] `prepare.sh` generates 5 icon sizes when LOGO_URL is set and ImageMagick is available
- [ ] Maskable icons use `COLOR_SURFACE` as background, not hardcoded white
- [ ] deliver.sh reports `favicon_replaced` via flag file mechanism
- [ ] `og_image_set` auto-checked when OG image is uploaded in admin UI
- [ ] Both steps show gold/locked in delivery tab
- [ ] Graceful skip + warning when ImageMagick not installed or LOGO_URL missing
- [ ] Works on macOS (`brew install imagemagick`) and Linux (`apt install imagemagick`)

---

## Files to Change
| File | Change |
|------|--------|
| `supabase/migrations/YYYYMMDD_logo_og_image.sql` | `logo_url`, `og_image_url` columns + `admin-assets` bucket |
| `supabase/functions/admin-upload-asset/index.ts` | New Edge Function |
| `supabase/functions/admin-generate-client-json/index.ts` | Read `logo_url` / `og_image_url` from quote |
| `lib/app/modules/widgets/admin_detail_content.dart` | Logo + OG upload UI |
| `lib/app/controllers/admin_controller.dart` | `uploadAsset()` method |
| `execution/frontend/app/prepare.sh` | Favicon generation block (modular_project) |
| `execution/frontend/app/deliver.sh` | Flag file check + favicon_replaced report (modular_project) |
| `lib/app/modules/widgets/admin_delivery_section.dart` | `isAuto: true` for favicon_replaced + og_image_set |
