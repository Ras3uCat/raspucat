# 003_ui_audit_fixes / 005_polish

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
Nice-to-have upgrades that improve perceived quality and engagement. None of these are
blockers — implement after 001–004 are complete and approved.

---

## User Stories
- As a visitor, I want to see where I am on the page via a scroll progress indicator.
- As a visitor, I want project images to load gracefully instead of popping in.
- As a visitor, I want to filter projects by technology so I can find relevant work.
- As a potential client, I want to read testimonials to build trust.

---

## Acceptance Criteria (Binary Pass/Fail)

### Scroll Progress Indicator
- [ ] A thin horizontal bar appears fixed at the top of the viewport.
- [ ] Bar fills left-to-right in `EColors.primary` (cyan) as the user scrolls down.
- [ ] Bar is not visible on mobile (too small to be useful).
- [ ] Uses existing `ScrollController` — no new controller needed.

### Skeleton Loaders (Project Images)
- [ ] While a carousel image is loading, a shimmer placeholder is shown.
- [ ] Shimmer colors use `EColors.shimmerDark` / `EColors.shimmerHighlight` (already defined).
- [ ] Transition from shimmer to image is smooth (fade-in).
- [ ] Skeleton matches the aspect ratio of the image container.

### Project Filtering
- [ ] Above or below the carousel, a row of technology filter chips is displayed.
- [ ] Tapping a chip filters the carousel to show only projects using that technology.
- [ ] "ALL" chip resets the filter.
- [ ] Active filter chip is highlighted with `EColors.primary` background.
- [ ] Chips are derived from the existing `technologies` lists in `project_data.dart`
      (no new data needed — deduplicated automatically).
- [ ] Filter state is managed in an existing or new GetX controller.

### Testimonials Section
- [ ] A Testimonials section exists (can be placeholder copy initially).
- [ ] Each testimonial shows: quote, client name, company/project context.
- [ ] Displayed as a horizontal carousel or stacked cards.
- [ ] Uses neon card style consistent with project cards.
- [ ] Section is skippable — hidden if testimonials list is empty (data-driven).

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Progress bar position | Fixed top, above navbar | Visible without interfering with content |
| Progress bar height | 2–3px | Subtle; does not distract |
| Skeleton shimmer | Existing shimmer constants | Avoids adding new colors |
| Filter chip style | Neon bordered pill, matches tech tags in project detail | Reuses existing widget style |
| Filter controller | New `ProjectFilterController` or extend existing carousel controller | Keep filter state separate from carousel scroll state |
| Testimonials data | Static `List<TestimonialModel>` in `lib/app/data/` | No backend needed for MVP |
| Testimonials placeholder | Empty list hides section | Avoids showing blank section |

---

## Implementation Detail
**Files created:**
- `lib/common/widgets/scroll_progress_bar.dart`
- `lib/common/widgets/shimmer_loader.dart` (if not already exists)
- `lib/app/modules/widgets/project_filter_chips.dart`
- `lib/app/controllers/project_filter_controller.dart`
- `lib/app/data/models/testimonial_model.dart`
- `lib/app/data/projects/testimonial_data.dart`
- `lib/app/modules/screens/testimonials_screen.dart`

**Files modified:**
- `lib/app/modules/screens/home_screen.dart` — add scroll bar, testimonials section
- `lib/app/modules/screens/projects_screen.dart` — add filter chips above carousel
- `lib/app/modules/widgets/projects_carousel.dart` — connect to filter controller
- `lib/app/modules/widgets/project_screen.dart` — add shimmer to image loading
- `lib/bindings.dart` — register `ProjectFilterController`

---

## Edge Cases & QA
- [ ] Filter with no matching projects shows an empty state message (not a blank carousel).
- [ ] Shimmer does not flash on fast connections (minimum display time: 300ms).
- [ ] Scroll progress bar resets to 0 if user navigates to a new route.
- [ ] Testimonials section does not render at all if `testimonialData` list is empty.
- [ ] Filter chips wrap gracefully on mobile if there are many unique technologies.
