# 030_booking_widget_system

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [ ] Completed

**Mode:** STUDIO

---

## Overview

Add a booking system so potential clients can schedule a 30-min discovery call directly from
the contact form, and existing clients can schedule a 30-min project check-in from the portal.
Both surfaces share the same availability pool. All state is backed by Supabase; Google Calendar
sync (with auto-generated Google Meet links) and Resend emails are handled via Edge Functions.

**Key decisions:**
- Custom backend (Supabase) — no Calendly/Cal.com dependency
- Google Meet auto-generated per booking (via Calendar API `conferenceData.createRequest`)
- 30-min buffer enforced after every booking
- Booking on contact form is optional (toggle); portal booking is always available
- Cancel/reschedule via email link (token-based, no auth) AND via client portal

---

## User Stories
- As a lead, I want to optionally schedule a call when submitting the contact form so I don't need to wait for an email back.
- As a client, I want to book a project check-in from my portal without emailing Ryan.
- As a lead/client, I want to cancel or reschedule my booking via a link in my confirmation email.
- As admin, I want to set my weekly availability and block time off in the admin panel.

---

## Acceptance Criteria

- [ ] `availability_rules`, `availability_blocks`, and `bookings` tables exist with RLS enabled
- [ ] `get-available-slots` Edge Function returns correct 30-min slots, respecting blocks, existing bookings, and 30-min buffer
- [ ] Contact form has an optional "Schedule a call?" toggle; `BookingWidget` appears when toggled on
- [ ] Submitting contact form with a slot selected creates a `bookings` row and a `contact_submissions` row
- [ ] Confirmation email sent via Resend with Google Meet link + manage link
- [ ] Google Calendar event created for each booking (with Meet link)
- [ ] `/booking/manage?token=xxx` public route allows cancel and reschedule without login
- [ ] Cancel: sets `status = 'cancelled'`, deletes Calendar event, sends cancellation email
- [ ] Reschedule: updates slot, updates Calendar event, sends reschedule email
- [ ] Client portal has a "Book a Check-in" section using same `BookingWidget` (`session_type = project_checkin`)
- [ ] Admin availability panel: set weekly hours + block ad-hoc time
- [ ] Double-booking is prevented (slot re-validated in `create-booking`)
- [ ] All new files stay under 300 lines

---

## Architecture

See plan file for full details. Summary:

### New DB Tables
- `availability_rules` — weekly recurring availability (day_of_week, start_time, end_time)
- `availability_blocks` — admin-blocked ranges
- `bookings` — individual bookings with `cancellation_token`, `google_event_id`, `meet_url`

### New Edge Functions
| Function | Auth |
|---|---|
| `get-available-slots` | Public |
| `create-booking` | Public (leads) / Portal JWT (clients) |
| `manage-booking` | Token-based (cancellation_token) |
| `admin-manage-availability` | adminToken |

### New Flutter Files
- `lib/app/data/models/booking_model.dart`
- `lib/app/data/repositories/booking_repository.dart`
- `lib/app/controllers/booking_controller.dart`
- `lib/app/modules/widgets/booking_widget.dart`
- `lib/app/modules/screens/manage_booking_screen.dart`
- `lib/app/controllers/manage_booking_controller.dart`
- `lib/app/modules/widgets/admin_availability_widget.dart`
- `lib/app/controllers/admin_availability_controller.dart`

### Modified Flutter Files
- `lib/app/modules/screens/contact_screen.dart`
- `lib/app/controllers/contact_controller.dart`
- `lib/app/modules/screens/portal_screen.dart`
- `lib/routes/routes.dart`
- `lib/routes/app_routes.dart`
- `lib/app/modules/screens/admin_screen.dart`

---

## Dependencies
- Existing: `supabase/migrations/` base schema, Resend integration (already used in other functions)
- Google Calendar API credentials (one-time manual setup before deploying create-booking)
- Supabase secrets: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`, `GOOGLE_CALENDAR_ID`

---

## Implementation Order
1. DB migration
2. `get-available-slots` Edge Function
3. `BookingWidget` + `BookingController` + `BookingRepository`
4. `create-booking` Edge Function + contact form wiring
5. `manage-booking` Edge Function + `ManageBookingScreen`
6. Portal booking section
7. Admin availability panel + `admin-manage-availability` Edge Function
8. Seed initial availability rules

---

## Verification
1. Set availability in admin → verify `availability_rules` rows in DB
2. Block time → verify slot disappears from picker
3. Submit contact form with booking → verify DB row, Resend email (with Meet link), Calendar event
4. Cancel via email link → `status = 'cancelled'`, event deleted, cancellation email sent
5. Portal check-in booking → correct `session_type`, same availability respected
6. Race condition: two concurrent bookings for same slot → second fails gracefully
7. Contact form without booking → only `contact_submissions` row, no booking row
