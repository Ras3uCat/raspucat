import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_form.dart';
import 'package:raspucat/app/modules/widgets/admin_form_widgets.dart';
import 'package:raspucat/app/modules/widgets/admin_site_health_section.dart';

class AdminQuoteRow extends StatelessWidget {
  const AdminQuoteRow({
    super.key,
    required this.quote,
    required this.state,
    required this.ctrl,
    required this.onTap,
    required this.onChargeBalance,
    required this.onStartSubscription,
    this.pendingModuleCount = 0,
    this.inProgressModuleCount = 0,
    this.unreadMessageCount = 0,
    this.newFileCount = 0,
  });

  final Map<String, dynamic> quote;
  final Map<String, dynamic> state;
  final AdminController ctrl;
  final VoidCallback onTap;
  final VoidCallback onChargeBalance;
  final VoidCallback onStartSubscription;
  final int pendingModuleCount;
  final int inProgressModuleCount;
  final int unreadMessageCount;
  final int newFileCount;

  static String _fmt(int? cents) {
    if (cents == null || cents == 0) return '—';
    final s = (cents / 100).round().toString();
    if (s.length <= 3) return '\$$s';
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  bool _hasUpdateAvailable(AdminController ctrl) {
    final current = ctrl.currentTemplateVersion.value;
    final installed = quote['template_version'] as String?;
    return current.isNotEmpty && installed != null && installed.isNotEmpty && installed != current;
  }

  bool get _canChargeBalance =>
      quote['status'] == 'deposit_paid' && (quote['balance_cents'] as int? ?? 0) > 0;

  bool get _isComped => quote['is_comped'] as bool? ?? false;

  bool get _canStartSub =>
      quote['billing_cycle'] != 'onetime' &&
      quote['activated_at'] == null &&
      quote['status'] != 'active' &&
      (_isComped || quote['stripe_payment_method_id'] != null);

  @override
  Widget build(BuildContext context) {
    final status = quote['status'] as String? ?? '';
    final (statusLabel, statusColor) = switch (status) {
      'active' => ('Active', EColors.primary),
      'fully_paid' => ('Fully Paid', EColors.primary),
      'deposit_paid' => ('Deposit Paid', EColors.gold),
      _ => ('Pending', EColors.textSecondary),
    };
    final chargingBalance = state['chargingBalance'] as bool? ?? false;
    final startingSub = state['startingSub'] as bool? ?? false;
    final chargeMsg = state['chargeMsg'] as String?;
    final subMsg = state['subMsg'] as String?;

    final isStale = state['isStale'] as bool? ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: EColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client + status row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote['client_name'] as String? ?? '',
                          style: const TextStyle(
                            color: EColors.textWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: ESizes.fontSizeMd,
                          ),
                        ),
                        Text(
                          quote['client_email'] as String? ?? '',
                          style: TextStyle(
                            color: EColors.textSecondary,
                            fontSize: ESizes.fontSizeLabel,
                          ),
                        ),
                        if ((quote['business_name'] as String? ?? '').isNotEmpty)
                          Text(
                            quote['business_name'] as String,
                            style: TextStyle(
                              color: EColors.textSecondary,
                              fontSize: ESizes.fontSizeLabel,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quote['status'] == 'pending')
                        Builder(
                          builder: (ctx) => GestureDetector(
                            onTap: () => AdminQuoteFormModal.show(ctx, ctrl, existingQuote: quote),
                            child: Padding(
                              padding: const EdgeInsets.only(right: ESizes.xs),
                              child: Icon(
                                Icons.edit_outlined,
                                color: EColors.textSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      if (_hasUpdateAvailable(ctrl)) ...[
                        _UpdateAvailablePill(
                          current: ctrl.currentTemplateVersion.value,
                          installed: quote['template_version'] as String? ?? '',
                        ),
                        const SizedBox(width: ESizes.xs),
                      ],
                      if (isStale) ...[
                        Tooltip(
                          message:
                              'Deposit paid over 7 days ago — consider charging the remaining balance or following up.',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
                            decoration: BoxDecoration(
                              color: EColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                              border: Border.all(color: EColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Stale',
                              style: TextStyle(
                                color: EColors.gold,
                                fontSize: ESizes.fontSizeLabel,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: ESizes.xs),
                      ],
                      if (unreadMessageCount > 0) ...[
                        _NewMessagePill(count: unreadMessageCount),
                        const SizedBox(width: ESizes.xs),
                      ],
                      if (newFileCount > 0) ...[
                        _NewFilePill(count: newFileCount),
                        const SizedBox(width: ESizes.xs),
                      ],
                      if (quote['has_pending_plan_change'] == true) ...[
                        const _PlanChangePill(),
                        const SizedBox(width: ESizes.xs),
                      ],
                      HealthBadgeDot(quote: quote),
                      if (pendingModuleCount > 0 || inProgressModuleCount > 0) ...[
                        _FeatureRequestedPill(
                          total: pendingModuleCount + inProgressModuleCount,
                          hasUnacknowledged: pendingModuleCount > 0,
                        ),
                        const SizedBox(width: ESizes.xs),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: ESizes.fontSizeLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: ESizes.sm),
              // Plan + financials
              Wrap(
                spacing: ESizes.md,
                runSpacing: 4,
                children: [
                  _InfoChip(
                    'Plan',
                    quote['plan_name'] as String? ?? quote['plan_id'] as String? ?? '—',
                  ),
                  _InfoChip('Deposit', _fmt(quote['deposit_cents'] as int?)),
                  _InfoChip('Balance', _fmt(quote['balance_cents'] as int?)),
                  if (quote['management_option_name'] != null)
                    _InfoChip(
                      'Management',
                      '${quote['management_option_name']} (${quote['billing_cycle'] ?? '—'})',
                    ),
                  if (!_isComped &&
                      (quote['subscription_amount_cents'] as int? ?? 0) > 0 &&
                      quote['billing_cycle'] != 'onetime')
                    _InfoChip(
                      'Sub',
                      '${_fmt(quote['subscription_amount_cents'] as int?)}${quote['billing_cycle'] == 'annual' ? '/yr' : '/mo'}',
                    ),
                  if (quote['subscription_started_at'] != null)
                    _InfoChip('Sub started', '✅ Active'),
                ],
              ),
              const SizedBox(height: ESizes.sm),
              // Action buttons
              Wrap(
                spacing: ESizes.sm,
                runSpacing: ESizes.sm,
                children: [
                  if (_canChargeBalance)
                    AdminActionButton(
                      label: 'Charge Remaining ${_fmt(quote['balance_cents'] as int?)}',
                      isLoading: chargingBalance,
                      onTap: onChargeBalance,
                      color: EColors.gold,
                    ),
                  if (_canStartSub)
                    AdminActionButton(
                      label: 'Start Subscription',
                      isLoading: startingSub,
                      onTap: onStartSubscription,
                      color: EColors.primary,
                    ),
                ],
              ),
              if (chargeMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    chargeMsg,
                    style: TextStyle(
                      color: chargeMsg.startsWith('✅') ? EColors.primary : const Color(0xFFFF4D4D),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                ),
              if (subMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subMsg,
                    style: TextStyle(
                      color: subMsg.startsWith('✅') ? EColors.primary : const Color(0xFFFF4D4D),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewMessagePill extends StatelessWidget {
  const _NewMessagePill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF38BDF8); // sky blue — distinct from gold/teal
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'New Message ($count)',
        style: const TextStyle(
          color: color,
          fontSize: ESizes.fontSizeLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NewFilePill extends StatelessWidget {
  const _NewFilePill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFA78BFA); // violet — distinct from sky blue / gold / teal
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'New File ($count)',
        style: const TextStyle(
          color: color,
          fontSize: ESizes.fontSizeLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlanChangePill extends StatelessWidget {
  const _PlanChangePill();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFB923C); // orange — distinct from existing pill colors
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'Plan Change',
        style: TextStyle(color: color, fontSize: ESizes.fontSizeLabel, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FeatureRequestedPill extends StatelessWidget {
  const _FeatureRequestedPill({required this.total, required this.hasUnacknowledged});
  final int total;
  final bool hasUnacknowledged;

  @override
  Widget build(BuildContext context) {
    // Gold = new/unseen; teal (primary) = acknowledged, in progress
    final color = hasUnacknowledged ? EColors.gold : EColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Feature Requested ($total)',
        style: TextStyle(color: color, fontSize: ESizes.fontSizeLabel, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _UpdateAvailablePill extends StatelessWidget {
  const _UpdateAvailablePill({required this.current, required this.installed});
  final String current;
  final String installed;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFBBF24); // amber
    return Tooltip(
      message: 'Template update available: $installed → $current',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: const Text(
          'Update Available',
          style: TextStyle(
            color: color,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: ESizes.fontSizeLabel),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: EColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: EColors.textWhite),
          ),
        ],
      ),
    );
  }
}
