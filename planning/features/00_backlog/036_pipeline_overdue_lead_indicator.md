# 036 — Overdue Lead Indicator in Pipeline UI

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`LeadModel.isOverdue` is a computed bool (`nextFollowupAt != null && nextFollowupAt < DateTime.now()`).
`nextFollowupAt` is also stored on the model. Neither is surfaced anywhere in the pipeline UI.
Users have no way to see who needs follow-up without clicking into every lead card.

---

## User Stories
- As the business owner, I want overdue leads to stand out in the pipeline so I know exactly
  who to reach out to first thing in the morning without clicking through each card.
- As the business owner, I want to see when a follow-up is due on a lead row so I can plan
  my day at a glance.

---

## Acceptance Criteria
- [ ] Overdue leads in the list view show a small amber dot (or "OVERDUE" chip) in the status column.
- [ ] Overdue leads in the kanban view show the same amber indicator on their card.
- [ ] The `nextFollowupAt` date is shown as a faint date string on non-overdue leads that have one set.
- [ ] Overdue styling uses `EColors.overdueAmber` (`#F0A500`) — add the token before implementing; do not use a raw hex.
- [ ] Leads with `closed_won` or `closed_lost` status never show the overdue indicator, even if `isOverdue` is true.
- [ ] Leads without `nextFollowupAt` show nothing (no placeholder, no dash).

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Indicator type | Amber dot + date chip | Subtle, consistent with HUD aesthetic |
| Color | `EColors.overdueAmber` (`#F0A500`) | `EColors.warning` is `Colors.yellow` — wrong hue. Add `overdueAmber` as a dedicated token in `lib/utils/constants/colors.dart` before implementing. |
| Location (list) | After status badge in lead row | Doesn't disrupt existing columns |
| Location (kanban) | Bottom of kanban card below last-contact line | Consistent with existing card layout |
| Closed columns in kanban | No overdue indicator on `closed_won` / `closed_lost` | Both statuses appear in the kanban (`_kKanbanColumns`). Showing overdue on a closed lead is misleading — guard with `!lead.isClosed`. |

---

## Scope Control
- [x] Included: Overdue indicator in list view + kanban view
- [x] Included: `nextFollowupAt` date shown on non-overdue leads that have one
- [ ] NOT Included: Sorting by `nextFollowupAt` (separate filter/sort feature)
- [ ] NOT Included: Notification or badge on the tab itself

---

## Implementation Detail

**Files:**
- List view row: `lib/app/modules/widgets/_outreach_lead_row.dart`
- Kanban card: `lib/app/modules/widgets/_outreach_kanban_view.dart`

**Prerequisite:** Add to `lib/utils/constants/colors.dart`:
```dart
static const Color overdueAmber = Color(0xFFF0A500);
```

**List view row** — after the status `_StatusBadge`, add:
```dart
if (lead.isOverdue && !lead.isClosed)
  Container(
    margin: const EdgeInsets.only(left: 6),
    width: 7, height: 7,
    decoration: const BoxDecoration(
      color: EColors.overdueAmber,
      shape: BoxShape.circle,
    ),
  )
else if (lead.nextFollowupAt != null)
  Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Text(
      _formatFollowupDate(lead.nextFollowupAt!),
      style: TextStyle(color: EColors.cyanTintedWhite.withAlpha(102), fontSize: 11),
    ),
  ),
```

**Date helper** (same file, top-level or private):
```dart
String _formatFollowupDate(DateTime dt) {
  final sameYear = dt.year == DateTime.now().year;
  return DateFormat(sameYear ? 'MMM d' : 'MMM d, y').format(dt);
}
```

**Kanban card** (`_outreach_kanban_view.dart`) — same amber dot / faint date treatment, guarded by `!lead.isClosed` to suppress on `closed_won` / `closed_lost` cards.

---

## Edge Cases & QA
- [ ] Lead with `nextFollowupAt` in the future shows date only, no amber.
- [ ] Lead with `nextFollowupAt = null` shows nothing in that slot.
- [ ] Lead with `closed_won` or `closed_lost` status shows no overdue indicator — both statuses appear in the kanban and the guard `!lead.isClosed` must suppress it.
- [ ] `unsubscribed` leads do not appear in the kanban (not in `_kKanbanColumns`) — no extra guard needed, but list view should still respect `!lead.isClosed` for consistency.
- [ ] Date format: `MMM d` (e.g., "Jun 22") in the same calendar year; `MMM d, y` (e.g., "Jun 22, 2025") when the follow-up year differs from the current year.
