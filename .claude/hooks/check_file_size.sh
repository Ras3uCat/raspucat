#!/usr/bin/env bash
# PostToolUse hook — enforce 300-line Dart file limit (advisory, never blocks)

INPUT=$(cat)

FILE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Only check Dart files inside lib/
if [[ "$FILE" != */lib/**/*.dart && "$FILE" != */lib/*.dart ]]; then
  exit 0
fi

if [ ! -f "$FILE" ]; then
  exit 0
fi

# Controllers legitimately grow large — skip entirely
if [[ "$FILE" == *_controller.dart ]]; then
  exit 0
fi

LINE_COUNT=$(wc -l < "$FILE")

if [ "$LINE_COUNT" -gt 300 ]; then
  BASENAME=$(basename "$FILE")
  echo "{\"continue\": true, \"hookSpecificOutput\": {\"hookEventName\": \"PostToolUse\", \"additionalContext\": \"FILE SIZE WARN: $BASENAME has $LINE_COUNT lines (limit: 300). Extract to sub-files per flutter_style.md when this file is stable.\"}}"
  exit 0
fi

echo '{"continue": true}'
exit 0
