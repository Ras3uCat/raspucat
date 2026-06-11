// Edge Function: manage-booking
// Token-based (no user auth). Allows cancel or reschedule via cancellation_token.
// Body: { token, action: 'cancel' | 'reschedule', newStartAt? }

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { getAvailableSlots, SLOT_DURATION_MS, formatInOwnerTz } from '../_shared/booking-slots.ts';
import { buildEmail } from '../_shared/email-templates.ts';

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
  const data = await res.json();
  if (!res.ok || !data.access_token) {
    console.error('Google OAuth token exchange failed:', JSON.stringify(data));
    throw new Error(`Google token exchange failed: ${data.error ?? 'unknown'} — ${data.error_description ?? ''}`);
  }
  return data.access_token;
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

    if (!token || !['cancel', 'reschedule', 'get'].includes(action)) {
      return json({ error: 'token and action (cancel|reschedule|get) required.' }, 400);
    }

    const { data: booking, error: lookupError } = await supabase
      .from('bookings')
      .select('id, session_type, start_at, end_at, status, name, email, google_event_id, meet_url, cancellation_token')
      .eq('cancellation_token', token)
      .single();

    if (lookupError || !booking) return json({ error: 'Booking not found.' }, 404);

    const label = SESSION_LABELS[booking.session_type] ?? booking.session_type;

    if (action === 'get') {
      return json({
        success: true,
        booking: {
          name: booking.name,
          email: booking.email,
          sessionType: booking.session_type,
          sessionLabel: label,
          startAt: booking.start_at,
          endAt: booking.end_at,
          status: booking.status,
          meetUrl: booking.meet_url,
          formattedTime: formatInOwnerTz(new Date(booking.start_at)),
        },
      });
    }

    if (booking.status === 'cancelled') return json({ error: 'Booking is already cancelled.' }, 409);

    if (action === 'cancel') {
      await supabase.from('bookings').update({ status: 'cancelled' }).eq('id', booking.id);

      if (booking.google_event_id) {
        try {
          const accessToken = await getGoogleAccessToken();
          await deleteCalendarEvent(booking.google_event_id, accessToken);
        } catch (err) {
          console.error('Calendar delete error (non-fatal):', err instanceof Error ? err.message : err);
        }
      }

      const html = buildEmail({
        eyebrowLabel: 'Booking Cancelled',
        heading: 'Your booking has been cancelled.',
        bodyHtml: `<p>Hi ${booking.name},</p>
                   <p>Your <strong style="color:#E8FEFF;">${label}</strong> on
                   <span style="color:#58E3EF;">${formatInOwnerTz(new Date(booking.start_at))}</span>
                   has been cancelled.</p>
                   <p>If you'd like to book a new session, <a href="${SITE_URL}/#contact" style="color:#58E3EF;">visit our contact page</a>.</p>`,
      });
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
        console.error('Calendar update error (non-fatal):', err instanceof Error ? err.message : err);
      }
    }

    const manageUrl = `${SITE_URL}/booking/manage?token=${booking.cancellation_token}`;
    const ctaHtml = booking.meet_url
      ? `<div style="text-align:center;margin-bottom:32px;">
          <a href="${booking.meet_url}" style="display:inline-block;padding:14px 36px;background:#58E3EF;border-radius:8px;color:#000612;font-family:'Space Grotesk',sans-serif;font-size:13px;font-weight:600;letter-spacing:2px;text-decoration:none;text-transform:uppercase;">
            Join Google Meet →
          </a>
        </div>`
      : '';

    const html = buildEmail({
      eyebrowLabel: 'Booking Rescheduled',
      heading: 'Your booking has been rescheduled.',
      bodyHtml: `<p>Hi ${booking.name},</p>
                 <p>Your <strong style="color:#E8FEFF;">${label}</strong> has been rescheduled to:</p>
                 <p style="font-family:'Space Grotesk',sans-serif;font-size:22px;font-weight:600;color:#58E3EF;margin:16px 0 24px;">${formatInOwnerTz(newStart)}</p>`,
      ctaHtml,
      footerHtml: `<p style="font-size:12px;color:rgba(232,254,255,0.25);margin:0;line-height:1.8;">
                     Need to change again?
                     <a href="${manageUrl}" style="color:rgba(88,227,239,0.6);">Manage your booking</a>
                   </p>`,
    });
    await sendEmail(booking.email, `${label} rescheduled — ${formatInOwnerTz(newStart)}`, html);

    return json({ success: true, action: 'rescheduled', newStartAt, newEndAt: newEnd });
  } catch (err) {
    console.error('manage-booking error:', err);
    return json({ error: 'Internal server error.' }, 500);
  }
});
