// Edge Function: manage-booking
// Token-based (no user auth). Allows cancel or reschedule via cancellation_token.
// Body: { token, action: 'cancel' | 'reschedule', newStartAt? }

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { getAvailableSlots, SLOT_DURATION_MS, formatInOwnerTz } from '../_shared/booking-slots.ts';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const FROM_EMAIL = Deno.env.get('RESEND_FROM_EMAIL') ?? 'onboarding@resend.dev';
const SITE_URL = Deno.env.get('SITE_URL') ?? 'https://raspucat.com';

const SESSION_LABELS: Record<string, string> = {
  discovery_call: 'Discovery Call',
  project_checkin: 'Project Check-In',
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function getGoogleAccessToken(): Promise<string> {
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: Deno.env.get('GOOGLE_CLIENT_ID')!,
      client_secret: Deno.env.get('GOOGLE_CLIENT_SECRET')!,
      refresh_token: Deno.env.get('GOOGLE_REFRESH_TOKEN')!,
      grant_type: 'refresh_token',
    }),
  });
  const { access_token } = await res.json();
  return access_token;
}

async function deleteCalendarEvent(googleEventId: string, accessToken: string): Promise<void> {
  const calendarId = Deno.env.get('GOOGLE_CALENDAR_ID') ?? 'primary';
  const res = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events/${googleEventId}`,
    { method: 'DELETE', headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (!res.ok && res.status !== 404) console.error('Calendar delete error:', res.status);
}

async function updateCalendarEvent(
  googleEventId: string,
  accessToken: string,
  startAt: string,
  endAt: string,
): Promise<void> {
  const calendarId = Deno.env.get('GOOGLE_CALENDAR_ID') ?? 'primary';
  const res = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events/${googleEventId}`,
    {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        start: { dateTime: startAt, timeZone: 'UTC' },
        end: { dateTime: endAt, timeZone: 'UTC' },
      }),
    },
  );
  if (!res.ok) console.error('Calendar update error:', res.status, await res.text());
}

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) return;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { token, action, newStartAt } = await req.json();

    if (!token || !['cancel', 'reschedule'].includes(action)) {
      return json({ error: 'token and action (cancel|reschedule) required.' }, 400);
    }

    const { data: booking, error: lookupError } = await supabase
      .from('bookings')
      .select('id, session_type, start_at, end_at, status, name, email, google_event_id, meet_url, cancellation_token')
      .eq('cancellation_token', token)
      .single();

    if (lookupError || !booking) return json({ error: 'Booking not found.' }, 404);
    if (booking.status === 'cancelled') return json({ error: 'Booking is already cancelled.' }, 409);

    const label = SESSION_LABELS[booking.session_type] ?? booking.session_type;

    if (action === 'cancel') {
      await supabase.from('bookings').update({ status: 'cancelled' }).eq('id', booking.id);

      if (booking.google_event_id) {
        try {
          const accessToken = await getGoogleAccessToken();
          await deleteCalendarEvent(booking.google_event_id, accessToken);
        } catch (err) {
          console.error('Calendar delete error (non-fatal):', err);
        }
      }

      const html = `
        <div style="background:#000612;color:#e0e0e0;font-family:Inter,sans-serif;padding:40px 24px;max-width:600px;margin:0 auto">
          <h2 style="color:#ef5858;margin-bottom:8px">Booking cancelled</h2>
          <p>Hi ${booking.name}, your <strong>${label}</strong> on ${formatInOwnerTz(new Date(booking.start_at))} has been cancelled.</p>
          <p>If you'd like to reschedule, <a href="${SITE_URL}/#contact" style="color:#58e3ef">visit the contact page</a>.</p>
        </div>`;
      await sendEmail(booking.email, `${label} cancelled`, html);
      return json({ success: true, action: 'cancelled' });
    }

    // Reschedule
    if (!newStartAt) return json({ error: 'newStartAt required for reschedule.' }, 400);

    const newStart = new Date(newStartAt);
    if (isNaN(newStart.getTime())) return json({ error: 'Invalid newStartAt.' }, 400);

    const dateStr = newStartAt.slice(0, 10);
    const available = await getAvailableSlots(supabase, dateStr);
    const isAvailable = available.some((s) => s.getTime() === newStart.getTime());
    if (!isAvailable) return json({ error: 'New slot is not available.' }, 409);

    const newEnd = new Date(newStart.getTime() + SLOT_DURATION_MS).toISOString();

    await supabase.from('bookings').update({
      start_at: newStartAt,
      end_at: newEnd,
      status: 'confirmed',
    }).eq('id', booking.id);

    if (booking.google_event_id) {
      try {
        const accessToken = await getGoogleAccessToken();
        await updateCalendarEvent(booking.google_event_id, accessToken, newStartAt, newEnd);
      } catch (err) {
        console.error('Calendar update error (non-fatal):', err);
      }
    }

    const manageUrl = `${SITE_URL}/booking/manage?token=${booking.cancellation_token}`;
    const html = `
      <div style="background:#000612;color:#e0e0e0;font-family:Inter,sans-serif;padding:40px 24px;max-width:600px;margin:0 auto">
        <h2 style="color:#58e3ef;margin-bottom:8px">Booking rescheduled</h2>
        <p>Hi ${booking.name}, your <strong>${label}</strong> has been rescheduled to:</p>
        <p style="font-size:18px;color:#ffffff;margin:16px 0"><strong>${formatInOwnerTz(newStart)}</strong></p>
        ${booking.meet_url ? `<p><a href="${booking.meet_url}" style="background:#58e3ef;color:#000612;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:600">Join Google Meet</a></p>` : ''}
        <hr style="border-color:#1a2a3a;margin:32px 0"/>
        <p style="font-size:13px;color:#888">Need to change again? <a href="${manageUrl}" style="color:#58e3ef">Manage your booking</a></p>
      </div>`;
    await sendEmail(booking.email, `${label} rescheduled — ${formatInOwnerTz(newStart)}`, html);

    return json({ success: true, action: 'rescheduled', newStartAt, newEndAt: newEnd });
  } catch (err) {
    console.error('manage-booking error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
