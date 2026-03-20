import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalManageBillingButton extends StatelessWidget {
  const PortalManageBillingButton({super.key, required this.ctrl});
  final PortalController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = ctrl.isBillingPortalLoading.value;
      final error = ctrl.billingPortalError.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: loading ? null : ctrl.openBillingPortal,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.lg, vertical: ESizes.sm),
              decoration: BoxDecoration(
                color: EColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border:
                    Border.all(color: EColors.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: EColors.primary.withValues(alpha: 0.6),
                          ),
                        )
                      : Icon(Icons.credit_card_outlined,
                          size: 16,
                          color: EColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(width: ESizes.sm),
                  Text(
                    'Manage Billing',
                    style: TextStyle(
                      color: EColors.primary.withValues(alpha: 0.7),
                      fontSize: ESizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: ESizes.xs),
            Text(
              error,
              style: TextStyle(
                color: Colors.redAccent.withValues(alpha: 0.8),
                fontSize: ESizes.fontSizeLabel,
              ),
            ),
          ],
        ],
      );
    });
  }
}
