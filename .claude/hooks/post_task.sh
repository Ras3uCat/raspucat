#!/usr/bin/env bash
# KDE Connect Notifier

DEVICE_ID="dde92f39ac8040a08b80b8f6e6e964f8"
STATUS=$?
PROJECT=$(basename "$(dir=$PWD; while [ ! -d "$dir/.claude" ] && [ "$dir" != "/" ]; do dir=$(dirname "$dir"); done; echo "$dir")")

if [ $STATUS -eq 0 ]; then
  TITLE="✅ [$PROJECT] Task Done"
  MESSAGE="Sub-task finished successfully. Ready for review."
  kdeconnect-cli -d "$DEVICE_ID" --ping-msg "$TITLE: $MESSAGE" 2>/dev/null
  echo "📱 Success notification sent to phone."
else
  TITLE="🚨 [$PROJECT] Task Failed"
  MESSAGE="The subagent is stuck or a build error occurred. Intervention required!"
  kdeconnect-cli -d "$DEVICE_ID" --ping-msg "$TITLE: $MESSAGE" 2>/dev/null
  kdeconnect-cli -d "$DEVICE_ID" --ring 2>/dev/null
  echo "🚨 FAILURE DETECTED. Phone is ringing!"
fi
