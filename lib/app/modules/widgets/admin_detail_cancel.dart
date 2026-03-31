import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_cancel_banners.dart';

class AdminDetailCancel extends StatelessWidget {
  const AdminDetailCancel({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.detail,
  });

  final AdminController ctrl;
  final String quoteId;
  final Map<String, dynamic> detail;

  static const _kRed = Color(0xFFFF4D4D);
  static const _kAmber = Color(0xFFFFB703);

  String _fmtDate(String? ts) {
    if (ts == null) return '—';
    final d = DateTime.tryParse(ts);
    if (d == null) return '—';
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = detail['status'] as String? ?? '';
    final isCancelled = status == 'cancelled';
    final hasSub = detail['subscription_started_at'] != null;
    final cancelAt = detail['subscription_cancel_at'] as String?;
    final cancelledAt = detail['cancelled_at'] as String?;
    final deliveryEmail = detail['delivery_email'] as String?;
    final handoffFeeCents = detail['handoff_fee_cents'] as int? ?? 0;
    final handoffReady = detail['handoff_package_ready'] as bool? ?? false;
    final handoffInvoiceId = detail['handoff_invoice_id'] as String?;

    if (isCancelled) {
      return AdminCancelledBanner(
        ctrl: ctrl,
        quoteId: quoteId,
        cancelledAt: _fmtDate(cancelledAt),
        deliveryEmail: deliveryEmail,
        handoffReady: handoffReady,
      );
    }

    if (cancelAt != null) {
      return AdminScheduledCancelBanner(
        ctrl: ctrl,
        quoteId: quoteId,
        cancelAt: _fmtDate(cancelAt),
        deliveryEmail: deliveryEmail,
        handoffReady: handoffReady,
        handoffFeeCents: handoffFeeCents,
        handoffInvoiceId: handoffInvoiceId,
      );
    }

    if (!hasSub) return const SizedBox.shrink();

    return Obx(() {
      final state = ctrl.quoteState[quoteId] ?? {};
      final cancelling = state['cancellingSubscription'] as bool? ?? false;
      final cancelMsg = state['cancelMsg'] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (handoffFeeCents > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Handoff fee: \$${(handoffFeeCents / 100).round()} — invoice sent on cancel',
                style: TextStyle(color: _kAmber.withValues(alpha: 0.7),
                    fontSize: ESizes.fontSizeLabel),
                textAlign: TextAlign.center,
              ),
            ),
          GestureDetector(
            onTap: cancelling ? null : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: EColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                    side: BorderSide(color: _kRed.withValues(alpha: 0.3)),
                  ),
                  title: const Text('Cancel Subscription?',
                      style: TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeMd)),
                  content: Text(
                    'This immediately cancels the Stripe subscription and triggers the handoff '
                    'emails (admin alert + client package). This cannot be undone.',
                    style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Keep', style: TextStyle(color: EColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cancel Subscription',
                          style: TextStyle(color: _kRed)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) ctrl.cancelSubscription(quoteId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: ESizes.sm + 4),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(color: _kRed.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: cancelling
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: _kRed, strokeWidth: 1.5))
                  : const Text('Cancel Subscription',
                      style: TextStyle(color: _kRed, fontWeight: FontWeight.w600,
                          fontSize: ESizes.fontSizeSm)),
            ),
          ),
          if (cancelMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(cancelMsg, textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cancelMsg.startsWith('✅') ? EColors.primary : _kRed,
                    fontSize: ESizes.fontSizeLabel,
                  )),
            ),
        ],
      );
    });
  }
}
