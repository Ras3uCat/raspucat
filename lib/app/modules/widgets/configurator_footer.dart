import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';
import 'package:raspucat/app/data/services/stripe_payment_service.dart';

class ConfiguratorFooter extends StatelessWidget {
  const ConfiguratorFooter({
    super.key,
    required this.plan,
    required this.state,
    required this.formKey,
  });

  final PlanModel plan;
  final ConfiguratorState state;
  final GlobalKey<FormState> formKey;

  static const _nextLabels = [
    'Continue',                    // 0 → 1
    'Initiate Launch Sequence',    // 1 → 2
    'Review & Pay',                // 2 → 3
    'Launch Now',                  // 3 → confirm payment
  ];

  Future<void> _onNext() async {
    final s = state.step.value;

    if (s == 2) {
      if (!(formKey.currentState?.validate() ?? false)) return;
      formKey.currentState!.save();
      final ok = await state.createPaymentIntent();
      if (ok) state.step.value = 3;
      return;
    }

    if (s == 3) {
      state.isLoading.value = true;
      state.errorMessage.value = null;
      final error = await StripePaymentService.confirmPayment();
      state.isLoading.value = false;
      if (error != null) {
        state.errorMessage.value = error;
        return;
      }
      state.step.value = 4;
      return;
    }

    state.step.value = s + 1;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = plan.isCustom ? EColors.accent : EColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.lg,
        vertical: ESizes.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: accentColor.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Obx(() {
        final s = state.step.value;
        final loading = state.isLoading.value;
        final managementSelected = state.selectedManagement.value != null;

        if (s == 4) return const SizedBox.shrink();

        final isDisabled = loading || (s == 1 && !managementSelected);

        return Row(
          children: [
            if (s > 0)
              TextButton(
                onPressed: loading ? null : () => state.step.value = s - 1,
                child: Text(
                  'Back',
                  style: TextStyle(color: EColors.textSecondary),
                ),
              ),
            const Spacer(),
            NeonButton(
              onTap: isDisabled ? null : _onNext,
              neonColor: accentColor,
              padding: const EdgeInsets.symmetric(
                vertical: ESizes.sm + 4,
                horizontal: ESizes.lg,
              ),
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      s < _nextLabels.length ? _nextLabels[s] : 'Continue',
                      style: const TextStyle(
                        color: EColors.textWhite,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
