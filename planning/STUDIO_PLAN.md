# STUDIO Implementation Plan: [Task Name]

## Lifecycle Metadata
- Status: [ 📝 BACKLOG | 🏗️ ACTIVE | ✅ COMPLETED ]
- Priority: [ P0 - Critical | P1 - High | P2 - Medium | P3 - Low ]
- Lead Agent: [ Planner | Architect | Flutter Subagent ]
- Specs Reference: [e.g., mood_guide.md]

## Objective
Precisely what are we changing? (e.g., "Migrating Auth from Firebase to Supabase").

## Design Decisions (ADR)
Document why we chose a specific path to prevent circular arguments with AI agents later.

| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| UX Pattern | Bottom Sheet | Non-disruptive; keeps user in context of the dashboard. |
| Data Source | Hardcoded Enum | Moods are static; avoids unnecessary API calls or DB overhead. |
| Entry Points | Filter Bar + Settings | Captures users both in-context and during exploration. |

## Scope Control
- [ ] Included: [e.g., Mood-to-Genre mapping, Bottom sheet UI, Settings Tile]
- [ ] NOT Included: [e.g., Ability to custom-map moods, Backend sync for guide preferences]

## Implementation Blueprint
### New & Modified Files    
| File Path | Action | Role/Purpose |
| :--- | :--- | :--- |
| lib/shared/widgets/name.dart | ➕ New | [Describe component] |
| lib/features/... | 📝 Edit | [Describe modification] |

### Widget Spec
Type: [e.g., Get.bottomSheet / Modal]
Structure:
├── Header: [Title]
├── Body:
│   └── ListBuilder (MoodTag.values)
│       ├── Style: [Icon + Color Dot]
│       └── Detail: [Description + Genre Wrap]

### Data Mapping
Hardcoded logic or schema changes here.
- Category A: [Item 1, Item 2]
- Category B: [Item 3, Item 4]

## Acceptance Criteria (Definition of Done)
- [ ] Binary Check: [Condition 1, e.g., Sheet opens when (i) is tapped].
- [ ] Binary Check: [Condition 2, e.g., All 6 moods are displayed].
- [ ] Standards: File length < 300 lines; uses E-Prefix constants.
- [ ] Lifecycle: Move this file to /02_completed and update README.md.

## Verification Plan
- Unit: flutter test tests/unit/[feature]_test.dart
- Manual: [Steps to verify in the Emulator]
- Edge Case: What happens on small screen sizes (iPhone SE)? Ensure the Wrap widget handles overflow.

## Session Log
- [2026-02-18]: Feature initialized by Planner.
- [Timestamp]: [Agent Name] started [Task].

