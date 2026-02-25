# Decision Log (ADR)

> **Goal:** To document the "Why" behind architectural pivots. This file serves as the ultimate constraint for agents to prevent regressive logic or repeating past mistakes.

---

## [ADR-001] Hybrid Agent Matrix
- **Date:** 2026-02-24
- **Status:** Approved
- **Context:** The project requires a fine-grained orchestration between high-level strategic reasoning (Claude) and low-level code implementation (AntiGravity).
- **Decision:** Formalize a hybrid model where Claude (Cloud) serves as the Planner/Architect, while AntiGravity (System) serves as the Flutter Subagent and UI Lead.
- **Rationale:** Claude excels at global context and safety checks, while AntiGravity's system access makes it more efficient for multi-file edits and UI automation.
- **Consequences:** All UI/Flutter tasks must be led by AntiGravity. Claude approves the high-level `STUDIO_PLAN.md` before AntiGravity begins implementation.

---

## [ADR-NNN] {Title}
- **Date:** YYYY-MM-DD
- **Status:** Proposed | Approved | Superseded
- **Context:** What was the problem or requirement?
- **Decision:** What did we choose to do?
- **Rationale:** Why did we choose this over other options?
- **Consequences:** What are the new rules/constraints for the agents?

---
