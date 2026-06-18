---
name: convert-lead
description: Converts a qualified outreach lead to a paying client. Creates a Stripe Checkout
  deposit session, a quote record, a Supabase Auth portal user, and sends the client a conversion
  email with deposit link and 24-hour magic login link. Run after prepare-reply once the prospect
  has verbally agreed to move forward. Trigger phrases include "convert lead", "convert [company]
  to a client", "they want to move forward", "close [company]", "run convert-lead", or any request
  to formally convert a prospect after a successful call.
---

# Convert Lead to Client

**Pipeline position:** `prepare-lead` → `prepare-reply` → **`convert-lead`** → `client-delivery`

Run this skill after a successful discovery call when the prospect has verbally agreed to move
forward and you have confirmed: plan tier, module selection, setup fee, billing cycle, and any
management add-on.

---

## When to Use

The system does not enforce a required lead status — any lead with a valid email address can be
converted. However, best practice is:
- Call is complete and prospect has verbally agreed
- You have a confirmed setup fee (negotiate before converting, not after)
- Lead has an email address stored in Supabase (if not, add it first — conversion will fail without it)

Do **not** convert if a quote already exists for this lead. Check Admin → Quotes and filter by
the lead's email before proceeding to avoid creating duplicate quotes.

---

## Inputs (Bottom Sheet Fields)

| Field | Required | Notes |
|---|---|---|
| Plan tier | Yes | Select from available plans |
| Module IDs | No | Multi-select; leave empty for plan defaults |
| Management option | No | Ongoing management add-on if sold |
| Billing cycle | No | Monthly or annual for recurring fees |
| Setup total (cents) | Yes | Negotiated total — deposit is auto-set to 50% |

---

## What This Skill Does

**Input:** Lead record (pulled by leadId from the admin panel)

**Output:**
1. Quote record created in `quotes` table with status `pending`, `portal_stage: awaiting_deposit`
2. Stripe Checkout Session created for the deposit (50% of setup total)
3. Supabase Auth user created for the client's email
4. 24-hour magic login link generated for the client portal
5. Conversion email sent via Resend with deposit link + magic link
6. Lead status updated to `closed_won`

---

## Steps

1. In admin panel → Pipeline → find the lead → open the detail panel
2. Verify the lead has an email address. If not, add it before proceeding.
3. Check Admin → Quotes — search the client's email. If a quote already exists, do not convert again.
4. Click "Convert to Client" button (bottom of the Actions section)
5. Bottom sheet — fill in all fields:
   - Plan tier (required)
   - Modules that apply (optional)
   - Management add-on if sold (optional)
   - Billing cycle if recurring fees apply (optional)
   - Setup total in dollars — confirm the negotiated number
6. Click "Convert" → loading spinner → success confirmation
7. Lead moves to `closed_won` column in the pipeline view
8. Quote appears in Admin → Quotes with status `pending / awaiting_deposit`
9. Client receives conversion email with:
   - Deposit link (Stripe Checkout, 50% of setup total)
   - Portal magic login link (expires in 24 hours)

---

## What Comes Next

- Client pays deposit → Stripe webhook fires → `portal_stage` advances to `onboarding_discovery`
- Client fills discovery form in the portal (pre-populated from `/prepare-lead` audit fields)
- Admin runs `/client-delivery` to kick off the build pipeline

---

## Edge Cases

**Price negotiation after the call:**
Adjust the setup total in the bottom sheet before clicking Convert. Once converted, the deposit
amount is locked in Stripe. To change it post-conversion, update the quote in Admin → Quotes
and manually create a new Stripe Checkout Session — do not reconvert.

**No reports / lead not yet prepared:**
Can still convert. The quote will be created without audit data. Run `/prepare-lead` after
conversion if intelligence reports are needed for onboarding.

**Lead has no email address:**
The edge function returns a 400 error. Add the email to the lead record in the admin panel
first, then retry conversion.

**Re-converting an already-converted lead:**
The edge function does not block duplicate conversions. Always check Admin → Quotes for an
existing quote before converting. A second conversion creates an orphan quote and a second
Stripe Checkout Session, and sends the client a second conversion email.

**Magic link expired (client didn't log in within 24 hours):**
Go to Admin → Clients → find the client → click "Resend Login Link." This generates a new
magic link and sends it via email. The deposit link does not expire.

**Conversion failed mid-flight (orphan quote):**
If the Stripe Checkout creation fails after the quote is inserted, Admin → Quotes will show a
`pending` quote with no deposit URL. Delete the orphan quote record, then retry the full
conversion. Do not attempt to patch the quote manually.

**Auth user already exists (re-convert or duplicate email):**
If the client's email is already in Supabase Auth, user creation will fail silently. The
function continues and falls back to sending the portal URL instead of a magic link. The client
will receive the email but will need to request a login link manually from the portal login page.

**Conversion email not received:**
Email delivery is fire-and-forget. The edge function returns success even if Resend fails.
If the client reports not receiving the email: (1) check Resend dashboard for delivery status,
(2) resend manually from Admin → Clients → "Resend Conversion Email" if that action exists,
or (3) send the deposit URL and portal URL to the client directly.
