import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

// ---------------------------------------------------------------------------
// Cancelled banner — shown when status == 'cancelled'
// ---------------------------------------------------------------------------

class AdminCancelledBanner extends StatelessWidget {
  const AdminCancelledBanner({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.cancelledAt,
    required this.handoffReady,
    this.deliveryEmail,
  });
  final AdminController ctrl;
  final String quoteId;
  final String cancelledAt;
  final String? deliveryEmail;
  final bool handoffReady;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D4D).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: const Color(0xFFFF4D4D).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subscription Cancelled',
                  style: TextStyle(color: Color(0xFFFF4D4D),
                      fontWeight: FontWeight.w600, fontSize: ESizes.fontSizeSm)),
              const SizedBox(height: 4),
              Text('Cancelled on $cancelledAt',
                  style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.55),
                      fontSize: ESizes.fontSizeLabel)),
              if (deliveryEmail != null) ...[
                const SizedBox(height: 4),
                Text('Handoff sent to: $deliveryEmail',
                    style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.55),
                        fontSize: ESizes.fontSizeLabel)),
              ],
              const SizedBox(height: 4),
              Text(
                handoffReady ? 'Handoff package: Sent ✓' : 'Handoff package: Not sent',
                style: TextStyle(
                  color: handoffReady
                      ? EColors.primary.withValues(alpha: 0.7)
                      : const Color(0xFFFFB703).withValues(alpha: 0.7),
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AdminResendHandoffButton(ctrl: ctrl, quoteId: quoteId),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scheduled banner — shown when cancel_at_period_end is set
// ---------------------------------------------------------------------------

class AdminScheduledCancelBanner extends StatelessWidget {
  const AdminScheduledCancelBanner({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.cancelAt,
    required this.handoffReady,
    required this.handoffFeeCents,
    this.deliveryEmail,
    this.handoffInvoiceId,
  });
  final AdminController ctrl;
  final String quoteId;
  final String cancelAt;
  final String? deliveryEmail;
  final bool handoffReady;
  final int handoffFeeCents;
  final String? handoffInvoiceId;

  @override
  Widget build(BuildContext context) {
    final hasFee = handoffFeeCents > 0;
    final invoicePending = hasFee && handoffInvoiceId != null && !handoffReady;
    final invoiceLabel = invoicePending
        ? 'Awaiting handoff invoice payment'
        : (handoffReady ? 'Handoff package: Sent ✓' : 'Handoff package: Pending');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB703).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cancellation Scheduled',
                  style: TextStyle(color: Color(0xFFFFB703),
                      fontWeight: FontWeight.w600, fontSize: ESizes.fontSizeSm)),
              const SizedBox(height: 4),
              Text('Service ends: $cancelAt',
                  style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.55),
                      fontSize: ESizes.fontSizeLabel)),
              if (deliveryEmail != null) ...[
                const SizedBox(height: 4),
                Text('Delivery email: $deliveryEmail',
                    style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.55),
                        fontSize: ESizes.fontSizeLabel)),
              ],
              if (hasFee) ...[
                const SizedBox(height: 4),
                Text('Handoff fee: \$${(handoffFeeCents / 100).round()}',
                    style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.55),
                        fontSize: ESizes.fontSizeLabel)),
              ],
              const SizedBox(height: 4),
              Text(invoiceLabel,
                  style: TextStyle(
                    color: handoffReady
                        ? EColors.primary.withValues(alpha: 0.7)
                        : const Color(0xFFFFB703).withValues(alpha: 0.7),
                    fontSize: ESizes.fontSizeLabel,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AdminResendHandoffButton(ctrl: ctrl, quoteId: quoteId),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Resend handoff button — reusable across both banners
// ---------------------------------------------------------------------------

class AdminResendHandoffButton extends StatelessWidget {
  const AdminResendHandoffButton({super.key, required this.ctrl, required this.quoteId});
  final AdminController ctrl;
  final String quoteId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = ctrl.quoteState[quoteId] ?? {};
      final sending = state['sendingHandoff'] as bool? ?? false;
      final msg = state['handoffMsg'] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: sending ? null : () => ctrl.sendHandoff(quoteId),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: ESizes.sm + 2),
              decoration: BoxDecoration(
                color: EColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(color: EColors.primary.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: sending
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
                    )
                  : const Text('Resend Handoff Email',
                      style: TextStyle(color: EColors.primary,
                          fontWeight: FontWeight.w500, fontSize: ESizes.fontSizeSm)),
            ),
          ),
          if (msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(msg, textAlign: TextAlign.center,
                  style: TextStyle(
                    color: msg.startsWith('✅') ? EColors.primary : const Color(0xFFFF4D4D),
                    fontSize: ESizes.fontSizeLabel,
                  )),
            ),
        ],
      );
    });
  }
}
