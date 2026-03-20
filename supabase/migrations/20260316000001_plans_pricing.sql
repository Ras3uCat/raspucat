-- ============================================================
-- Migration: 20260316000001_plans_pricing.sql
-- Plans & Pricing — modules, management options, plan presets
-- ============================================================

-- ------------------------------------------------------------
-- MODULES
-- ------------------------------------------------------------
create table if not exists public.modules (
  id             text primary key,                 -- e.g. 'blog_gallery'
  name           text not null,
  description    text not null,
  price          integer not null,                 -- a la carte price in USD cents
  price_note     text,                             -- e.g. '+ usage' for variable pricing
  upgrade_of     text references public.modules(id), -- non-null = upgrade path (e.g. ai_chatbot_full → ai_chatbot_lite)
  sort_order     integer not null default 0,
  created_at     timestamptz not null default now()
);

-- Seed modules (prices in USD cents)
insert into public.modules (id, name, description, price, price_note, upgrade_of, sort_order) values
  ('blog_gallery',         'Blog & Gallery',               'Publish posts and showcase your work with a fully managed blog and image gallery.',                             40000, null,       null,              1),
  ('booking_shop',         'Online Booking / Shop',        'Accept appointments or sell products online with a built-in booking calendar and storefront.',                  60000, null,       null,              2),
  ('stripe',               'Stripe Integration',           'Secure payment processing for bookings, products, and deposits via Stripe Checkout.',                          30000, null,       null,              3),
  ('tip_gratuity',         'Tip / Gratuity at Checkout',   'One-click tip selector at checkout — a favorite for salons and spas that often pays for the site itself.',    20000, null,       null,              4),
  ('pwa_notifications',    'PWA Push Notifications',       'Home screen install with push notifications for booking reminders and promos — no App Store required.',        40000, null,       null,              5),
  ('stats_digest',         'Monthly Stats Digest',         'Branded monthly PDF showing revenue trends, top services, and growth metrics sent to your inbox.',             30000, null,       null,              6),
  ('ai_chatbot_lite',      'AI Chatbot — Lite',            'Pre-loaded with your FAQ, hours, and service list. Handles the "Are you open?" questions 24/7.',               50000, null,       null,              7),
  ('ai_chatbot_full',      'AI Chatbot — Full',            'Deeply trained on your business data and tone. Fine-tuned monthly. Reduces admin load by up to 40%.',          80000, null,       'ai_chatbot_lite', 8),
  ('pdf_invoices',         'Automated PDF Invoices',       'Auto-generated branded invoices sent to clients after every transaction.',                                     40000, null,       null,              9),
  ('multi_location',       'Multi-location Support',       'Manage multiple business locations from one dashboard with location-specific pages and booking.',               90000, null,       null,             10),
  ('native_apps',          'Native Mobile Apps',           'Full iOS and Android App Store presence with deep device integration and offline support.',                    350000, null,       null,             11),
  ('stripe_connect',       'Stripe Connect',               'Multi-staff payout management — each team member receives their share automatically.',                         70000, null,       null,             12),
  ('sms_reminders',        'SMS Reminders',                'Automated appointment reminders and confirmations via SMS (powered by Twilio).',                               40000, '+ usage',  null,             13),
  ('loyalty_referrals',    'Loyalty & Referrals',          'Points-based loyalty program and referral tracking to retain and grow your client base.',                      60000, null,       null,             14),
  ('google_reviews',       'Google Reviews Auto-Sync',     'Automatically pulls your latest Google reviews onto your site to build social proof.',                        35000, null,       null,             15),
  ('custom_menu',          'Custom Menu / Pricing Module', 'A fully branded, editable menu or service pricing list displayed on your site.',                               45000, null,       null,             16),
  ('gated_content',        'Gated Video / Course Content', 'Password-protected video lessons or course content for memberships or paid programs.',                        150000, '+',        null,             17)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- MANAGEMENT OPTIONS
-- ------------------------------------------------------------
create table if not exists public.management_options (
  id             text primary key,                 -- 'standard' | 'premium' | 'handover'
  name           text not null,
  description    text not null,
  monthly_price  integer not null default 0,       -- USD cents; 0 for handover
  annual_price   integer not null default 0,       -- USD cents; 0 for handover
  annual_savings integer not null default 0,       -- USD cents; 0 for handover
  onetime_price  integer not null default 0,       -- USD cents; 0 for recurring plans
  sort_order     integer not null default 0,
  created_at     timestamptz not null default now()
);

insert into public.management_options (id, name, description, monthly_price, annual_price, annual_savings, onetime_price, sort_order) values
  ('standard', 'Standard Management', 'Hosting & SSL, Supabase DB & Auth, domain management, platform updates, monthly stats digest, 1 hr content support.',  14900, 149000, 29800, 0,     1),
  ('premium',  'Premium Management',  'Everything in Standard plus priority support (< 4h response), monthly AI chatbot fine-tuning, advanced SEO tracking.',   29900, 299000, 59800, 0,     2),
  ('handover', 'Handover & Docs',     'Full deployment to your own infrastructure, credential transfer, technical documentation, and 1 onboarding call.',       0,     0,      0,     40000, 3)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- PLANS
-- ------------------------------------------------------------
create table if not exists public.plans (
  id                  text primary key,            -- 'pro' | 'premium' | 'custom'
  name                text not null,
  label               text not null,               -- e.g. 'Launchpad'
  ideal_for           text not null,
  setup_price         integer not null,            -- USD cents (bundle price)
  base_price          integer not null default 120000, -- USD cents — always $1,200
  monthly_price       integer not null,            -- USD cents; matches management standard
  bundle_savings      integer,                     -- USD cents; null for custom
  is_featured         boolean not null default false,
  is_custom           boolean not null default false,
  locked_module_ids   text[] not null default '{}',
  sort_order          integer not null default 0,
  created_at          timestamptz not null default now()
);

insert into public.plans (id, name, label, ideal_for, setup_price, monthly_price, bundle_savings, is_featured, is_custom, locked_module_ids, sort_order) values
  ('pro',     'Pro',     'Launchpad', 'Solopreneurs & Startups',                      220000, 14900, 30000, false, false,
   array['blog_gallery','booking_shop','stripe'], 1),
  ('premium', 'Premium', 'Engine',    'Service & Retail SMBs',                        350000, 14900, 75000, true,  false,
   array['blog_gallery','booking_shop','stripe','tip_gratuity','pwa_notifications','stats_digest','ai_chatbot_lite'], 2),
  ('custom',  'Custom',  'Build Your Own', 'Franchises, Power Users & High-Growth',   120000, 14900, null,  false, true,
   array[]::text[], 3)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- RLS — public read-only (no auth required for portfolio site)
-- ------------------------------------------------------------
alter table public.modules           enable row level security;
alter table public.management_options enable row level security;
alter table public.plans             enable row level security;

create policy "Public read modules"            on public.modules            for select using (true);
create policy "Public read management_options" on public.management_options for select using (true);
create policy "Public read plans"              on public.plans              for select using (true);
