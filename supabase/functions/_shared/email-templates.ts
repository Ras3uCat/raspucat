const LOGO_URL =
  'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';

// btoa() only handles ASCII — encode to UTF-8 bytes first for Unicode content (e.g. em dash in labels).
export function toBase64(str: string): string {
  const bytes = new TextEncoder().encode(str);
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary);
}

function toGCalDate(iso: string): string {
  return iso.replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
}

export function buildGoogleCalendarUrl(
  title: string,
  startIso: string,
  endIso: string,
  description: string,
): string {
  const params = new URLSearchParams({
    action: 'TEMPLATE',
    text: title,
    dates: `${toGCalDate(startIso)}/${toGCalDate(endIso)}`,
    details: description,
  });
  return `https://calendar.google.com/calendar/render?${params}`;
}

export function buildIcs(
  summary: string,
  startIso: string,
  endIso: string,
  description: string,
): string {
  const fmt = (s: string) => s.replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Ras3uCat//Booking//EN',
    'BEGIN:VEVENT',
    `DTSTART:${fmt(startIso)}`,
    `DTEND:${fmt(endIso)}`,
    `SUMMARY:${summary}`,
    `DESCRIPTION:${description.replace(/\n/g, '\\n')}`,
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  return lines.join('\r\n');
}

export function buildCalendarCtaHtml(googleCalUrl: string, meetUrl: string | null): string {
  const meetButton = meetUrl
    ? `<a href="${meetUrl}" style="display:inline-block;padding:14px 36px;background:#58E3EF;border-radius:8px;color:#000612;font-family:'Space Grotesk',sans-serif;font-size:13px;font-weight:600;letter-spacing:2px;text-decoration:none;text-transform:uppercase;">
        Join Google Meet →
      </a>`
    : '';

  return `<div style="margin-bottom:32px;">
    ${meetButton ? `<div style="text-align:center;margin-bottom:16px;">${meetButton}</div>` : ''}
    <div style="text-align:center;">
      <a href="${googleCalUrl}" style="display:inline-block;padding:10px 24px;border:1px solid rgba(88,227,239,0.4);border-radius:8px;color:#58E3EF;font-family:'Space Grotesk',sans-serif;font-size:12px;font-weight:600;letter-spacing:2px;text-decoration:none;text-transform:uppercase;">
        + Add to Google Calendar
      </a>
      <p style="font-size:11px;color:rgba(232,254,255,0.25);margin:10px 0 0;">Apple / Outlook users: open the attached <strong style="color:rgba(232,254,255,0.4);">booking.ics</strong> file to add to your calendar.</p>
    </div>
  </div>`;
}

export function buildEmail({
  eyebrowLabel,
  heading,
  bodyHtml,
  ctaHtml = '',
  footerHtml = '',
}: {
  eyebrowLabel: string;
  heading: string;
  bodyHtml: string;
  ctaHtml?: string;
  footerHtml?: string;
}): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600&family=Inter:wght@400;500&display=swap');
  </style>
</head>
<body style="margin:0;padding:0;background:#000612;font-family:'Inter',sans-serif;-webkit-font-smoothing:antialiased;">
<div style="max-width:600px;margin:0 auto;padding:40px 24px;">

  <div style="text-align:center;padding-bottom:28px;border-bottom:1px solid rgba(88,227,239,0.12);">
    <img src="${LOGO_URL}" alt="Ras3uCat" style="height:56px;width:auto;margin-bottom:12px;display:block;margin-left:auto;margin-right:auto;" />
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;letter-spacing:5px;color:#58E3EF;margin:0 0 6px;text-transform:uppercase;">Ras3uCat</p>
    <p style="font-size:10px;color:rgba(232,254,255,0.3);letter-spacing:2px;margin:0;text-transform:uppercase;">Designed to engage. Engineered to move. Deployed to perform.</p>
  </div>

  <div style="padding:40px 0 32px;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">${eyebrowLabel}</p>
    <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">${heading}</h1>
    <div style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0 0 32px;">
      ${bodyHtml}
    </div>
    ${ctaHtml}
    ${footerHtml}
  </div>

  <div style="padding-top:28px;border-top:1px solid rgba(88,227,239,0.08);">
    <p style="color:rgba(232,254,255,0.4);font-size:13px;margin:0 0 4px;">With precision,</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;color:#58E3EF;margin:0;letter-spacing:1px;">Meow</p>
    <p style="font-family:'Space Grotesk',sans-serif;font-size:11px;color:rgba(232,254,255,0.2);margin:4px 0 0;letter-spacing:1px;">Ras3uCat</p>
  </div>

  <div style="text-align:center;padding-top:40px;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:rgba(88,227,239,0.2);margin:0;">Sync complete △ M3OW</p>
  </div>

</div>
</body>
</html>`;
}
