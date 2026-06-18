# 035 — Resend Webhook Open/Click Tracking

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
`outreach_emails` stores `opened_at` and `clicked_at` columns. The email history UI in the
lead detail panel already renders dots for Open / Click / Reply status. But there is no Resend
webhook handler — both columns are always null. Resend can POST events to a URL whenever an
email is opened or a link is clicked. This feature wires that up.

**Note:** Resend does not emit an `email.replied` event. Reply tracking is out of scope for this
feature and requires a separate inbound-parse pipeline.

---

## Prerequisites / Schema Dependencies
The following columns must exist on `outreach_emails` before implementation:
- `resend_id TEXT` — populated when the email is sent via Resend
- `opened_at TIMESTAMPTZ`
- `clicked_at TIMESTAMPTZ`

If any are missing, create a migration before starting: `/migrate add missing outreach_emails tracking columns`.

---

## User Stories
- As the business owner, I want to see which leads actually opened my email so I can prioritize
  follow-ups to people who are already engaged.
- As the business owner, I want to know if someone clicked the booking link without replying so
  I can reach out proactively.

---

## Acceptance Criteria
- [ ] A webhook endpoint exists that accepts POST from Resend with a valid Resend webhook signature.
- [ ] `email.opened` event → finds `outreach_emails` row by `resend_id`, sets `opened_at = now()`.
- [ ] `email.clicked` event → sets `clicked_at = now()` on matching row.
- [ ] Webhook signature is verified using `RESEND_WEBHOOK_SECRET` env var — unauthorized requests return 401.
- [ ] Duplicate `svix-id` delivery → skipped (idempotent, no double-write).
- [ ] Unknown event types → returns `200 { received: true }` (log and skip, never 400/500).
- [ ] Webhook URL is registered in Resend dashboard with `?action=resend-webhook` query param.
- [ ] Email history dots for Open/Click populate after real events.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Endpoint location | New action `resend-webhook` in `admin-outreach-email` | Co-located with email logic; avoids a new edge function |
| Auth | Resend webhook signature via svix HMAC | Industry standard; `RESEND_WEBHOOK_SECRET` already a known pattern |
| Idempotency | Store processed `svix-id` in `outreach_webhook_events`; bail early on duplicate | Per `api_conventions.md` — field-null guard alone fails under concurrent re-delivery |
| `email.replied` | Out of scope — Resend does not emit this event | Would require inbound-parse pipeline (separate feature) |

---

## Scope Control
- [x] Included: `email.opened`, `email.clicked` events
- [x] Included: Webhook signature verification
- [x] Included: svix-id idempotency table
- [ ] NOT Included: `email.replied` — Resend does not support this event
- [ ] NOT Included: Bounce / spam complaint handling
- [ ] NOT Included: Aggregated open-rate dashboard (separate feature if needed)
- [ ] NOT Included: Admin UI changes — dots already render from existing fields

---

## Implementation Detail

**File:** `supabase/functions/admin-outreach-email/index.ts`

The `resend-webhook` action differs from all other actions — it is NOT protected by
`adminToken`. Instead it verifies Resend's webhook signature header. The `adminToken`
check at the top of the function must allow `resend-webhook` through before validation.

**Import:**
```ts
import { Webhook } from 'https://esm.sh/svix@1?target=deno&no-check';
```

**Handler:**
```ts
if (action === 'resend-webhook') {
  const webhookSecret = Deno.env.get('RESEND_WEBHOOK_SECRET');
  if (!webhookSecret) return json({ error: 'Missing webhook secret.' }, 500);

  const svixId = req.headers.get('svix-id') ?? '';
  const svixTimestamp = req.headers.get('svix-timestamp') ?? '';
  const svixSignature = req.headers.get('svix-signature') ?? '';

  try {
    const wh = new Webhook(webhookSecret);
    wh.verify(await req.text(), { 'svix-id': svixId, 'svix-timestamp': svixTimestamp, 'svix-signature': svixSignature });
  } catch {
    return json({ error: 'Invalid signature.' }, 401);
  }

  // Idempotency: skip events already processed
  const { data: existing } = await supabase
    .from('outreach_webhook_events')
    .select('id')
    .eq('svix_id', svixId)
    .maybeSingle();
  if (existing) return json({ received: true });

  try {
    const { type, data } = body;
    const resendId = data?.email_id;
    if (!resendId) return json({ error: 'No email_id.' }, 400);

    const now = new Date().toISOString();
    if (type === 'email.opened') {
      await supabase.from('outreach_emails')
        .update({ opened_at: now }).eq('resend_id', resendId).is('opened_at', null);
    } else if (type === 'email.clicked') {
      await supabase.from('outreach_emails')
        .update({ clicked_at: now }).eq('resend_id', resendId).is('clicked_at', null);
    }
    // Unknown event types: log and skip — never return non-200

    await supabase.from('outreach_webhook_events').insert({ svix_id: svixId, event_type: type });
  } catch (err) {
    console.error('resend-webhook processing error:', err);
    // Return 200 so Resend does not retry a permanent failure
  }

  return json({ received: true });
}
```

**Migration needed for idempotency table:**
```sql
create table public.outreach_webhook_events (
  id uuid primary key default gen_random_uuid(),
  svix_id text not null unique,
  event_type text not null,
  created_at timestamptz not null default now()
);
alter table public.outreach_webhook_events enable row level security;
-- No client access needed — service role only
```

**Env var needed:** `RESEND_WEBHOOK_SECRET` (set in Supabase Edge Function secrets)

**Resend dashboard:** Add webhook pointing to:
```
https://gegwqywgbgzahnftppda.supabase.co/functions/v1/admin-outreach-email?action=resend-webhook
```
Events to enable: `email.opened`, `email.clicked`

---

## Edge Cases & QA
- [ ] Duplicate `svix-id` delivery → early return before any DB write.
- [ ] `resend_id` not found → no rows updated, returns `200 { received: true }`.
- [ ] Invalid signature → returns 401 immediately.
- [ ] DB error during update → caught, logs error, still returns `200` (prevents Resend retries on permanent failures).
- [ ] Unknown event type (e.g., `email.bounced`) → logs and skips, returns `200`.

## Test Plan
1. Use the Resend dashboard **Webhooks → Replay** button to fire test `email.opened` / `email.clicked` events at the deployed function.
2. Alternatively, use `svix play` to forward live events to a local tunnel during development.
3. Fire the same event twice and confirm the `outreach_webhook_events` table deduplicates it (row count stays at 1).
4. Send a request with a tampered signature and confirm 401.
