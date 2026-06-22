import '_admin_delivery_step_def.dart';

const deliverySteps = [
  // Setup
  DeliveryStepDef(key: 'discovery_call_complete', label: 'Discovery call complete', phase: 'Setup'),
  DeliveryStepDef(
    key: 'email_provisioned',
    label: 'Client email provisioned (@raspucat.com)',
    phase: 'Setup',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'supabase_account_created',
    label: 'Supabase account created (use provisioned email)',
    phase: 'Setup',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'client_json_generated',
    label: 'client.json generated and filled in',
    phase: 'Setup',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'brand_alignment_complete',
    label: 'Brand alignment report generated (/inspo)',
    phase: 'Setup',
  ),
  // Deploy
  DeliveryStepDef(
    key: 'deliver_sh_complete',
    label: 'deliver.sh run successfully',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'resend_key_set',
    label: 'RESEND_KEY set in Supabase secrets',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'stripe_webhooks_registered',
    label: 'Stripe webhooks registered',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'jwt_hook_registered',
    label: 'JWT hook registered in Supabase Auth',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'supabase_auth_urls_set',
    label: 'Auth Site URL + Redirect URLs set',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'auth_email_templates_customised',
    label: 'Auth email templates customised',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'deployed_to_hosting',
    label: 'Deployed to hosting + DNS pointed',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'www_redirect_confirmed',
    label: 'www redirect confirmed',
    phase: 'Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'stripe_sk_set',
    label: 'STRIPE_SK set in Supabase secrets (test)',
    phase: 'Deploy',
    modules: ['booking'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'stripe_webhook_secret_set',
    label: 'STRIPE_WEBHOOK_SECRET set',
    phase: 'Deploy',
    modules: ['booking'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'stripe_live_switchover',
    label: 'Stripe test → live key switchover',
    phase: 'Deploy',
    modules: ['booking'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'stripe_webhook_live',
    label: 'Stripe webhook re-registered (live)',
    phase: 'Deploy',
    modules: ['booking'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'stripe_shop_webhook_secret_set',
    label: 'STRIPE_SHOP_WEBHOOK_SECRET set',
    phase: 'Deploy',
    modules: ['shop'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'stripe_events_webhook_secret_set',
    label: 'STRIPE_EVENTS_WEBHOOK_SECRET set',
    phase: 'Deploy',
    modules: ['events'],
    isAuto: true,
  ),
  // Post-Deploy
  DeliveryStepDef(
    key: 'favicon_replaced',
    label: 'Favicon + PWA icons replaced',
    phase: 'Post-Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'og_image_set',
    label: 'OG image uploaded and URL set',
    phase: 'Post-Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'master_user_created',
    label: 'Master user created (role: master)',
    phase: 'Post-Deploy',
  ),
  DeliveryStepDef(
    key: 'supabase_2fa_enabled',
    label: 'Supabase 2FA enabled',
    phase: 'Post-Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(key: 'test_data_cleared', label: 'Test data cleared', phase: 'Post-Deploy'),
  DeliveryStepDef(
    key: 'search_console_verified',
    label: 'Search Console + sitemap submitted',
    phase: 'Post-Deploy',
  ),
  DeliveryStepDef(
    key: 'uptime_robot_active',
    label: 'Site monitoring active (direct ping)',
    phase: 'Post-Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'storage_bucket_created',
    label: 'Supabase Storage bucket created (Public)',
    phase: 'Post-Deploy',
    modules: ['gallery'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'expire_bookings_cron',
    label: 'expire-pending-bookings cron scheduled',
    phase: 'Post-Deploy',
    modules: ['booking'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'send_reminders_cron',
    label: 'send-reminders cron scheduled',
    phase: 'Post-Deploy',
    modules: ['booking'],
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'send_review_requests_cron',
    label: 'send-review-requests cron scheduled',
    phase: 'Post-Deploy',
    modules: ['google_reviews'],
    isAuto: true,
  ),
  // QA
  DeliveryStepDef(
    key: 'smoke_test_passed',
    label: 'End-to-end smoke test passed',
    phase: 'QA',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'qa_booking',
    label: 'QA: test booking end-to-end',
    phase: 'QA',
    modules: ['booking'],
  ),
  DeliveryStepDef(key: 'qa_shop', label: 'QA: test shop checkout', phase: 'QA', modules: ['shop']),
  DeliveryStepDef(
    key: 'qa_events',
    label: 'QA: test event ticket purchase',
    phase: 'QA',
    modules: ['events'],
  ),
  DeliveryStepDef(
    key: 'qa_newsletter',
    label: 'QA: test newsletter + welcome email',
    phase: 'QA',
    modules: ['newsletter'],
  ),
  // Handover
  DeliveryStepDef(
    key: 'handover_email_sent',
    label: 'Handover email sent',
    phase: 'Handover',
    isAuto: true,
  ),
];

final deliveryStepByKey = {for (final s in deliverySteps) s.key: s};
