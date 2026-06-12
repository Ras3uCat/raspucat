// Edge Function: create-booking
// Public (leads) or portal-auth (clients).
// Body: { sessionType, startAt, name, email, message?, quoteId? }
// Creates booking row, Google Calendar event (with Meet link), and sends confirmation email.

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
const ADMIN_EMAIL = Deno.env.get('ADMIN_EMAIL') ?? 'ras3ucat@gmail.com';

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
        description: `${message ? message + '\n\n' : ''}Guest email: ${guestEmail}`,
        start: { dateTime: startAt, timeZone: 'UTC' },
        end: { dateTime: endAt, timeZone: 'UTC' },
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

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) return;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
}

async function sendConfirmationEmail(
  to: string,
  name: string,
  sessionType: string,
  startAt: Date,
  meetUrl: string | null,
  cancellationToken: string,
): Promise<void> {
  const label = SESSION_LABELS[sessionType] ?? sessionType;
  const formattedTime = formatInOwnerTz(startAt);
  const manageUrl = `${SITE_URL}/booking/manage?token=${cancellationToken}`;

  const ctaHtml = meetUrl
    ? `<div style="text-align:center;margin-bottom:32px;">
        <a href="${meetUrl}" style="display:inline-block;padding:14px 36px;background:#58E3EF;border-radius:8px;color:#000612;font-family:'Space Grotesk',sans-serif;font-size:13px;font-weight:600;letter-spacing:2px;text-decoration:none;text-transform:uppercase;">
          Join Google Meet →
        </a>
      </div>`
    : '';

  const html = buildEmail({
    eyebrowLabel: 'Booking Confirmed',
    heading: `Your ${label} is confirmed.`,
    bodyHtml: `<p>Hi ${name},</p>
               <p>You're booked for a <strong style="color:#E8FEFF;">${label}</strong> on:</p>
               <p style="font-family:'Space Grotesk',sans-serif;font-size:22px;font-weight:600;color:#58E3EF;margin:16px 0 24px;">${formattedTime}</p>`,
    ctaHtml,
    footerHtml: `<p style="font-size:12px;color:rgba(232,254,255,0.25);margin:0;line-height:1.8;">
                   Need to reschedule or cancel?
                   <a href="${manageUrl}" style="color:rgba(88,227,239,0.6);">Manage your booking</a>
                 </p>`,
  });

  await sendEmail(to, `${label} confirmed — ${formattedTime}`, html);
}

async function sendAdminNotificationEmail(
  sessionType: string,
  guestName: string,
  guestEmail: string,
  startAt: Date,
  message: string | null,
  meetUrl: string | null,
): Promise<void> {
  const label = SESSION_LABELS[sessionType] ?? sessionType;
  const formattedTime = formatInOwnerTz(startAt);

  const html = buildEmail({
    eyebrowLabel: 'New Booking',
    heading: `New ${label} booked.`,
    bodyHtml: `<p><strong style="color:#E8FEFF;">Name:</strong> ${guestName}</p>
               <p><strong style="color:#E8FEFF;">Email:</strong> ${guestEmail}</p>
               <p><strong style="color:#E8FEFF;">When:</strong> <span style="color:#58E3EF;">${formattedTime}</span></p>
               ${message ? `<p><strong style="color:#E8FEFF;">Message:</strong><br>${message}</p>` : ''}
               ${meetUrl ? `<p><strong style="color:#E8FEFF;">Meet link:</strong> <a href="${meetUrl}" style="color:#58E3EF;">${meetUrl}</a></p>` : ''}`,
  });

  await sendEmail(ADMIN_EMAIL, `New booking: ${label} — ${guestName}`, html);
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
    await sendAdminNotificationEmail(sessionType, name, email, startDate, message, meetUrl);

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
