#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <site-name> <supabase-url> <anon-key>" >&2
  echo "Example: $0 raspucat https://gegwqywgbgzahnftppda.supabase.co eyJhbGciOi..." >&2
  exit 1
fi

NAME="$1"
URL="$2"
ANON_KEY="$3"

cd "$(dirname "$0")"

VALUE=$(printf '{"url":"%s","anonKey":"%s"}' "$URL" "$ANON_KEY")

npx wrangler kv:key put --binding=SITES_KV "$NAME" "$VALUE"

echo "Added '$NAME'. Current sites in supabase-keepalive:"
npx wrangler kv:key list --binding=SITES_KV | grep -o '"name": *"[^"]*"'
