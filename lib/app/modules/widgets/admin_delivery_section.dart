import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

// Step definition — must stay in sync with edge function STEPS array.
class _StepDef {
  const _StepDef({
    required this.key,
    required this.label,
    required this.phase,
    this.modules = const [],
    this.isAuto = false,
  });
  final String key;
  final String label;
  final String phase;
  final List<String> modules; // substring-matched against module_ids
  final bool isAuto;
}

const _steps = [
  // Setup
  _StepDef(key: 'discovery_call_complete', label: 'Discovery call complete', phase: 'Setup'),
  _StepDef(key: 'supabase_account_created', label: 'Supabase account created', phase: 'Setup'),
  _StepDef(key: 'client_json_generated', label: 'client.json generated and filled in', phase: 'Setup'),
  // Deploy
  _StepDef(key: 'deliver_sh_complete', label: 'deliver.sh run successfully', phase: 'Deploy', isAuto: true),
  _StepDef(key: 'stripe_webhooks_registered', label: 'Stripe webhooks registered', phase: 'Deploy'),
  _StepDef(key: 'jwt_hook_registered', label: 'JWT hook registered in Supabase Auth', phase: 'Deploy'),
  _StepDef(key: 'supabase_auth_urls_set', label: 'Auth Site URL + Redirect URLs set', phase: 'Deploy'),
  _StepDef(key: 'auth_email_templates_customised', label: 'Auth email templates customised', phase: 'Deploy'),
  _StepDef(key: 'deployed_to_hosting', label: 'Deployed to hosting + DNS pointed', phase: 'Deploy'),
  _StepDef(key: 'www_redirect_confirmed', label: 'www redirect confirmed', phase: 'Deploy'),
  _StepDef(key: 'stripe_sk_set', label: 'STRIPE_SK set in Supabase secrets (test)', phase: 'Deploy', modules: ['booking']),
  _StepDef(key: 'stripe_webhook_secret_set', label: 'STRIPE_WEBHOOK_SECRET set', phase: 'Deploy', modules: ['booking']),
  _StepDef(key: 'stripe_live_switchover', label: 'Stripe test → live key switchover', phase: 'Deploy', modules: ['booking']),
  _StepDef(key: 'stripe_webhook_live', label: 'Stripe webhook re-registered (live)', phase: 'Deploy', modules: ['booking']),
  _StepDef(key: 'stripe_shop_webhook_secret_set', label: 'STRIPE_SHOP_WEBHOOK_SECRET set', phase: 'Deploy', modules: ['shop']),
  _StepDef(key: 'stripe_events_webhook_secret_set', label: 'STRIPE_EVENTS_WEBHOOK_SECRET set', phase: 'Deploy', modules: ['events']),
  // Post-Deploy
  _StepDef(key: 'favicon_replaced', label: 'Favicon + PWA icons replaced', phase: 'Post-Deploy'),
  _StepDef(key: 'og_image_set', label: 'OG image uploaded and URL set', phase: 'Post-Deploy'),
  _StepDef(key: 'master_user_created', label: 'Master user created (role: master)', phase: 'Post-Deploy'),
  _StepDef(key: 'supabase_2fa_enabled', label: 'Supabase 2FA enabled', phase: 'Post-Deploy'),
  _StepDef(key: 'test_data_cleared', label: 'Test data cleared', phase: 'Post-Deploy'),
  _StepDef(key: 'search_console_verified', label: 'Search Console + sitemap submitted', phase: 'Post-Deploy'),
  _StepDef(key: 'uptime_robot_active', label: 'UptimeRobot monitor active', phase: 'Post-Deploy', isAuto: true),
  _StepDef(key: 'storage_bucket_created', label: 'Supabase Storage bucket created (Public)', phase: 'Post-Deploy', modules: ['gallery']),
  _StepDef(key: 'expire_bookings_cron', label: 'expire-pending-bookings cron scheduled', phase: 'Post-Deploy', modules: ['booking']),
  _StepDef(key: 'send_reminders_cron', label: 'send-reminders cron scheduled', phase: 'Post-Deploy', modules: ['booking']),
  _StepDef(key: 'send_review_requests_cron', label: 'send-review-requests cron scheduled', phase: 'Post-Deploy', modules: ['google_reviews']),
  // QA
  _StepDef(key: 'smoke_test_passed', label: 'End-to-end smoke test passed', phase: 'QA'),
  _StepDef(key: 'qa_booking', label: 'QA: test booking end-to-end', phase: 'QA', modules: ['booking']),
  _StepDef(key: 'qa_shop', label: 'QA: test shop checkout', phase: 'QA', modules: ['shop']),
  _StepDef(key: 'qa_events', label: 'QA: test event ticket purchase', phase: 'QA', modules: ['events']),
  _StepDef(key: 'qa_newsletter', label: 'QA: test newsletter + welcome email', phase: 'QA', modules: ['newsletter']),
  // Handover
  _StepDef(key: 'handover_email_sent', label: 'Handover email sent', phase: 'Handover', isAuto: true),
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
            _ProgressHeader(checked: checked, total: total, done: done),
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

      widgets.add(_PhaseLabel(phase));
      widgets.add(const SizedBox(height: 6));
      for (final row in phaseRows) {
        final def = _stepByKey[row['step'] as String? ?? ''];
        if (def == null) continue;
        widgets.add(_StepRow(
          def: def,
          checked: row['checked'] == true,
          checkedBy: row['checked_by'] as String?,
          checkedAt: row['checked_at'] as String?,
          onToggle: def.isAuto
              ? null
              : (v) => widget.ctrl.toggleDeliveryStep(widget.quoteId, def.key, v),
        ));
      }
      widgets.add(const SizedBox(height: ESizes.md));
    }

    return widgets;
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.checked,
    required this.total,
    required this.done,
  });
  final int checked;
  final int total;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = total > 0 ? checked / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                done ? 'Delivered ✓' : '$checked / $total steps complete',
                style: TextStyle(
                  color: done ? EColors.primary : EColors.textWhite,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(t * 100).round()}%',
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSizeLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: t,
            backgroundColor: EColors.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? EColors.primary : EColors.primary.withValues(alpha: 0.7),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel(this.phase);
  final String phase;

  @override
  Widget build(BuildContext context) => Text(
        phase.toUpperCase(),
        style: const TextStyle(
          color: EColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.def,
    required this.checked,
    required this.checkedBy,
    required this.checkedAt,
    required this.onToggle,
  });

  final _StepDef def;
  final bool checked;
  final String? checkedBy;
  final String? checkedAt;
  final void Function(bool)? onToggle;

  static String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = checkedBy == 'system';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 20,
            child: isSystem
                ? Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: checked
                        ? EColors.primary
                        : EColors.textSecondary.withValues(alpha: 0.4),
                  )
                : GestureDetector(
                    onTap: onToggle != null ? () => onToggle!(!checked) : null,
                    child: Icon(
                      checked
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: checked
                          ? EColors.primary
                          : EColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.label,
                  style: TextStyle(
                    color:
                        checked ? EColors.textWhite : EColors.textSecondary,
                    fontSize: ESizes.fontSizeLabel,
                    decoration: checked ? TextDecoration.lineThrough : null,
                    decorationColor: EColors.textSecondary,
                  ),
                ),
                if (checked && checkedAt != null)
                  Text(
                    '${isSystem ? 'System' : 'Admin'} · ${_fmtDate(checkedAt)}',
                    style: TextStyle(
                      color: EColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
