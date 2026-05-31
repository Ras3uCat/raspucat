import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

class AdminSelfManagedSection extends StatelessWidget {
  const AdminSelfManagedSection({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.detail,
  });

  final AdminController ctrl;
  final String quoteId;
  final Map<String, dynamic> detail;

  static const _kGold = Color(0xFFFFB703);

  // Returns months active, or null if no subscription.
  static int? _monthsActive(String? isoDate) {
    if (isoDate == null) return null;
    final start = DateTime.tryParse(isoDate);
    if (start == null) return null;
    final now = DateTime.now();
    return (now.year - start.year) * 12 + (now.month - start.month);
  }

  @override
  Widget build(BuildContext context) {
    final hasSub = detail['subscription_started_at'] != null;
    final alreadySelfManaged = detail['management_option_id'] == 'handover';
    final isCancelled = detail['status'] == 'cancelled';

    if (!hasSub || alreadySelfManaged || isCancelled) return const SizedBox.shrink();

    final months = _monthsActive(detail['subscription_started_at'] as String?) ?? 0;
    final waived = months >= 12;
    final feeLabel = waived ? 'Fee waived (loyalty)' : '\$800 fee applies';
    final feeColor = waived ? EColors.primary : _kGold;

    return Obx(() {
      final state = ctrl.quoteState[quoteId] ?? {};
      final switching = state['switchingSelfManaged'] as bool? ?? false;
      final msg = state['selfManagedMsg'] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  '$months months active · ',
                  style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
                ),
                Text(
                  feeLabel,
                  style: TextStyle(
                    color: feeColor,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: switching
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: EColors.backgroundDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                          side: BorderSide(color: _kGold.withValues(alpha: 0.3)),
                        ),
                        title: const Text(
                          'Switch to Self-Managed?',
                          style: TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeMd),
                        ),
                        content: Text(
                          waived
                              ? 'Client has been active for $months months — loyalty waiver applies. '
                                    'The Stripe subscription will be cancelled immediately at \$0 fee. '
                                    'The handoff package will be sent to the client.'
                              : 'Client has been active for $months months (under 12). '
                                    'The Stripe subscription will be cancelled and a \$800 fee will be due — '
                                    'invoice manually via the Stripe dashboard after confirming.',
                          style: TextStyle(
                            color: EColors.textSecondary,
                            fontSize: ESizes.fontSizeSm,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: TextStyle(color: EColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Switch to Self-Managed', style: TextStyle(color: _kGold)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) ctrl.switchToSelfManaged(quoteId);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: ESizes.sm + 4),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(color: _kGold.withValues(alpha: 0.35)),
              ),
              alignment: Alignment.center,
              child: switching
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: _kGold, strokeWidth: 1.5),
                    )
                  : Text(
                      'Switch to Self-Managed',
                      style: TextStyle(
                        color: _kGold,
                        fontWeight: FontWeight.w600,
                        fontSize: ESizes.fontSizeSm,
                      ),
                    ),
            ),
          ),
          if (msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: msg.startsWith('✅') ? EColors.primary : const Color(0xFFFF4D4D),
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            ),
        ],
      );
    });
  }
}
