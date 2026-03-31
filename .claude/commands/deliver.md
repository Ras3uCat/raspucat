Run a pre-flight delivery check for a Raspucat client project and surface the next blocking step: $ARGUMENTS

**Context:** Raspucat delivers client apps via the modular_project template.
This command checks readiness before running `new-client.sh` and `deliver.sh`.

---

Check each item in order. Stop at the first FAIL and output only the fix for that item.

**Pre-flight Checklist**

1. **Raspucat quote exists**
   - Confirm a quote ID is known (from Raspucat admin panel)
   - FAIL → create quote in Raspucat admin, collect deposit before proceeding

2. **client.json generated**
   - Confirm "Generate client.json" was clicked in Raspucat admin for this quote
   - Check that CLIENT_NAME, CLIENT_SLUG, MODULES, RASPUCAT_QUOTE_ID are filled
   - FAIL → generate from Raspucat admin panel

3. **Remaining client.json fields filled**
   - Brand fields: PERSONALITY, COLOR_*, FONT_* — not "FILL_IN"
   - Contact: PHONE, STREET, CITY, STATE, ZIP, COUNTRY — not empty
   - Backend: SUPABASE_URL, SUPABASE_ANON_KEY — not "FILL_IN"
   - FAIL → complete discovery call with client, fill missing fields

4. **modular_project new-client.sh run**
   - Check: `~/Documents/development/flutter_apps/clients/{CLIENT_SLUG}/` exists
   - FAIL → run `cd ~/Documents/development/flutter_apps/dev/modular_project && ./new-client.sh`

5. **Supabase linked**
   - From client project dir: `supabase status`
   - FAIL → `supabase link --project-ref <ref>`

6. **Flutter dependencies**
   - Run: `flutter pub get` in client's `execution/frontend/app/`
   - FAIL → show error output

7. **Dart analyzer clean**
   - Run: `dart analyze execution/frontend/app/lib/ --no-fatal-infos 2>&1 | tail -5`
   - FAIL → fix errors before building

8. **Ready to deliver**
   - All checks passed → print:
     ```
     ✅ Pre-flight complete. Run:
        cd execution/frontend/app && ./deliver.sh

     After deliver.sh completes:
     - Register JWT hook in Supabase Auth → Hooks
     - Set Auth redirect URL in Supabase Auth → URL Configuration
     - Schedule cron jobs
     - Deploy build/web/ to Netlify/Vercel
     - Set STRIPE_SK as Supabase secret (if payments enabled)
     - Mark deliver_sh_complete in Raspucat admin delivery checklist
     ```
