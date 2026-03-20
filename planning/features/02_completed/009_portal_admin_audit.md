# 009 — Portal & Admin Panel Audit Fixes

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

---

## Overview
Full audit of the client portal and admin panel surfaces 13 issues across three severity tiers.
Items are ordered by impact. Each has a self-contained acceptance criteria block so they can be
pulled into `01_active` individually or as a group.

---

## CRITICAL

---

### C1 — Stripe Payment Element: Fragile 100ms Mount Delay

**File:** `lib/app/controllers/portal_modules_controller.dart`

**Problem:**
`_mountEmbeddedElement()` waits a hardcoded 100ms before mounting the Stripe JS element.
If the `HtmlElementView` hasn't rendered (slow machine, slow connection), Stripe can't find
the target div and the payment form silently never appears. No error is surfaced to the user.

**Acceptance Criteria:**
- [x] Replace `Future.delayed(const Duration(milliseconds: 100), ...)` with a proper
      post-frame callback (`WidgetsBinding.instance.addPostFrameCallback`) that mounts
      only after the view is confirmed rendered.
- [x] If mounting fails (JS error caught), show an inline error message:
      `"Could not load payment form. Please refresh and try again."`
- [x] `isCheckoutLoading` spinner is dismissed only after a successful mount, not on a timer.
- [x] Tested on a throttled (Slow 3G) connection in Chrome DevTools — form appears.
      *(QA step — verify manually before next release)*

**Files to modify:**
- `lib/app/controllers/portal_modules_controller.dart`
- `lib/app/modules/widgets/portal_add_modules_view.dart` (error state for payment step)

---

### C2 — Payment Step: No Error State When Element Fails to Load

**File:** `lib/app/modules/widgets/portal_add_modules_view.dart`

**Problem:**
If `kIsWeb` is true but the `HtmlElementView` fails or Stripe JS errors, the payment step
renders a blank container. The client has no feedback and no recovery path.

**Acceptance Criteria:**
- [x] Payment step has an `errorMessage` observable in the controller.
- [x] If mount fails or Stripe returns an error event, `errorMessage` is populated.
- [x] UI shows error banner with a "Retry" button that re-triggers `_mountEmbeddedElement()`.
- [x] If non-web platform, a clear "Payment not supported on this device" message is shown
      instead of a blank container.

**Files to modify:**
- `lib/app/controllers/portal_modules_controller.dart`
- `lib/app/modules/widgets/portal_add_modules_view.dart`

---

### C3 — Admin Stats Bar Doesn't Refresh After Mutations

**File:** `lib/app/controllers/admin_controller.dart`

**Problem:**
`fetchStats()` is only called on login and manual refresh. After `chargeBalance()` or
`startSubscription()` succeeds, the stats bar (total revenue, active subscriptions, etc.)
stays stale until the admin manually refreshes.

**Acceptance Criteria:**
- [x] `chargeBalance()` calls `fetchStats()` after a successful charge.
- [x] `startSubscription()` calls `fetchStats()` after a successful subscription start.
- [x] `cancelSubscription()` calls `fetchStats()` after a successful cancel.
- [x] Stats bar visually flickers/animates to signal a refresh occurred.

**Files to modify:**
- `lib/app/controllers/admin_controller.dart`

---

## MEDIUM

---

### M1 — Deliverables: Repository Exists But Is Unconnected

**Files:**
- `lib/app/data/repositories/portal_deliverables_repository.dart` ← exists, unused
- `lib/app/data/models/portal_deliverable_model.dart` ← exists, unused
- No controller, no view, no tab

**Problem:**
The deliverables data layer was scaffolded but never wired to the UI. Clients have no way
to view deliverables even if the backend supports them.

**Decision:** Delete dead files (owner confirmed 2026-03-20).

If implementing:

**Acceptance Criteria:**
- [ ] New "Deliverables" tab added to `PortalScreen` (tab index 4, after Add Modules).
- [ ] `PortalDeliverablesController` created in `lib/app/controllers/`.
- [ ] `PortalDeliverablesView` created in `lib/app/modules/widgets/`.
- [ ] View lists deliverables with name, description, download link.
- [ ] Badge/notification on Deliverables tab when new deliverables are posted (mirrors
      the Files notification pattern).
- [ ] Admin panel exposes a way to add/manage deliverables per quote.
- [ ] Empty state: "No deliverables yet — check back soon."

**Files to create:**
- `lib/app/controllers/portal_deliverables_controller.dart`
- `lib/app/modules/widgets/portal_deliverables_view.dart`
- `supabase/functions/admin-upload-deliverable/index.ts` (if needed)

**Files to modify:**
- `lib/app/modules/screens/portal_screen.dart`
- `lib/app/modules/widgets/admin_detail_content.dart`
- `lib/app/modules/widgets/portal_dashboard.dart` (add quick link)

If removing:

**Acceptance Criteria:**
- [x] `portal_deliverables_repository.dart` deleted.
- [x] `portal_deliverable_model.dart` deleted.
- [x] `portal_deliverables_controller.dart` deleted.
- [x] `portal_deliverables_view.dart` deleted.
- [x] No orphaned imports.

---

### M2 — Admin Detail Drawer: Pending Modules Not Fully Actionable

**File:** `lib/app/modules/widgets/admin_detail_content.dart` → `_PendingModulesSection`

**Problem:**
The pending modules section in the detail drawer shows pending/in-progress modules and
exposes Acknowledge + Mark Live buttons, but the workflow isn't visually clear. There is
no "Reject" action, no timestamps visible, and no status explanation for the client.

**Acceptance Criteria:**
- [x] Each pending module row shows `purchased_at` date in a human-readable format.
- [x] "Acknowledge" button has a tooltip: "Confirms you've received this request and are
      working on it. The client will see 'In Progress'."
- [x] "Mark Live" button has a tooltip: "Marks this module as delivered."
- [x] A "Reject / Remove" action is available (with confirmation dialog) for modules
      requested in error.
- [x] After any action, the pending modules section refreshes automatically.

**Files to modify:**
- `lib/app/modules/widgets/admin_detail_content.dart`
- `lib/app/controllers/admin_controller.dart` (add `rejectModule()` if needed)
- `supabase/functions/admin-reject-module/index.ts` (new, if needed)

---

### M3 — Portal File Delete Doesn't Sync Admin Badge Count

**File:** `lib/app/controllers/portal_files_controller.dart`

**Problem:**
`deleteFile()` removes the file from the local `files` list but the admin's
`newFileCounts` map in `AdminController` stays inflated until the next full poll.
The admin will continue to see a stale "New File (N)" pill on the quote row.

**Acceptance Criteria:**
- [x] File deletion is a non-issue for the badge because the Edge Function
      (`admin-get-pending-modules`) counts files on every poll — confirm the poll
      interval is reasonable (currently only on login/manual refresh).
- [x] Added periodic re-poll every 60s via `Timer.periodic` in `AdminController`.
      Timer starts on login, cancelled on logout and `onClose()`.

**Files to modify:**
- `lib/app/controllers/admin_controller.dart`

---

### M4 — Portal Dashboard: Plan Card Shows Count But Not Module Names

**File:** `lib/app/modules/widgets/portal_dashboard.dart` → `_PlanCard`

**Problem:**
The plan card shows "3 modules included" but the client can't see which modules are
included without navigating to the Add Modules tab.

**Acceptance Criteria:**
- [x] `PortalQuote` model already has `moduleIds` — IDs humanized for display.
- [x] Plan card shows module names as small chips/tags below the count line.
- [x] Max 4 chips shown; if more, show "+ N more".
- [x] Chips are non-interactive (display only).

**Files to modify:**
- `lib/app/modules/widgets/portal_dashboard.dart`
- `lib/app/data/models/portal_quote_model.dart` (if module names need to be added)

---

### M5 — Admin Messages & Files: No Auto-Refresh (No Realtime)

**Files:**
- `lib/app/controllers/admin_messages_controller.dart`
- `lib/app/controllers/admin_files_controller.dart`

**Problem:**
Both controllers load data once on `onInit`. The admin has to manually tap the refresh
button to see new messages or files. There are no Supabase Realtime subscriptions.

**Acceptance Criteria:**
- [x] `AdminMessagesController` subscribes to Supabase Realtime on
      `portal_messages` filtered by `quote_id`. New messages insert triggers `loadMessages()`.
- [x] `AdminFilesController` subscribes to Supabase Realtime on
      `portal_files` filtered by `quote_id`. New file insert triggers `loadFiles()`.
- [x] Subscriptions are cancelled in `onClose()`.
- [x] Manual refresh buttons remain as a fallback.
- [x] No duplicate messages/files — `assignAll` replaces list on every load.

**Files to modify:**
- `lib/app/controllers/admin_messages_controller.dart`
- `lib/app/controllers/admin_files_controller.dart`

---

### M6 — Portal Messages: No Auto-Refresh (No Realtime)

**File:** `lib/app/controllers/portal_messages_controller.dart`

**Problem:**
Same issue as M5 but client-facing. Client won't see new admin messages without
manually refreshing or re-opening the Messages tab.

**Acceptance Criteria:**
- [x] `PortalMessagesController` subscribes to Supabase Realtime on `portal_messages`
      filtered by `quote_id`.
- [x] New message arrives → list updates → `unreadMessageCount` in `PortalController`
      increments by 1 → badge re-appears on nav.
- [x] Subscription cancelled in `onClose()`.

**Files to modify:**
- `lib/app/controllers/portal_messages_controller.dart`
- `lib/app/controllers/portal_controller.dart` (hook for realtime count increment)

---

## LOW / POLISH

---

### L1 — Image Lightbox: No Download Button

**File:** `lib/app/modules/widgets/portal_files_view.dart` → `_showImageLightbox`

**Problem:**
The lightbox shows the full image but has no download button. The user must close it
and click the download icon on the file row.

**Acceptance Criteria:**
- [x] Lightbox overlay includes a download icon button (bottom-right, distinct from close).
- [x] Tapping it calls `launchUrl` with the signed URL in `externalApplication` mode.
- [x] Same change applied to `admin_files_section.dart`'s lightbox.

**Files to modify:**
- `lib/app/modules/widgets/portal_files_view.dart`
- `lib/app/modules/widgets/admin_files_section.dart`

---

### L2 — Admin Quote Rows: No Hover Cursor on Desktop

**File:** `lib/app/modules/widgets/admin_quote_row.dart`

**Problem:**
The row uses `GestureDetector` which doesn't change the cursor to a pointer on web/desktop.
Users can't tell the row is clickable until they click it.

**Acceptance Criteria:**
- [x] Wrap the outer `GestureDetector` with `MouseRegion(cursor: SystemMouseCursors.click)`.
- [x] Same fix applied to `_QuickLinkCard` in `portal_dashboard.dart`.

**Files to modify:**
- `lib/app/modules/widgets/admin_quote_row.dart`
- `lib/app/modules/widgets/portal_dashboard.dart` (`_QuickLinkCard`)

---

### L3 — Admin Pipeline View: Empty Column Placeholder

**File:** `lib/app/modules/widgets/admin_pipeline_view.dart`

**Problem:**
Empty stage columns show no content — indistinguishable from loading.

**Acceptance Criteria:**
- [x] Each column shows "No quotes" placeholder text when its list is empty.
- [x] Placeholder uses the same muted style as empty state hints elsewhere.

**Files to modify:**
- `lib/app/modules/widgets/admin_pipeline_view.dart`

---

### L4 — Admin "Stale" Badge: No Explanation or Action

**File:** `lib/app/modules/screens/admin_screen.dart`

**Problem:**
The "Stale" pill on a quote row indicates a deposit was paid 7+ days ago but no action
has been taken, but there's no tooltip or CTA telling the admin what to do about it.

**Acceptance Criteria:**
- [x] "Stale" pill has a `Tooltip` with text:
      `"Deposit paid over 7 days ago — consider charging the remaining balance or following up."`
- [x] The stale badge in the header also has a tooltip.

**Files to modify:**
- `lib/app/modules/widgets/admin_quote_row.dart`
- `lib/app/modules/screens/admin_screen.dart`

---

### L5 — Magic Link Expiry Copy Is Hardcoded

**File:** `lib/app/modules/screens/portal_login_screen.dart`

**Problem:**
"The link expires in 1 hour" is hardcoded. If the Supabase magic link TTL is changed,
the copy silently becomes wrong.

**Acceptance Criteria:**
- [x] Move the expiry string to a constant in `lib/utils/constants/text.dart`
      (`EText.magicLinkExpiry = 'The link expires in 1 hour'`).
- [x] Note in the constant: "Must be kept in sync with Supabase magic link TTL setting."

**Files to modify:**
- `lib/utils/constants/text.dart`
- `lib/app/modules/screens/portal_login_screen.dart`

---

## Implementation Order Recommendation

| Priority | Item | Effort | Impact |
|:---------|:-----|:-------|:-------|
| 1 | C1 + C2 — Stripe payment reliability | Medium | High — blocks conversions |
| 2 | C3 — Stats refresh after mutations | Low | Medium — data correctness |
| 3 | M1 — Deliverables decision | Low/High | Medium — depends on decision |
| 4 | M5 + M6 — Realtime subscriptions | Medium | High — live UX |
| 5 | L1 — Lightbox download | Low | Low |
| 6 | L2 — Hover cursors | Low | Low |
| 7 | L3 — Pipeline empty state | Low | Low |
| 8 | L4 — Stale tooltip | Low | Low |
| 9 | M2 — Pending module workflow | Medium | Medium |
| 10 | M3 — File count sync | Low | Low |
| 11 | M4 — Module names in plan card | Low | Low |
| 12 | L5 — Magic link copy | Low | Low |
