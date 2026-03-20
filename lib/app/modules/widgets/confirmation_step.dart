import 'package:raspucat/utils/constants/exports.dart';

class ConfirmationStep extends StatelessWidget {
  const ConfirmationStep({super.key, required this.plan});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final accentColor = plan.isCustom ? EColors.accent : EColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ESizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: accentColor, size: 56),
            const SizedBox(height: ESizes.md),
            Text(
              'Deposit received!',
              style: TextStyle(
                color: EColors.textWhite,
                fontSize: ESizes.fontSizeLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESizes.sm),
            Text(
              "Check your inbox — a confirmation email is on its way.\nWe'll be in touch shortly to kick things off.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSizeSm,
                height: 1.6,
              ),
            ),
            const SizedBox(height: ESizes.lg),
            NeonButton(
              onTap: () => Get.back(),
              neonColor: accentColor,
              padding: const EdgeInsets.symmetric(
                vertical: ESizes.sm + 4,
                horizontal: ESizes.lg,
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: EColors.textWhite,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
