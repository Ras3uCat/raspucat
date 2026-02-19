# Strategic Roadmap

## Vision
One sentence describing the core "Why" of this project and who it serves.

## Tech Stack (Active)
- **Frontend:** Flutter (GetX)
- **Backend:** Supabase (PostgreSQL + RLS)
- **Payments:** Stripe 
- **Architecture:** [ADR History](planning/decisions.md)

---

## Release Phases
This section defines the "When." Use IDs that link directly to your /features directory.

### Phase 0: Setup & Infrastructure
Status: [ 📝 BACKLOG | 🏗️ ACTIVE | ✅ COMPLETE ]
Goal: Establish the foundation.
- [ ] 000_ci_cd_pipeline
- [ ] 001_database_schema_v1
- [ ] 002_auth_foundation

### Phase 1: Minimum Viable Product (MVP)
Status: [ 📝 QUEUED ]
Goal: Solve the core problem for the first user.
- [ ] 003_core_feature_a
- [ ] 004_core_feature_b

### Phase 2: Growth & Optimization
Status: [ 📝 QUEUED ]
Goal: Scale usage and refine UX.
- [ ] 005_analytics_integration
- [ ] 006_onboarding_flow_v2

---

## Critical Path & Constraints
- Current Blocker: [List any technical or resource bottlenecks]
- Hard Deadlines: [e.g., "Must launch Beta by Sept 1st"]
- Non-Negotiables: [e.g., "Must be 100% offline-first"]

## Project Guardrails (The "Rules")
- Code Quality: All files must stay under 300 lines; use [Specific Pattern] for state management.
- Security: Every database table must have Row Level Security (RLS) policies defined.
- Documentation: No PR merged without an updated Current Task Tracking log.

## Success Metrics (KPIs)
- Metric 1: (e.g., Time to value < 2 minutes)
- Metric 2: (e.g., 99.9% Crash-free users)