// Edge Function: create-booking
// Public (leads) or portal-auth (clients).
// Body: { sessionType, startAt, name, email, message?, quoteId? }
// Creates booking row, Google Calendar event (with Meet link), and sends confirmation email.

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

async function createCalendarEvent(
  bookingId: string,
  sessionType: string,
  guestName: string,
  guestEmail: string,
  startAt: string,
  endAt: string,
  message: string | null,
  accessToken: string,
): Promise<{ googleEventId: string | null; meetUrl: string | null }> {
  const calendarId = Deno.env.get('GOOGLE_CALENDAR_ID') ?? 'primary';
  const label = SESSION_LABELS[sessionType] ?? sessionType;
  const res = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events?conferenceDataVersion=1`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        summary: `${label} — ${guestName}`,
        description: message ?? '',
        start: { dateTime: startAt, timeZone: 'UTC' },
        end: { dateTime: endAt, timeZone: 'UTC' },
        attendees: [{ email: guestEmail, displayName: guestName }],
        conferenceData: {
          createRequest: {
            requestId: bookingId,
            conferenceSolutionKey: { type: 'hangoutsMeet' },
          },
        },
      }),
    },
  );
  if (!res.ok) {
    console.error('Calendar create error:', res.status, await res.text());
    return { googleEventId: null, meetUrl: null };
  }
  const event = await res.json();
  const meetUrl = event.conferenceData?.entryPoints?.find(
    (ep: { entryPointType: string; uri: string }) => ep.entryPointType === 'video',
  )?.uri ?? null;
  return { googleEventId: event.id ?? null, meetUrl };
}

async function sendConfirmationEmail(
  to: string,
  name: string,
  sessionType: string,
  startAt: Date,
  meetUrl: string | null,
  cancellationToken: string,
): Promise<void> {
  if (!RESEND_API_KEY) return;
  const label = SESSION_LABELS[sessionType] ?? sessionType;
  const formattedTime = formatInOwnerTz(startAt);
  const manageUrl = `${SITE_URL}/booking/manage?token=${cancellationToken}`;
  const html = `
    <div style="background:#000612;color:#e0e0e0;font-family:Inter,sans-serif;padding:40px 24px;max-width:600px;margin:0 auto">
      <h2 style="color:#58e3ef;margin-bottom:8px">Your ${label} is confirmed</h2>
      <p>Hi ${name},</p>
      <p>You're booked for a <strong>${label}</strong> on:</p>
      <p style="font-size:18px;color:#ffffff;margin:16px 0"><strong>${formattedTime}</strong></p>
      ${meetUrl ? `<p><a href="${meetUrl}" style="background:#58e3ef;color:#000612;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:600">Join Google Meet</a></p>` : ''}
      <hr style="border-color:#1a2a3a;margin:32px 0"/>
      <p style="font-size:13px;color:#888">Need to reschedule or cancel?
        <a href="${manageUrl}" style="color:#58e3ef">Manage your booking</a>
      </p>
    </div>`;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject: `${label} confirmed — ${formattedTime}`, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { sessionType, startAt, name, email, message = null, quoteId = null, leadId = null } = await req.json();

    if (!sessionType || !startAt || !name || !email) {
      return json({ error: 'sessionType, startAt, name, email required.' }, 400);
    }
    if (!['discovery_call', 'project_checkin'].includes(sessionType)) {
      return json({ error: 'Invalid sessionType.' }, 400);
    }

    const startDate = new Date(startAt);
    if (isNaN(startDate.getTime())) return json({ error: 'Invalid startAt.' }, 400);

    // Re-validate slot is still available (race condition protection)
    const dateStr = startAt.slice(0, 10);
    const available = await getAvailableSlots(supabase, dateStr);
    const isAvailable = available.some((s) => s.getTime() === startDate.getTime());
    if (!isAvailable) return json({ error: 'Slot is no longer available.' }, 409);

    const endAt = new Date(startDate.getTime() + SLOT_DURATION_MS).toISOString();

    // Insert booking (cancellation_token generated by DB default)
    const { data: booking, error: insertError } = await supabase
      .from('bookings')
      .insert({ session_type: sessionType, start_at: startAt, end_at: endAt, name, email, message, quote_id: quoteId })
      .select('id, cancellation_token')
      .single();

    if (insertError || !booking) {
      console.error('Booking insert error:', insertError);
      return json({ error: 'Failed to create booking.' }, 500);
    }

    // Google Calendar + Meet (best-effort — don't fail the booking if Calendar errors)
    let meetUrl: string | null = null;
    try {
      const accessToken = await getGoogleAccessToken();
      const calResult = await createCalendarEvent(
        booking.id, sessionType, name, email, startAt, endAt, message, accessToken,
      );
      if (calResult.googleEventId) {
        await supabase.from('bookings').update({
          google_event_id: calResult.googleEventId,
          meet_url: calResult.meetUrl,
        }).eq('id', booking.id);
        meetUrl = calResult.meetUrl;
      }
    } catch (calErr) {
      console.error('Calendar integration error (non-fatal):', calErr);
    }

    await sendConfirmationEmail(email, name, sessionType, startDate, meetUrl, booking.cancellation_token);

    // If this booking came from an outreach lead, advance them to call_booked
    if (leadId) {
      await supabase
        .from('leads')
        .update({ status: 'call_booked' })
        .eq('id', leadId)
        .in('status', ['prospect', 'contacted', 'replied']);
    }

    return json({ bookingId: booking.id, cancellationToken: booking.cancellation_token, meetUrl });
  } catch (err) {
    console.error('create-booking error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
