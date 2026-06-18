# 040 — Pipeline Company Name Search

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

## Mode
FLOW

---

## Overview
The pipeline only filters by industry dropdown. As the lead list grows, finding a specific
company requires scrolling through all leads. A search input that filters by company name
(and optionally city) would make the pipeline usable at scale.

---

## User Stories
- As the business owner, I want to type a company name and immediately see matching leads so
  I don't have to scroll through 200 leads to find one.
- As the business owner, when no companies match my search, I want to see a clear empty state
  so I know my search worked but returned nothing.

---

## Acceptance Criteria
- [ ] A search TextField appears in the pipeline header, next to the industry filter.
- [ ] Typing filters `ctrl.leads` by `companyName.toLowerCase().contains(query.toLowerCase())`.
- [ ] Search is applied on top of the existing industry filter (both filters active simultaneously).
- [ ] Clear button (×) appears when query is non-empty; clears search on tap.
- [ ] Works in both list view and kanban view.
- [ ] Empty search → all leads shown (same as current behavior).
- [ ] When search returns 0 matches, show inline "No companies match '[query]'" text in the lead list area.
- [ ] Search state is local to the widget (no controller change needed).

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| State location | `StatefulWidget` local state (`TextEditingController` + `setState`) | Small local state; avoids persisting search across tab switches |
| Filter scope | `companyName` only | Covers 95% of use cases; city search can be added later |
| UI placement | Next to industry filter in pipeline header | Consistent with existing filter pattern |
| Debounce | Not applied | Single-user app; instantaneous filtering is acceptable at current scale |

---

## Scope Control
- [x] Included: Company name search with clear button
- [x] Included: Combined filtering with existing industry filter
- [x] Included: Empty state message when 0 results match
- [ ] NOT Included: Debounce (single-user app, instantaneous filtering is acceptable)
- [ ] NOT Included: City, score range, or status filters
- [ ] NOT Included: Search across notes or contact info fields
- [ ] NOT Included: Persistent search state across sessions

---

## Implementation Detail

**File:** `lib/app/modules/pipeline/views/_pipeline_header.dart` (confirm exact path before editing)

Add a `TextEditingController _search` to the pipeline widget's state. Call `_search.dispose()` in the widget's `dispose()` method. In the leads list/kanban rendering, apply an additional filter:

```dart
final query = _search.text.toLowerCase();
final filtered = ctrl.filteredLeadsByStatus.where(
  (l) => query.isEmpty || l.companyName.toLowerCase().contains(query),
).toList();
```

Show an empty state when `filtered.isEmpty && query.isNotEmpty`:
```dart
if (filtered.isEmpty && query.isNotEmpty)
  Center(child: Text("No companies match '$query'", style: ETextStyles.hint))
```

In the header row, add after the industry filter:
```dart
SizedBox(
  width: ESizes.searchFieldWidth, // define constant: 200
  child: TextField(
    controller: _search,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      hintText: 'Search companies...',
      hintStyle: ETextStyles.hint,
      suffixIcon: _search.text.isNotEmpty
        ? GestureDetector(
            onTap: () { _search.clear(); setState(() {}); },
            child: const Icon(Icons.close, color: EColors.softGrey, size: 14),
          )
        : null,
      // HUD-style border and background — match existing industry filter decoration
    ),
  ),
)
```

**Lifecycle:**
```dart
@override
void dispose() {
  _search.dispose();
  super.dispose();
}
```

**Before implementing:** Confirm the exact getter name on the pipeline controller (assumed `filteredLeadsByStatus`) and verify `ESizes.searchFieldWidth` is defined or add it to the constants file.

---

## Edge Cases & QA
- [ ] Query with special chars (e.g., "&", "'") → `contains` handles safely.
- [ ] Switching between list/kanban while search active → search persists within same widget instance.
- [ ] Industry filter + search both active → leads must match both.
- [ ] Kanban view: filtered leads still go into correct status columns.
- [ ] Leads reload/refresh while search active → filter re-applies correctly against new data.
- [ ] Very long company names → card truncates without overflow in kanban view.
