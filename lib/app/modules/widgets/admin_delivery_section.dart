import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import '_admin_delivery_step_def.dart';
import '_admin_delivery_widgets.dart';

const _steps = [
  // Setup
  DeliveryStepDef(key: 'discovery_call_complete', label: 'Discovery call complete', phase: 'Setup'),
  DeliveryStepDef(
    key: 'email_provisioned',
    label: 'Client email provisioned (@raspucat.com)',
    phase: 'Setup',
  ),
  DeliveryStepDef(
    key: 'supabase_account_created',
    label: 'Supabase account created (use provisioned email)',
    phase: 'Setup',
  ),
  DeliveryStepDef(
    key: 'client_json_generated',
    label: 'client.json generated and filled in',
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
    key: 'stripe_webhooks_registered',
    label: 'Stripe webhooks registered',
    phase: 'Deploy',
  ),
  DeliveryStepDef(
    key: 'jwt_hook_registered',
    label: 'JWT hook registered in Supabase Auth',
    phase: 'Deploy',
  ),
  DeliveryStepDef(
    key: 'supabase_auth_urls_set',
    label: 'Auth Site URL + Redirect URLs set',
    phase: 'Deploy',
  ),
  DeliveryStepDef(
    key: 'auth_email_templates_customised',
    label: 'Auth email templates customised',
    phase: 'Deploy',
  ),
  DeliveryStepDef(
    key: 'deployed_to_hosting',
    label: 'Deployed to hosting + DNS pointed',
    phase: 'Deploy',
  ),
  DeliveryStepDef(key: 'www_redirect_confirmed', label: 'www redirect confirmed', phase: 'Deploy'),
  DeliveryStepDef(
    key: 'stripe_sk_set',
    label: 'STRIPE_SK set in Supabase secrets (test)',
    phase: 'Deploy',
    modules: ['booking'],
  ),
  DeliveryStepDef(
    key: 'stripe_webhook_secret_set',
    label: 'STRIPE_WEBHOOK_SECRET set',
    phase: 'Deploy',
    modules: ['booking'],
  ),
  DeliveryStepDef(
    key: 'stripe_live_switchover',
    label: 'Stripe test → live key switchover',
    phase: 'Deploy',
    modules: ['booking'],
  ),
  DeliveryStepDef(
    key: 'stripe_webhook_live',
    label: 'Stripe webhook re-registered (live)',
    phase: 'Deploy',
    modules: ['booking'],
  ),
  DeliveryStepDef(
    key: 'stripe_shop_webhook_secret_set',
    label: 'STRIPE_SHOP_WEBHOOK_SECRET set',
    phase: 'Deploy',
    modules: ['shop'],
  ),
  DeliveryStepDef(
    key: 'stripe_events_webhook_secret_set',
    label: 'STRIPE_EVENTS_WEBHOOK_SECRET set',
    phase: 'Deploy',
    modules: ['events'],
  ),
  // Post-Deploy
  DeliveryStepDef(
    key: 'favicon_replaced',
    label: 'Favicon + PWA icons replaced',
    phase: 'Post-Deploy',
  ),
  DeliveryStepDef(
    key: 'og_image_set',
    label: 'OG image uploaded and URL set',
    phase: 'Post-Deploy',
  ),
  DeliveryStepDef(
    key: 'master_user_created',
    label: 'Master user created (role: master)',
    phase: 'Post-Deploy',
  ),
  DeliveryStepDef(key: 'supabase_2fa_enabled', label: 'Supabase 2FA enabled', phase: 'Post-Deploy'),
  DeliveryStepDef(key: 'test_data_cleared', label: 'Test data cleared', phase: 'Post-Deploy'),
  DeliveryStepDef(
    key: 'search_console_verified',
    label: 'Search Console + sitemap submitted',
    phase: 'Post-Deploy',
  ),
  DeliveryStepDef(
    key: 'uptime_robot_active',
    label: 'UptimeRobot monitor active',
    phase: 'Post-Deploy',
    isAuto: true,
  ),
  DeliveryStepDef(
    key: 'storage_bucket_created',
    label: 'Supabase Storage bucket created (Public)',
    phase: 'Post-Deploy',
    modules: ['gallery'],
  ),
  DeliveryStepDef(
    key: 'expire_bookings_cron',
    label: 'expire-pending-bookings cron scheduled',
    phase: 'Post-Deploy',
    modules: ['booking'],
  ),
  DeliveryStepDef(
    key: 'send_reminders_cron',
    label: 'send-reminders cron scheduled',
    phase: 'Post-Deploy',
    modules: ['booking'],
  ),
  DeliveryStepDef(
    key: 'send_review_requests_cron',
    label: 'send-review-requests cron scheduled',
    phase: 'Post-Deploy',
    modules: ['google_reviews'],
  ),
  // QA
  DeliveryStepDef(key: 'smoke_test_passed', label: 'End-to-end smoke test passed', phase: 'QA'),
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

final _stepByKey = {for (final s in _steps) s.key: s};

class AdminDeliverySection extends StatefulWidget {
  const AdminDeliverySection({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.moduleIds,
  });

  final AdminController ctrl;
  final String quoteId;
  final List<String> moduleIds;

  @override
  State<AdminDeliverySection> createState() => _AdminDeliverySectionState();
}

class _AdminDeliverySectionState extends State<AdminDeliverySection> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.ctrl.fetchDeliveryProgress(widget.quoteId);
    if (!mounted) return;
    final rows = widget.ctrl.deliveryProgress[widget.quoteId];
    if (rows != null && rows.isEmpty) {
      await widget.ctrl.initDeliveryProgress(widget.quoteId, widget.moduleIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.ctrl.loadingDelivery.contains(widget.quoteId)) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
          ),
        );
      }
      final rows = widget.ctrl.deliveryProgress[widget.quoteId] ?? [];
      final total = rows.length;
      final checked = rows.where((r) => r['checked'] == true).length;
      final done = total > 0 && checked == total;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressHeader(checked: checked, total: total, done: done),
            const SizedBox(height: ESizes.md),
            ..._buildPhases(rows),
          ],
        ),
      );
    });
  }

  List<Widget> _buildPhases(List<Map<String, dynamic>> rows) {
    const phases = ['Setup', 'Deploy', 'Post-Deploy', 'QA', 'Handover'];
    final widgets = <Widget>[];
    for (final phase in phases) {
      final phaseRows = rows.where((r) {
        final def = _stepByKey[r['step'] as String? ?? ''];
        return def?.phase == phase;
      }).toList();
      if (phaseRows.isEmpty) continue;
      widgets.add(PhaseLabel(phase));
      widgets.add(const SizedBox(height: 6));
      for (final row in phaseRows) {
        final def = _stepByKey[row['step'] as String? ?? ''];
        if (def == null) continue;
        widgets.add(
          DeliveryStepRow(
            def: def,
            checked: row['checked'] == true,
            checkedBy: row['checked_by'] as String?,
            checkedAt: row['checked_at'] as String?,
            onToggle: def.isAuto
                ? null
                : (v) => widget.ctrl.toggleDeliveryStep(widget.quoteId, def.key, v),
          ),
        );
      }
      widgets.add(const SizedBox(height: ESizes.md));
    }
    return widgets;
  }
}
