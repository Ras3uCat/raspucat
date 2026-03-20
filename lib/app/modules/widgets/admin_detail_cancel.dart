import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final hasSub = detail['subscription_started_at'] != null;
    if (!hasSub) return const SizedBox.shrink();

    return Obx(() {
      final state = ctrl.quoteState[quoteId] ?? {};
      final cancelling = state['cancellingSubscription'] as bool? ?? false;
      final cancelMsg = state['cancelMsg'] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: cancelling ? null : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: EColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                    side: BorderSide(
                      color: const Color(0xFFFF4D4D).withValues(alpha: 0.3),
                    ),
                  ),
                  title: const Text(
                    'Cancel Subscription?',
                    style: TextStyle(
                      color: EColors.textWhite,
                      fontSize: ESizes.fontSizeMd,
                    ),
                  ),
                  content: Text(
                    'This will immediately cancel the Stripe subscription and notify the client. This cannot be undone.',
                    style: TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeSm,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Keep',
                        style: TextStyle(color: EColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Cancel Subscription',
                        style: TextStyle(color: Color(0xFFFF4D4D)),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) ctrl.cancelSubscription(quoteId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: ESizes.sm + 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(
                  color: const Color(0xFFFF4D4D).withValues(alpha: 0.4),
                ),
              ),
              alignment: Alignment.center,
              child: cancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4D4D),
                        strokeWidth: 1.5,
                      ),
                    )
                  : const Text(
                      'Cancel Subscription',
                      style: TextStyle(
                        color: Color(0xFFFF4D4D),
                        fontWeight: FontWeight.w600,
                        fontSize: ESizes.fontSizeSm,
                      ),
                    ),
            ),
          ),
          if (cancelMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                cancelMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cancelMsg.startsWith('✅')
                      ? EColors.primary
                      : const Color(0xFFFF4D4D),
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            ),
        ],
      );
    });
  }
}
