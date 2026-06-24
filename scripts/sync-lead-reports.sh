#!/bin/bash
# Syncs local lead report files to Supabase leads table.
# Usage: ./scripts/sync-lead-reports.sh <lead-id> <client-slug> <admin_token> [flags]
# Flags:
#   --custom-plan <path>   Sync confirmed post-call plan  → custom_plan_md
#   --proposal    <path>   Sync proposal HTML             → proposal_html
#
# Example (prepare-lead):
#   ./scripts/sync-lead-reports.sh abc-123 southside-tattoo myToken
# Example (prepare-reply):
#   ./scripts/sync-lead-reports.sh abc-123 southside-tattoo myToken \
#     --custom-plan outputs/southside-tattoo/custom-plan.md \
#     --proposal    outputs/southside-tattoo/proposal.html

set -e

LEAD_ID="${1}"
SLUG="${2}"
TOKEN="${3}"
shift 3

BASE_URL="https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-leads"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og"
# System DNS (via getent) fails to resolve the Supabase subdomain; use --resolve to bypass
SUPABASE_RESOLVE="gegwqywgbgzahnftppda.supabase.co:443:172.64.149.246"

CUSTOM_PLAN_PATH=""
PROPOSAL_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --custom-plan) CUSTOM_PLAN_PATH="$2"; shift 2 ;;
    --proposal)    PROPOSAL_PATH="$2";    shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

if [ -z "$LEAD_ID" ] || [ -z "$SLUG" ] || [ -z "$TOKEN" ]; then
  echo "Usage: $0 <lead-id> <client-slug> <admin_token> [--custom-plan <path>] [--proposal <path>]"
  exit 1
fi

DIR="planning/leads/$SLUG"

if [ ! -d "$DIR" ]; then
  echo "Directory not found: $DIR"
  exit 1
fi

echo "Syncing reports for: $SLUG (lead: $LEAD_ID)"

BODY=$(python3 -c "
import json, os, sys

lead_id = '$LEAD_ID'
token = '$TOKEN'
base = '$DIR'
custom_plan_path = '$CUSTOM_PLAN_PATH'
proposal_path = '$PROPOSAL_PATH'

# Standard prepare-lead files (always auto-detected from slug dir)
files = {
    'blueprintMd':        os.path.join(base, 'blueprint.md'),
    'brandBriefHtml':     os.path.join(base, 'brand_brief_report.html'),
    'competitorHtml':     os.path.join(base, 'competitor_report.html'),
    'brandAlignmentHtml': os.path.join(base, 'brand_alignment_report.html'),
    'customPlanDraftMd':  os.path.join(base, 'custom-plan-draft.md'),
}

# Explicit prepare-reply outputs (only included when flag is passed)
if custom_plan_path:
    files['customPlanMd'] = custom_plan_path
if proposal_path:
    files['proposalHtml'] = proposal_path

body = {'adminToken': token, 'action': 'sync-reports', 'leadId': lead_id}

for key, path in files.items():
    if os.path.exists(path):
        with open(path) as f:
            body[key] = f.read()
        print(f'  Including {key} ({os.path.getsize(path)} bytes)', flush=True)
    else:
        print(f'  Skipping {key} — not found', flush=True)

print(json.dumps(body), file=sys.stdout)
" 2>&1)

# Extract JSON (last line) from python output
JSON_BODY=$(echo "$BODY" | tail -1)
echo "$BODY" | head -n -1

RESPONSE=$(curl -s --resolve "$SUPABASE_RESOLVE" -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d "$JSON_BODY")

if echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if 'lead' in d else 1)" 2>/dev/null; then
  echo "✓ Reports synced — visible in Admin Panel → lead detail → Reports tab"
else
  echo "✗ Failed: $RESPONSE"
  exit 1
fi
