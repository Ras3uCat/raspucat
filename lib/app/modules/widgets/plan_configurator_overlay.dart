import 'dart:ui';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/plans_controller.dart';
import 'package:raspucat/app/modules/widgets/price_summary_bar.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';
import 'package:raspucat/app/modules/widgets/configurator_footer.dart';
import 'package:raspucat/app/modules/widgets/modules_step.dart';
import 'package:raspucat/app/modules/widgets/management_step.dart';
import 'package:raspucat/app/modules/widgets/details_step.dart';
import 'package:raspucat/app/modules/widgets/payment_step.dart';
import 'package:raspucat/app/modules/widgets/confirmation_step.dart';

class PlanConfiguratorOverlay extends StatelessWidget {
  const PlanConfiguratorOverlay({super.key, required this.plan});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final ctrl = PlansController.instance;
    final state = ConfiguratorState(plan: plan, modules: ctrl.modules);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Get.back(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: EColors.backgroundDark.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          Center(
            child: _ConfiguratorPanel(plan: plan, state: state, ctrl: ctrl),
          ),
        ],
      ),
    );
  }
}

// ─── Panel ────────────────────────────────────────────────────────────────────

class _ConfiguratorPanel extends StatelessWidget {
  const _ConfiguratorPanel({
    required this.plan,
    required this.state,
    required this.ctrl,
  });

  final PlanModel plan;
  final ConfiguratorState state;
  final PlansController ctrl;

  static const _stepTitles = [
    'Modules',
    'Management',
    'Your Details',
    'Payment',
    'Confirmed!',
  ];

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.sizeOf(context).width;
    final double screenH = MediaQuery.sizeOf(context).height;
    final bool isMobile = EDeviceUtils.isMobileWidth(screenW);
    final panelW = isMobile ? screenW * 0.95 : (screenW * 0.6).clamp(400.0, 680.0);
    final panelH = screenH * 0.85;
    final accentColor = plan.isCustom ? EColors.accent : EColors.primary;
    final formKey = GlobalKey<FormState>();

    return Container(
      width: panelW,
      height: panelH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
        color: EColors.backgroundDark.withValues(alpha: 0.96),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.md, ESizes.sm, ESizes.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: accentColor.withValues(alpha: 0.15), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Obx(() {
                    final title = state.step.value < _stepTitles.length
                        ? _stepTitles[state.step.value]
                        : '';
                    return NeonText(
                      text: 'Configure ${plan.name} — $title',
                      neonColor: accentColor,
                      isHeadline: false,
                      style: const TextStyle(
                        fontSize: ESizes.fontSizeLg,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  const Spacer(),
                  NeonButton(
                    onTap: () => Get.back(),
                    padding: const EdgeInsets.all(ESizes.sm),
                    enableOverlay: false,
                    child: Icon(Icons.close, color: accentColor, size: 20),
                  ),
                ],
              ),
            ),
            // Body — step router
            Expanded(
              child: Obx(() {
                switch (state.step.value) {
                  case 0:
                    return ModulesStep(
                      plan: plan,
                      state: state,
                      modules: ctrl.modules,
                    );
                  case 1:
                    return ManagementStep(
                      state: state,
                      options: ctrl.managementOptions,
                    );
                  case 2:
                    return DetailsStep(state: state, formKey: formKey);
                  case 3:
                    return PaymentStep(state: state);
                  case 4:
                    return ConfirmationStep(plan: plan);
                  default:
                    return const SizedBox.shrink();
                }
              }),
            ),
            // Price bar (hidden on confirmation)
            Obx(() {
              if (state.step.value == 4) return const SizedBox.shrink();
              return PriceSummaryBar(
                plan: plan,
                setupPrice: state.computedSetup.value,
                selectedAddonCount: state.selectedAddonCount,
                addonSavings: state.addonSavings.value,
                selectedManagement: state.selectedManagement.value,
                isAnnual: state.isAnnual.value,
                promoDiscountCents: state.promoDiscountCents.value,
                appliedPromoCode: state.appliedPromoCode.value,
                promoSubscriptionLabel: state.promoSubscriptionLabel.value,
                subDiscountPct: state.subDiscountPct.value,
                subDiscountFixed: state.subDiscountFixed.value,
              );
            }),
            ConfiguratorFooter(plan: plan, state: state, formKey: formKey),
          ],
        ),
      ),
    );
  }
}
