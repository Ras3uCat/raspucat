#!/bin/bash
# Syncs local industry narrative files to Supabase industry_profiles table.
# Usage: ./scripts/sync-industry-narratives.sh <slug> <"Full Name"> <admin_token>
# Example: ./scripts/sync-industry-narratives.sh tattoo-shop "Tattoo Shops" mySecretToken

set -e

SLUG="${1}"
NAME="${2}"
TOKEN="${3}"
BASE_URL="https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-leads"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZ3dxeXdnYmd6YWhuZnRwcGRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDIyMDQsImV4cCI6MjA4OTI3ODIwNH0.2DgzGgFAMzb5jxULTDthYs0SPH7zmM8rvkMSOQlY2Og"

if [ -z "$SLUG" ] || [ -z "$NAME" ] || [ -z "$TOKEN" ]; then
  echo "Usage: $0 <slug> <\"Full Name\"> <admin_token>"
  echo "Example: $0 tattoo-shop \"Tattoo Shops\" myToken"
  exit 1
fi

DIR="planning/industries"

sync_field() {
  local field_key="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    echo "  Skipping $field_key — file not found: $file"
    return
  fi

  echo "  Syncing $field_key from $file..."

  local body
  body=$(python3 -c "
import json, sys
with open('$file') as f:
    content = f.read()
print(json.dumps({'adminToken': '$TOKEN', 'action': 'sync-industry', 'slug': '$SLUG', 'name': '$NAME', '$field_key': content}))
")

  local response
  response=$(curl -s -X POST "$BASE_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -d "$body")

  if echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if 'profile' in d else 1)" 2>/dev/null; then
    echo "  ✓ $field_key synced"
  else
    echo "  ✗ $field_key failed: $response"
  fi
}

echo "Syncing narratives for: $NAME ($SLUG)"
sync_field "rideAlongMd"     "$DIR/$SLUG-ride-along.md"
sync_field "moneyMapMd"      "$DIR/$SLUG-money-map.md"
sync_field "clientLocatorMd" "$DIR/$SLUG-client-locator.md"
echo "Done."
