# 023 — Claude Harness Upgrade

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Complete

## Context
The Raspucat project's Claude harness is on the legacy structure (`.agent/hooks/`, `.cloud/skills/`).
The modular_project completed the same upgrade in Wave 0 (feature 103–107) and is now significantly
more capable: auto-formatting, file size enforcement, stale-path guards, build diagnostics, and
8 custom slash commands.

This feature migrates Raspucat to the same production harness standard.

## What Needs To Change

### 1. Directory Migration
| From (legacy) | To (target) |
|---|---|
| `.agent/hooks/` | `.claude/hooks/` |
| `.cloud/skills/` | `.claude/skills/` |
| `.claude/agents.json` | `.claude/agents/*.md` (individual files) |

Delete `.agent/` and `.cloud/` after migration.

### 2. New Hooks (4)
Copy and adapt from modular_project `.claude/hooks/`:

| Hook | Trigger | What it does |
|---|---|---|
| `pre_bash.sh` | PreToolUse (Bash) | Blocks commits with legacy paths (`.cloud/`, `.agent/`), secrets, dart analyze failures |
| `format_dart.sh` | PostToolUse (Write/Edit) async | Auto-formats Dart files to 100-char line length |
| `check_file_size.sh` | PostToolUse (Write/Edit) | Blocks files >300 lines in `lib/` |
| `diagnose_build.sh` | PostToolUseFailure (Bash) async | Auto-diagnoses Flutter/Dart build failures via `claude --print` |

### 3. Existing Hook Enhancements (2)
- **`pre_task.sh`** — Add backend keyword detection (`supabase|migration|rls|repository`)
- **`post_task.sh`** — Add `2>/dev/null` to kdeconnect-cli calls for cleaner error handling

### 4. New Skills (4)
Copy from modular_project `.claude/skills/`:
- `client-delivery/` (SKILL.md + DETAILED_GUIDE.md)
- `seo-strategy/` (SKILL.md + DETAILED_GUIDE.md)
- `scroll-stop-builder/SKILL.md`
- Add `DETAILED_GUIDE.md` to existing: `backend-dev/`, `frontend-design/`, `qa/`

### 5. Agent Files (decompose agents.json → individual .md files)
Create `.claude/agents/` with one file per agent:
- `planner.md`, `architect.md`, `flutter.md`, `backend.md`, `payments.md`, `qa.md`
- Add new: `security-auditor.md`
- Delete `agents.json` after migration

### 6. Commands (8 new slash commands)
Create `.claude/commands/`:
- `status.md` — Current sprint/workflow state
- `health.md` — Environment health check
- `review.md` — Structured code review
- `fix-issue.md` — Bug fix workflow
- `gen-feature.md` — Scaffold a new feature
- `migrate.md` — Generate Supabase migration boilerplate
- `deliver.md` — Pre-flight delivery check (adapt for Raspucat delivery flow)
- `new-client.md` — Scaffold new client project (links to modular_project new-client.sh)

### 7. Rules (3 style guides)
Create `.claude/rules/`:
- `flutter_style.md` — Dart/Flutter conventions (300-line limit, GetX, const, etc.)
- `api_conventions.md` — Supabase query rules, RLS, Edge Function patterns
- `testing_rules.md` — Test structure, GetX testing, forbidden patterns

### 8. settings.json (replace settings.local.json)
Replace `.claude/settings.local.json` with `.claude/settings.json` containing:
- Full hook orchestration (SessionStart, PostToolUse, PreToolUse, PostToolUseFailure, Stop, Notification)
- Permission allowlist (carry over from current settings.local.json + add mv for features workflow)
- Deny list (force push, hard reset, rm -rf, curl|bash)

### 9. CLAUDE.md Update
- Update hook path references from `.agent/hooks/` → `.claude/hooks/`
- Update skills path from `.cloud/skills/` → `.claude/skills/`
- Remove inline hook JSON block (now lives in settings.json)
- Add references to `.claude/rules/`, `.claude/commands/`, `.claude/agents/`

## Acceptance Criteria
- [ ] `.agent/` and `.cloud/` directories deleted
- [ ] All 7 hooks in `.claude/hooks/` and executable
- [ ] `settings.json` wired — hooks fire on SessionStart, Edit/Write, Bash, Stop
- [ ] `flutter analyze` clean after migration
- [ ] `pre_bash.sh` blocks any commit referencing `.cloud/` or `.agent/`
- [ ] `format_dart.sh` fires after Dart file edits
- [ ] `check_file_size.sh` fires and blocks >300-line lib/ files
- [ ] `diagnose_build.sh` fires on Bash failures
- [ ] 12 skills in `.claude/skills/`
- [ ] 7 agent `.md` files in `.claude/agents/`, `agents.json` removed
- [ ] 8 commands in `.claude/commands/`
- [ ] 3 rules in `.claude/rules/`
- [ ] CLAUDE.md updated with correct paths
- [ ] Session start fires skill_loader + pre_task hooks correctly

## Implementation Notes
- Copy hooks/skills/agents/commands/rules from modular_project as base
- Adapt `pre_bash.sh` path checks for Raspucat's `lib/` location (not `execution/frontend/app/lib/`)
- Adapt `check_file_size.sh` for Raspucat's `lib/` path
- `diagnose_build.sh` can be copied verbatim
- Keep `settings.local.json` for MCP config (don't fold into settings.json)
- Do NOT add `client-delivery` skill triggers to CLAUDE.md — Raspucat is not a client project

## File Paths (Critical)
- Source (modular_project): `/home/ryan/Documents/development/flutter_apps/dev/modular_project/.claude/`
- Target (raspucat): `/home/ryan/Documents/development/flutter_apps/raspucat/.claude/`
- Legacy to delete: `/home/ryan/Documents/development/flutter_apps/raspucat/.agent/`
- Legacy to delete: `/home/ryan/Documents/development/flutter_apps/raspucat/.cloud/`
