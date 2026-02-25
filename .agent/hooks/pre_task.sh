#!/usr/bin/env bash
# Pre-Task Synchronizer

# 1. Enforcement of STUDIO protocol
if grep -q "STUDIO" planning/CURRENT_TASK.md; then
  if [ ! -f STUDIO_PLAN.md ]; then
    echo "❌ ARCHITECT BLOCK: STUDIO task detected but STUDIO_PLAN.md is missing."
    echo "   Action: Ask the Planner (AntiGravity) to generate the plan first."
    exit 1
  fi
  echo "✅ STUDIO_PLAN.md verified."
fi

# 2. Skill & Context Audit
# Check if the task involves critical domains and suggest skills
if grep -qi "stripe\|payment" planning/CURRENT_TASK.md; then
  echo "⚖️ ARCHITECT ADVISORY: Task involves Payments. Ensure .cloud/skills/payments_dev/ is loaded."
fi

if grep -qi "flutter\|widget\|screen" planning/CURRENT_TASK.md; then
  echo "📱 ARCHITECT ADVISORY: UI Task. AntiGravity should lead implementation."
fi

# 3. Clean Context Signal
echo "--- 📋 MISSION START ---"
head -n 5 planning/CURRENT_TASK.md # Briefly show the goal