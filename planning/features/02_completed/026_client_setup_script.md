# 026_client_setup_script

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
Add a "Setup Script" download button to the existing `AdminClientJsonDialog`. When clicked, the browser
downloads a shell script (`{slug}-setup.sh`) that fully bootstraps a new client project — cloning the
private `Ras3uCat/modular_project` template, writing the pre-generated `client.json`, prompting for
Supabase credentials, and running `supabase link` + `deliver.sh` automatically.

This eliminates most of the manual steps in the client delivery process.

---

## What already exists (reuse, don't rebuild)
- `lib/app/modules/widgets/admin_client_json_dialog.dart` — dialog with Download/Copy; already uses `dart:html` for file downloads
- `admin_controller.dart:generateClientJson()` — calls `admin-generate-client-json` Edge Function
- Button to open dialog: `admin_detail_content.dart:240`

No new Edge Function or backend changes needed.

---

## Files to change

| File | Change |
|------|--------|
| `lib/app/modules/widgets/admin_client_json_dialog.dart` | Add "Setup Script" button + `_downloadSetupScript()` method; update `_manualFields` |
| `lib/app/modules/widgets/_client_setup_script_builder.dart` | **New** — `buildClientSetupScript()` top-level function (keeps dialog under 300 lines) |

---

## Script behaviour

```
→ Cloning modular_project template...
→ Writing client.json...

┌──────────────────────────────────────────────────────────────┐
│  ACTION REQUIRED — Create a Supabase project                 │
│                                                              │
│  1. Sign up at supabase.com with: cheeseinc@raspucat.com     │
│  2. Create a new project (free tier)                         │
│  3. Go to Settings → API and copy the Project URL + anon key │
└──────────────────────────────────────────────────────────────┘
(opening browser...)
Press Enter when your Supabase project is ready...

Enter Supabase Project URL: https://xxxx.supabase.co
Enter Supabase Anon Key:    eyJ...
Enter Raspucat Admin Token: ****

→ Patching client.json...
→ Linking Supabase CLI...
→ Running deliver.sh...

✓ Done — check Raspucat admin for delivery progress
```

---

## `_client_setup_script_builder.dart` — shell script template

Key sections:
1. `git clone git@github.com:Ras3uCat/modular_project "$TARGET"` — no local template path needed
2. Strip `.git`, re-init, `chmod +x deliver.sh`
3. Write embedded `client.json` via heredoc
4. Open `https://supabase.com/dashboard/sign-up` in browser
5. `read` prompts for `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `RASPUCAT_ADMIN_TOKEN`
6. `python3` patches the 3 values into client.json
7. Extract project ref from URL: `sed 's|https://||' | sed 's|\.supabase\.co.*||'`
8. `supabase link --project-ref "$PROJECT_REF"`
9. `./deliver.sh`

Requires: git with SSH access to github.com/Ras3uCat, Supabase CLI, python3.

---

## `admin_client_json_dialog.dart` changes

### New method
```dart
void _downloadSetupScript() {
  if (_json == null) return;
  String slug = 'client';
  String name = 'Client';
  try {
    final map = jsonDecode(_json!) as Map<String, dynamic>;
    slug = (map['CLIENT_SLUG'] as String?) ?? slug;
    name = (map['CLIENT_NAME'] as String?) ?? name;
  } catch (_) {}
  final script = buildClientSetupScript(slug, name, _json!);
  final blob = html.Blob([script], 'text/x-shellscript');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', '$slug-setup.sh')
    ..click();
  html.Url.revokeObjectUrl(url);
}
```

### New button in `_buildHeader()` (between Download and Copy)
Styled with `EColors.secondary` border/text to visually distinguish from the JSON download.

### Updated `_manualFields`
Remove stale: `BRAND_COLOR_PRIMARY`, `BRAND_COLOR_SECONDARY`, `BRAND_FONT`, `SMTP_*`
Add missing: `RASPUCAT_ADMIN_TOKEN`, `RESEND_KEY`
Final list: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
`RASPUCAT_ADMIN_TOKEN`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `RESEND_KEY`,
`SITE_URL`, `LOGO_URL`

### New imports
```dart
import 'dart:convert';
import '_client_setup_script_builder.dart';
```

---

## Verification
1. Admin → client detail → "client.json" button → dialog opens
2. Click "Setup Script" → `{slug}-setup.sh` downloads
3. Inspect script: confirm clone URL is `git@github.com:Ras3uCat/modular_project`, client.json embedded, slug/name correct
4. Run on machine: confirms clone → write → interactive prompts → supabase link → deliver.sh
5. Confirm guard: if target dir already exists, script exits with clear error
