const LOGO_URL =
  'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';

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
