#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <site-name> <supabase-url> <anon-key> <table>" >&2
  echo "  <table> must be a real table in the public schema — the ping queries" >&2
  echo "  it via PostgREST so it counts as database activity, not just an API hit." >&2
  echo "Example: $0 raspucat https://gegwqywgbgzahnftppda.supabase.co eyJhbGciOi... leads" >&2
  exit 1
fi

NAME="$1"
URL="$2"
ANON_KEY="$3"
TABLE="$4"

cd "$(dirname "$0")"

VALUE=$(printf '{"url":"%s","anonKey":"%s","table":"%s"}' "$URL" "$ANON_KEY" "$TABLE")

npx wrangler kv:key put --binding=SITES_KV "$NAME" "$VALUE"

echo "Added '$NAME'. Current sites in supabase-keepalive:"
npx wrangler kv:key list --binding=SITES_KV | grep -o '"name": *"[^"]*"'
