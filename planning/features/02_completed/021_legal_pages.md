# 021 — Legal Pages (Terms & Conditions + Privacy Policy)

## Status
- [x] Backlog (Draft)
- [x] Approved
- [x] In Progress
- [x] Completed

**Mode: STUDIO**

---

## Overview

Raspucat collects payment information (Stripe), stores client data (Supabase), and operates
a client portal — all of which require legally visible Terms & Conditions and Privacy Policy
pages. These are also required by Stripe before going live with payment collection.

Each document lives at its own route, is accessible from the site footer, and is styled
consistently with the existing dark/neon brand.

Note: Raspucat currently hosts BingeQuest's legal pages at separate routes. The Raspucat-specific
legal pages are distinct and cover the web development service business (plans, payments, portal).

---

## Routes

| Page | Route |
|:-----|:------|
| Terms & Conditions | `/terms` |
| Privacy Policy | `/privacy` |

Both routes should return a `404` if navigation is somehow misconfigured.

---

## Content Scope

### Terms & Conditions — Key Sections
1. Acceptance of Terms
2. Services Provided (web development, portal access, module add-ons)
3. Payment Terms (deposit, final balance, Stripe processing)
4. Refund & Cancellation Policy
5. Intellectual Property (work product ownership on handover vs. management plan)
6. Client Responsibilities (content, domain access, approvals)
7. Limitation of Liability
8. Governing Law
9. Changes to Terms
10. Contact

### Privacy Policy — Key Sections
1. What We Collect (name, email, payment info via Stripe, portal activity)
2. How We Use It (project delivery, billing, communications)
3. Third-Party Services (Stripe, Supabase, hosting providers)
4. Data Retention
5. Your Rights (access, deletion, correction)
6. Cookies
7. Contact

---

## UI Design

- **Layout:** Standalone screen — no `SectionContainer` stack, no parallax.
- **Header:** Small neon site logo/wordmark linking back to `/` home.
- **Body:** Single scrollable column, max-width ~760px, centered.
- **Typography:** `textTheme.bodyMedium` for body, `textTheme.titleMedium` for section headings.
  All on `EColors.backgroundDark` with `EColors.textSecondary` body text.
- **Footer:** Standard `SiteFooter` component.
- **Back link:** `← Back to raspucat.com` text button at top left.

---

## User Stories

- As a prospective client, I want to read the Terms before entering payment details.
- As a privacy-conscious visitor, I want to know what data is collected and how it's used.
- As a Stripe reviewer, I need publicly accessible T&C and Privacy Policy URLs before
  the account can process live payments.

---

## Acceptance Criteria

### Routing
- [ ] `/terms` renders `TermsScreen` via `AppRoutes`.
- [ ] `/privacy` renders `PrivacyScreen` via `AppRoutes`.
- [ ] Both routes are accessible without authentication.
- [ ] Footer links to both pages from any page on the site.

### Screen Structure
- [ ] Shared `_LegalScreen` base widget accepts `title` + `List<_LegalSection>` content.
- [ ] `_LegalSection` model: `heading` (String) + `body` (String).
- [ ] Max-width 760px content column, centered horizontally.
- [ ] Back-to-home link at top left (`← raspucat.com`).
- [ ] `SiteFooter` at the bottom.

### Content
- [ ] All T&C sections present (10 sections listed above).
- [ ] All Privacy Policy sections present (7 sections listed above).
- [ ] Content stored as `const` data — no hardcoded strings in widgets.
- [ ] Placeholder company details (name, email, jurisdiction) marked with `// TODO: legal review`.

### Style
- [ ] Background: `EColors.backgroundDark`.
- [ ] Body text: `EColors.textSecondary`, line height 1.7.
- [ ] Section headings: `EColors.textWhite`, `fontWeight.w600`.
- [ ] Page title: `NeonText` matching other section headings.
- [ ] No horizontal overflow at any viewport width.

---

## Files to Create
- `lib/app/modules/screens/terms_screen.dart`
- `lib/app/modules/screens/privacy_screen.dart`
- `lib/app/data/content/legal_content.dart` — const content data

## Files to Modify
- `lib/routes/app_routes.dart` — add `/terms`, `/privacy` route constants
- `lib/routes/routes.dart` — add `GetPage` entries
- `lib/common/widgets/footer/site_footer.dart` — add T&C + Privacy links
- `lib/utils/constants/exports.dart` — export new screens

---

## Notes

- Legal copy should be reviewed by a qualified professional before going live.
- Stripe requires these pages to be live and linked before enabling live payment mode.
- Keep both screens under 300 lines — extract shared `_LegalScreen` scaffold if needed.
