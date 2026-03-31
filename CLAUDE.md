# Raspucat Constitution (Global Context)

## ROLE
Claude is the **Planner/Architect** (Global Strategy & Safety).
AntiGravity is the **Flutter Subagent** (Feature Implementation & UI Design).

## AGENT BEHAVIOR
1. **Bootstrap:** Hooks are wired automatically via `.claude/settings.json` — `skill_loader.sh` + `pre_task.sh` fire on SessionStart.
2. **Handshake:** Confirm the active task in `planning/features/01_active/`. AntiGravity leads Flutter/UI tasks, including sub-task planning within those scopes.
3. **Skill Check:** Verify corresponding `.claude/skills/` pack is loaded before implementation.
4. **Constraint:** No implementation until a task is assigned. Summary-only on first message.

## TECH STACK & ARCHITECTURE
- **State Management:** GetX (Strict). Feature-first: `lib/app/modules/<feature>/`.
- **Backend:** Supabase. All DB changes must be timestamped SQL migrations in `supabase/migrations/`.
- **Payments:** Stripe (Checkout + Webhooks). Use `.claude/skills/stripe-*` for implementation.
- **UI:** Material 3 + `E-Prefix` constants (e.g., `EColors.primary`). Use `.claude/skills/frontend-design` for high-end aesthetic execution.

## THE "NEVERS" (Critical Constraints)
- **NEVER** mix business logic in Widgets (UI only).
- **NEVER** exceed 300 lines per file (Refactor > 300 immediately).
- **NEVER** trust client-side state for Auth, Permissions, or Payments.
- **NEVER** bypass the Repository pattern in the data layer.
- **NEVER** ignore `planning/DECISIONS.md` (ADR) history.

## WORKFLOW MODES
- **FLOW:** Small diffs/bugs. Incremental commits.
- **STUDIO:** Complex features. **MANDATORY:** The active feature file in `planning/features/01_active/` must have `Mode: STUDIO` and complete scope/acceptance criteria before implementation begins.

## MEMORY & KNOWLEDGE
- **Source of Truth:** `planning/features/01_active/` (active feature file is the current task).
- **Historical Context:** `planning/DECISIONS.md`.

## CONTEXT BUDGET
- Target max active context: 6,000 tokens.
- Prefer summaries over raw files.
- Use subagents for multi-file exploration.
- NEVER load more than 3 source files unless explicitly required.

## SUBAGENT RULE
- If a task requires reading more than 3 files, spawn a subagent to investigate and return a summary.
- Main agent must not ingest raw multi-file content.

## LOCAL AGENT DELEGATION
- Flutter UI tasks → delegate to **Flutter subagent AntiGravity**.
- Multi-file investigation → delegate to subagents.
- Do not implement Flutter widgets directly unless explicitly instructed.
- Specialist agents: see `.claude/agents/` (architect, planner, flutter, backend, payments, qa, security-auditor).

## LOCAL SUBAGENT OPTIMIZATION
1. **Bootstrap Speed:** Skip full project analysis. Focus ONLY on the immediate file/task.
2. **Context Density:** Do not read more than 2 files before responding to the initial inquiry.
3. **No-Wait Mode:** Respond as soon as the core task is identified.

## SLASH COMMANDS
- `/health` — environment health check
- `/status` — current sprint status
- `/review` — structured code review
- `/fix-issue` — bug fix workflow
- `/gen-feature` — scaffold new feature
- `/migrate` — generate Supabase migration boilerplate
- `/deliver` — pre-flight client delivery check
- `/new-client` — scaffold new client project
