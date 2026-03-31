// Edge Function: admin-send-handoff
// Sends cancellation handoff emails — admin alert or client package.
// Called by admin-cancel-subscription (Path B) and raspucat-stripe-webhook (Path A).
//
// Body: { quoteId, action: 'admin_alert' | 'client_package', adminToken? }
// Auth: adminToken must match ADMIN_PASSWORD, OR Authorization Bearer == SERVICE_ROLE_KEY.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const FROM_EMAIL = Deno.env.get('RESEND_FROM_EMAIL') ?? 'onboarding@resend.dev';
const LOGO_URL = Deno.env.get('LOGO_URL') ?? 'https://gegwqywgbgzahnftppda.supabase.co/storage/v1/object/public/assets/logos/raspucat_gradient.png';
const ADMIN_SITE_URL = Deno.env.get('ADMIN_SITE_URL') ?? 'https://raspucat.com';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY) return;
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM_EMAIL, to, subject, html }),
  });
  if (!res.ok) console.error('Resend error:', res.status, await res.text());
}

function themedEmail(contentHtml: string): string {
  return `<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#000612;font-family:'Inter',sans-serif;">
<div style="max-width:600px;margin:0 auto;padding:40px 24px;">
  <div style="text-align:center;padding-bottom:28px;border-bottom:1px solid rgba(88,227,239,0.12);">
    <img src="${LOGO_URL}" alt="Ras3uCat" style="height:56px;width:auto;display:block;margin:0 auto 12px;" />
    <p style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:600;letter-spacing:5px;color:#58E3EF;margin:0 0 6px;text-transform:uppercase;">Ras3uCat</p>
    <p style="font-size:10px;color:rgba(232,254,255,0.3);letter-spacing:2px;margin:0;text-transform:uppercase;">Building the future, one line of code at a time.</p>
  </div>
  <div style="padding:40px 0 32px;">${contentHtml}</div>
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

function fmtDate(ts: string | null): string {
  if (!ts) return 'N/A';
  return new Date(ts).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
}

async function buildAdminAlert(quote: Record<string, unknown>): Promise<void> {
  const adminEmail = Deno.env.get('ADMIN_EMAIL') ?? FROM_EMAIL;
  const quoteUrl = `${ADMIN_SITE_URL}`;
  const html = themedEmail(`
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#FF6B6B;margin:0 0 14px;text-transform:uppercase;">⚠ Cancellation Initiated</p>
    <h1 style="font-family:'Space Grotesk',sans-serif;font-size:24px;font-weight:600;color:#E8FEFF;margin:0 0 20px;line-height:1.3;letter-spacing:0.5px;">${quote.client_name} is cancelling</h1>
    <div style="background:rgba(88,227,239,0.05);border:1px solid rgba(88,227,239,0.12);border-radius:8px;padding:20px;margin-bottom:24px;">
      <table style="width:100%;border-collapse:collapse;">
        <tr><td style="color:rgba(232,254,255,0.4);font-size:13px;padding:6px 0;">Client</td><td style="color:#E8FEFF;font-size:13px;text-align:right;">${quote.client_name}</td></tr>
        <tr><td style="color:rgba(232,254,255,0.4);font-size:13px;padding:6px 0;">Business</td><td style="color:#E8FEFF;font-size:13px;text-align:right;">${quote.business_name ?? '—'}</td></tr>
        <tr><td style="color:rgba(232,254,255,0.4);font-size:13px;padding:6px 0;">Account email</td><td style="color:#E8FEFF;font-size:13px;text-align:right;">${quote.client_email}</td></tr>
        <tr><td style="color:rgba(232,254,255,0.4);font-size:13px;padding:6px 0;">Delivery email</td><td style="color:#58E3EF;font-size:13px;text-align:right;">${quote.delivery_email ?? quote.client_email}</td></tr>
        <tr><td style="color:rgba(232,254,255,0.4);font-size:13px;padding:6px 0;">Service ends</td><td style="color:#E8FEFF;font-size:13px;text-align:right;">${fmtDate(quote.subscription_cancel_at as string ?? quote.cancelled_at as string)}</td></tr>
        <tr><td style="color:rgba(232,254,255,0.4);font-size:13px;padding:6px 0;">Handoff fee</td><td style="color:#E8FEFF;font-size:13px;text-align:right;">${(quote.handoff_fee_cents as number ?? 0) > 0 ? '$' + ((quote.handoff_fee_cents as number) / 100).toFixed(0) : 'None'}</td></tr>
      </table>
    </div>
    <p style="color:rgba(232,254,255,0.6);font-size:14px;line-height:1.7;margin:0 0 20px;">
      Prepare the handoff package: ensure all deliverables and files are up to date in the portal before the service end date.
    </p>
    <a href="${quoteUrl}" style="display:inline-block;background:rgba(88,227,239,0.1);border:1px solid rgba(88,227,239,0.3);color:#58E3EF;font-family:'Space Grotesk',sans-serif;font-size:13px;font-weight:600;padding:10px 20px;border-radius:6px;text-decoration:none;">Open Admin Panel</a>
  `);
  await sendEmail(adminEmail, `⚠ Cancellation — ${quote.business_name ?? quote.client_name}`, html);
}

function buildWhatToDoNext(modules: string[], clientSlug: string): string {
  const card = (icon: string, label: string, body: string) =>
    `<div style="padding:16px 18px;margin-bottom:12px;background:rgba(88,227,239,0.04);border:1px solid rgba(88,227,239,0.1);border-radius:8px;">
      <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 8px;text-transform:uppercase;">${icon} ${label}</p>
      ${body}
    </div>`;

  const li = (text: string) =>
    `<p style="color:rgba(232,254,255,0.65);font-size:13px;line-height:1.75;margin:4px 0;">• ${text}</p>`;

  const warn = (text: string) =>
    `<p style="color:#FF6B6B;font-size:13px;line-height:1.75;margin:4px 0;">⚠ ${text}</p>`;

  const blocks: string[] = [];

  // Always: Supabase transfer
  const supabaseAccount = clientSlug
    ? `Your database is under <strong style="color:#E8FEFF;">${clientSlug}@raspucat.com</strong>`
    : 'Your database is under your Raspucat-provisioned account';
  blocks.push(card('⬡', 'Transfer Your Database', [
    li(`${supabaseAccount} — log in at <a href="https://supabase.com" style="color:#58E3EF;">supabase.com</a> and update the account email to yours to take full ownership of your database.`),
    li('All your data travels with the Supabase project — no separate export needed for the transfer.'),
  ].join('')));

  // Always: DNS
  blocks.push(card('◈', 'DNS &amp; Domain', [
    li('When you\'re ready to move to a new host, update your domain\'s A record to point to the new server.'),
    li('Your domain registrar (e.g. Namecheap, GoDaddy) is where you manage DNS — not Supabase or Stripe.'),
  ].join('')));

  // Gallery — surface first (time-sensitive)
  if (modules.includes('gallery')) {
    blocks.unshift(card('◉', 'Download Your Gallery Photos', [
      warn('Your gallery photos live in Supabase Storage tied to your project account. Download them before any migration to avoid access issues.'),
      li('Log in at supabase.com → Storage → portal-files bucket → download all assets.'),
      li('Once the account is transferred, the storage bucket moves with it — download first.'),
    ].join('')));
  }

  // Booking
  if (modules.includes('booking')) {
    blocks.push(card('◷', 'Booking &amp; Payments', [
      li('Your booking payments are in your own Stripe account. Log in at <a href="https://stripe.com" style="color:#58E3EF;">stripe.com</a> using the email you used during Stripe onboarding.'),
      li('Cancellation policy: Admin → Settings → Booking Rules'),
      li('Issue refunds: Admin → Bookings → select booking → Refund'),
    ].join('')));
  }

  // Shop
  if (modules.includes('shop')) {
    blocks.push(card('◫', 'Shop &amp; Orders', [
      li('Your shop payments are in your Stripe account — same login as above if booking is also active.'),
      li('Fulfil orders: Admin → Shop → Orders'),
      li('Export your product list: Admin → Shop → Products → Export (keep a copy before switching platforms).'),
    ].join('')));
  }

  // Events
  if (modules.includes('events')) {
    blocks.push(card('◈', 'Events', [
      li('Your event payments are in your Stripe account. Log in at stripe.com to manage payouts.'),
      li('Past attendee data is exportable from your Supabase dashboard (<code style="color:#58E3EF;">event_tickets</code> table).'),
      li('If you move to a new provider, you\'ll need to re-register the Stripe webhook endpoint.'),
    ].join('')));
  }

  // Newsletter
  if (modules.includes('newsletter')) {
    blocks.push(card('◎', 'Newsletter &amp; Subscribers', [
      warn('Existing unsubscribe links will stop working once the site goes down — notify subscribers before go-down if possible.'),
      li('Export your subscriber list from Supabase (<code style="color:#58E3EF;">newsletter_subscribers</code> table) before transferring.'),
      li('Resend domain verification is tied to this project — verify a new domain with your new email provider.'),
    ].join('')));
  }

  // Blog
  if (modules.includes('blog')) {
    blocks.push(card('◱', 'Blog', [
      li('All blog posts are stored in your Supabase DB (<code style="color:#58E3EF;">blog_posts</code> table) — fully exportable.'),
      li('No third-party CMS dependency — all content is yours and travels with the database.'),
    ].join('')));
  }

  // Subscriptions
  if (modules.includes('subscriptions')) {
    blocks.push(card('↻', 'Recurring Subscriptions', [
      li('Recurring subscription management is in your Stripe account at <a href="https://stripe.com" style="color:#58E3EF;">stripe.com</a>.'),
      li('Notify active subscribers of any plan or billing changes before they happen.'),
      li('Subscriber records are exportable from Supabase (<code style="color:#58E3EF;">subscriptions</code> table).'),
    ].join('')));
  }

  // CRM
  if (modules.includes('crm')) {
    blocks.push(card('◧', 'Client Records (CRM)', [
      li('Client records (<code style="color:#58E3EF;">profiles</code> + <code style="color:#58E3EF;">bookings</code>) are exportable from your Supabase dashboard.'),
      li('Export via: Supabase Dashboard → Table Editor → select table → Export to CSV.'),
    ].join('')));
  }

  // Loyalty
  if (modules.includes('loyalty')) {
    blocks.push(card('◆', 'Loyalty Points', [
      li('Loyalty points ledger is in Supabase (<code style="color:#58E3EF;">loyalty_ledger</code> table) — exportable.'),
      warn('Points balances will be lost if clients are migrated to a new platform without a data migration.'),
    ].join('')));
  }

  // Referrals
  if (modules.includes('referrals')) {
    blocks.push(card('↗', 'Referrals', [
      li('Referral records are in Supabase (<code style="color:#58E3EF;">referrals</code> table) — exportable.'),
      warn('Outstanding referral discount codes will stop working when the site goes down.'),
    ].join('')));
  }

  // Gift vouchers
  if (modules.includes('gift')) {
    blocks.push(card('◇', 'Gift Vouchers', [
      warn('Outstanding unredeemed vouchers: you are responsible for honouring these after transition. Export the list and contact those clients directly.'),
      li('Gift voucher records are in Supabase (<code style="color:#58E3EF;">gift_vouchers</code> table) — exportable.'),
    ].join('')));
  }

  // Reviews
  if (modules.includes('reviews')) {
    blocks.push(card('◎', 'Reviews', [
      li('Review records are in Supabase (<code style="color:#58E3EF;">reviews</code> table) — exportable.'),
      li('Google Reviews Auto-Sync (if enabled) will stop pulling once the site is down.'),
    ].join('')));
  }

  // Always: Support
  blocks.push(card('✦', 'Need Help During Transition?', [
    li('Reply to this email and we\'ll help you through the handoff process.'),
    li('We\'re available to answer questions during your transition window.'),
  ].join('')));

  return `<div style="margin-bottom:28px;">
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 16px;text-transform:uppercase;">What To Do Next</p>
    ${blocks.join('\n    ')}
  </div>`;
}

async function buildClientPackage(quote: Record<string, unknown>): Promise<void> {
  const deliveryTo = (quote.delivery_email as string) ?? (quote.client_email as string);

  // Fetch deliverables
  const { data: deliverables } = await supabase
    .from('portal_deliverables')
    .select('title, url, status')
    .eq('quote_id', quote.id)
    .order('created_at');

  // Fetch admin-uploaded files
  const { data: files } = await supabase
    .from('portal_files')
    .select('file_name, storage_path, size_bytes')
    .eq('quote_id', quote.id)
    .eq('uploaded_by', 'admin')
    .order('created_at');

  // Build signed URLs for files (valid 7 days)
  const fileLinks: Array<{ name: string; url: string; size: string }> = [];
  for (const file of files ?? []) {
    const { data: signed } = await supabase.storage
      .from('portal-files')
      .createSignedUrl(file.storage_path as string, 60 * 60 * 24 * 7);
    if (signed?.signedUrl) {
      const kb = Math.round((file.size_bytes as number) / 1024);
      fileLinks.push({ name: file.file_name as string, url: signed.signedUrl, size: `${kb} KB` });
    }
  }

  const deliverablesHtml = (deliverables ?? []).length > 0
    ? `<div style="margin-bottom:28px;">
        <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 12px;text-transform:uppercase;">Your Deliverables</p>
        ${(deliverables ?? []).map((d: Record<string, unknown>) => `
          <div style="padding:10px 14px;margin-bottom:8px;background:rgba(88,227,239,0.04);border:1px solid rgba(88,227,239,0.1);border-radius:6px;">
            ${d.url ? `<a href="${d.url}" style="color:#58E3EF;font-size:14px;font-weight:500;text-decoration:none;">${d.title}</a>` : `<span style="color:#E8FEFF;font-size:14px;">${d.title}</span>`}
          </div>`).join('')}
      </div>`
    : '';

  const filesHtml = fileLinks.length > 0
    ? `<div style="margin-bottom:28px;">
        <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 12px;text-transform:uppercase;">Your Files</p>
        <p style="color:rgba(232,254,255,0.4);font-size:12px;margin:0 0 10px;">Download links expire in 7 days.</p>
        ${fileLinks.map(f => `
          <div style="padding:10px 14px;margin-bottom:8px;background:rgba(88,227,239,0.04);border:1px solid rgba(88,227,239,0.1);border-radius:6px;display:flex;justify-content:space-between;align-items:center;">
            <a href="${f.url}" style="color:#58E3EF;font-size:14px;font-weight:500;text-decoration:none;">${f.name}</a>
            <span style="color:rgba(232,254,255,0.3);font-size:12px;">${f.size}</span>
          </div>`).join('')}
      </div>`
    : '';

  const noAssetsMsg = deliverablesHtml === '' && filesHtml === ''
    ? `<p style="color:rgba(232,254,255,0.5);font-size:14px;margin:0 0 28px;">No files or deliverables are currently stored in your portal. If you are expecting specific assets, please contact us and we'll make sure you receive everything.</p>`
    : '';

  const whatNextHtml = buildWhatToDoNext(
    (quote.modules as string[]) ?? [],
    (quote.client_slug as string) ?? '',
  );

  const html = themedEmail(`
    <p style="font-family:'Space Grotesk',sans-serif;font-size:10px;letter-spacing:3px;color:#58E3EF;margin:0 0 14px;text-transform:uppercase;">Your Handoff Package</p>
    <h1 style="font-family:'Space Grotesk',sans-serif;font-size:26px;font-weight:600;color:#E8FEFF;margin:0 0 14px;line-height:1.3;letter-spacing:0.5px;">Here's everything that belongs to you, ${quote.client_name}.</h1>
    <p style="color:rgba(232,254,255,0.6);font-size:15px;line-height:1.8;margin:0 0 32px;">
      Thank you for trusting Ras3uCat to build and manage <strong style="color:#E8FEFF;">${quote.business_name ?? 'your site'}</strong>.
      Below is everything you need to take full ownership of your digital presence.
    </p>
    ${deliverablesHtml}
    ${filesHtml}
    ${noAssetsMsg}
    ${whatNextHtml}
    <p style="color:rgba(232,254,255,0.4);font-size:13px;line-height:1.7;margin:0;">
      It's been a pleasure working with you. Wishing you and ${quote.business_name ?? 'your business'} all the best.
    </p>
  `);

  await sendEmail(deliveryTo, `Your files and deliverables from Ras3uCat — ${quote.business_name ?? quote.client_name}`, html);

  // Mark package as sent (idempotency guard)
  await supabase
    .from('quotes')
    .update({ handoff_package_ready: true })
    .eq('id', quote.id);
}

function isAuthorized(req: Request, body: Record<string, unknown>): boolean {
  const adminPassword = Deno.env.get('ADMIN_PASSWORD');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  // Check adminToken in body
  if (adminPassword && body.adminToken === adminPassword) return true;

  // Check Authorization Bearer header (for internal function-to-function calls)
  const authHeader = req.headers.get('Authorization') ?? '';
  const bearer = authHeader.replace('Bearer ', '').trim();
  if (serviceRoleKey && bearer === serviceRoleKey) return true;

  return false;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json() as Record<string, unknown>;
    if (!isAuthorized(req, body)) {
      return new Response(JSON.stringify({ error: 'Unauthorized.' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { quoteId, action } = body;
    if (!quoteId || !action) {
      return new Response(JSON.stringify({ error: 'quoteId and action are required.' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: quote, error: quoteErr } = await supabase
      .from('quotes')
      .select('*')
      .eq('id', quoteId)
      .single();

    if (quoteErr || !quote) {
      return new Response(JSON.stringify({ error: 'Quote not found.' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'admin_alert') {
      await buildAdminAlert(quote);
      return new Response(JSON.stringify({ success: true }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'client_package') {
      // Idempotency: skip if already sent
      if (quote.handoff_package_ready === true) {
        return new Response(JSON.stringify({ success: true, skipped: true }), {
          status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      await buildClientPackage(quote);
      return new Response(JSON.stringify({ success: true }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('admin-send-handoff error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
