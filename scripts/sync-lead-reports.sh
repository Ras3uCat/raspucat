#!/bin/bash
# Syncs local lead report files to Supabase leads table.
# Usage: ./scripts/sync-lead-reports.sh <lead-id> <client-slug> <admin_token>
# Example: ./scripts/sync-lead-reports.sh abc-123 southside-tattoo myToken

set -e

LEAD_ID="${1}"
SLUG="${2}"
TOKEN="${3}"
BASE_URL="https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-leads"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og"

if [ -z "$LEAD_ID" ] || [ -z "$SLUG" ] || [ -z "$TOKEN" ]; then
  echo "Usage: $0 <lead-id> <client-slug> <admin_token>"
  echo "Example: $0 abc-123 southside-tattoo myToken"
  exit 1
fi

DIR="planning/leads/$SLUG"

if [ ! -d "$DIR" ]; then
  echo "Directory not found: $DIR"
  exit 1
fi

echo "Syncing reports for: $SLUG (lead: $LEAD_ID)"

# Build JSON body with all available report files
BODY=$(python3 -c "
import json, os

lead_id = '$LEAD_ID'
token = '$TOKEN'
base = '$DIR'

files = {
    'blueprintMd':        os.path.join(base, 'blueprint.md'),
    'brandBriefHtml':     os.path.join(base, 'brand_brief_report.html'),
    'competitorHtml':     os.path.join(base, 'competitor_report.html'),
    'brandAlignmentHtml': os.path.join(base, 'brand_alignment_report.html'),
    'customPlanMd':       os.path.join(base, 'custom-plan-draft.md'),
}

body = {'adminToken': token, 'action': 'sync-reports', 'leadId': lead_id}

for key, path in files.items():
    if os.path.exists(path):
        with open(path) as f:
            body[key] = f.read()
        print(f'  Including {key} ({os.path.getsize(path)} bytes)', flush=True)
    else:
        print(f'  Skipping {key} — not found', flush=True)

import sys
# Print to stderr to avoid mixing with JSON output
print(json.dumps(body), file=sys.stdout)
" 2>&1)

# Extract JSON (last line) from python output
JSON_BODY=$(echo "$BODY" | tail -1)
echo "$BODY" | head -n -1

RESPONSE=$(curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d "$JSON_BODY")

if echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if 'lead' in d else 1)" 2>/dev/null; then
  echo "✓ Reports synced — visible in Admin Panel → lead detail → Reports tab"
else
  echo "✗ Failed: $RESPONSE"
  exit 1
fi
