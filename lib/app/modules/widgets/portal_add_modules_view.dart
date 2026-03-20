import 'package:raspucat/app/controllers/portal_modules_controller.dart';
import 'package:raspucat/app/data/models/pending_module_model.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:flutter/foundation.dart';

class PortalAddModulesView extends StatelessWidget {
  const PortalAddModulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PortalModulesController());

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
              color: EColors.primary, strokeWidth: 2),
        );
      }

      // Show inline payment panel when embedded element is mounted
      if (ctrl.showPaymentElement.value) {
        return _PaymentPanel(ctrl: ctrl);
      }

      // Show card choice dialog when prep is ready
      if (ctrl.checkoutPrep.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ctrl.checkoutPrep.value != null && !ctrl.showPaymentElement.value) {
            _showCardChoiceDialog(Get.context!, ctrl);
          }
        });
      }

      return RefreshIndicator(
        onRefresh: ctrl.loadModules,
        color: EColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(ESizes.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header
              Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: EColors.primary, size: 20),
                  const SizedBox(width: ESizes.sm),
                  const Text(
                    'Add Modules',
                    style: TextStyle(
                      color: EColors.textWhite,
                      fontSize: ESizes.fontSizeLg,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Expand your project with additional features.',
                style: TextStyle(
                  color: EColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: ESizes.fontSizeSm,
                ),
              ),
              const SizedBox(height: ESizes.xl),

              // Success banner
              if (ctrl.showSuccessBanner.value)
                _SuccessBanner(onDismiss: ctrl.dismissSuccessBanner),

              // Error banner
              if (ctrl.errorMessage.value.isNotEmpty)
                _ErrorBanner(
                  message: ctrl.errorMessage.value,
                  onRetry: ctrl.loadModules,
                ),

              // Pending modules section
              if (ctrl.pendingModules.isNotEmpty) ...[
                _SectionHeader('Pending Activation'),
                const SizedBox(height: ESizes.sm),
                ...ctrl.pendingModules.map((m) => _PendingModuleCard(module: m)),
                const SizedBox(height: ESizes.xl),
              ],

              // Available modules
              if (ctrl.availableModules.isNotEmpty) ...[
                _SectionHeader('Available Modules'),
                const SizedBox(height: ESizes.sm),
                ...ctrl.availableModules.map(
                  (m) => _ModuleCard(
                    module: m,
                    isCheckingOut: ctrl.checkingOut[m.id] == true,
                    onCheckout: () => ctrl.checkout(m.id, m.name),
                  ),
                ),
              ],

              if (ctrl.availableModules.isEmpty &&
                  ctrl.pendingModules.isEmpty &&
                  !ctrl.isLoading.value)
                _EmptyState(),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Banners
// ---------------------------------------------------------------------------

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.lg),
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        color: const Color(0xFF06D6A0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: const Color(0xFF06D6A0).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF06D6A0), size: 18),
          const SizedBox(width: ESizes.sm),
          const Expanded(
            child: Text(
              'Module purchased! It will be activated once our team reviews your request.',
              style: TextStyle(
                color: Color(0xFF06D6A0),
                fontSize: ESizes.fontSizeSm,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close,
                color: Color(0xFF06D6A0), size: 16),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.lg),
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border:
            Border.all(color: const Color(0xFFFF4D4D).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF4D4D), size: 18),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFFF4D4D), fontSize: ESizes.fontSizeSm),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(
                    color: EColors.primary, fontSize: ESizes.fontSizeLabel)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.isCheckingOut,
    required this.onCheckout,
  });
  final ModuleModel module;
  final bool isCheckingOut;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.md),
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.name,
                  style: const TextStyle(
                    color: EColors.textWhite,
                    fontSize: ESizes.fontSizeMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (module.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    module.description,
                    style: TextStyle(
                      color: EColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: ESizes.fontSizeSm,
                    ),
                  ),
                ],
                const SizedBox(height: ESizes.sm),
                Text(
                  module.displayPrice,
                  style: const TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSizeMd,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (module.priceNote != null)
                  Text(
                    module.priceNote!,
                    style: TextStyle(
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: ESizes.md),
          SizedBox(
            width: 130,
            child: NeonButton(
              onTap: isCheckingOut ? null : onCheckout,
              neonColor: EColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md, vertical: ESizes.sm),
              child: isCheckingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: EColors.textWhite, strokeWidth: 1.5),
                    )
                  : const Text(
                      'Add to Project',
                      style: TextStyle(
                        color: EColors.textWhite,
                        fontSize: ESizes.fontSizeLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingModuleCard extends StatelessWidget {
  const _PendingModuleCard({required this.module});
  final PendingModuleModel module;

  @override
  Widget build(BuildContext context) {
    final isInProgress = module.isAcknowledged;
    final statusColor = isInProgress ? EColors.primary : EColors.gold;
    final statusLabel = isInProgress ? 'In Progress' : 'Queued';
    final icon = isInProgress ? Icons.build_outlined : Icons.schedule;

    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm + 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 16),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              module.name,
              style: const TextStyle(
                color: EColors.textWhite,
                fontSize: ESizes.fontSizeSm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: EColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card choice dialog
// ---------------------------------------------------------------------------

void _showCardChoiceDialog(BuildContext context, PortalModulesController ctrl) {
  final prep = ctrl.checkoutPrep.value;
  if (prep == null) return;

  final brand = (prep.brand ?? 'card').toUpperCase();
  final last4 = prep.last4 ?? '????';
  final moduleName = ctrl.activeModuleName.value ?? 'this module';

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF060D1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
        side: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ESizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  ),
                  child: const Icon(Icons.credit_card, color: EColors.primary, size: 18),
                ),
                const SizedBox(width: ESizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeMd,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        moduleName,
                        style: TextStyle(
                          color: EColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: ESizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESizes.lg),

            // Saved card option
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                ctrl.payWithSavedCard();
              },
              child: Container(
                padding: const EdgeInsets.all(ESizes.md),
                decoration: BoxDecoration(
                  color: EColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  border: Border.all(color: EColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: EColors.primary, size: 18),
                    const SizedBox(width: ESizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$brand ending in $last4',
                            style: const TextStyle(
                              color: EColors.textWhite,
                              fontSize: ESizes.fontSizeSm,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Card on file',
                            style: TextStyle(
                              color: EColors.textSecondary.withValues(alpha: 0.45),
                              fontSize: ESizes.fontSizeLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: EColors.primary.withValues(alpha: 0.5), size: 14),
                  ],
                ),
              ),
            ),
            ),

            const SizedBox(height: ESizes.sm),

            // New card option
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                ctrl.payWithNewCard();
              },
              child: Container(
                padding: const EdgeInsets.all(ESizes.md),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  border: Border.all(color: EColors.textSecondary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_card_outlined, color: EColors.textSecondary.withValues(alpha: 0.5), size: 18),
                    const SizedBox(width: ESizes.sm),
                    Text(
                      'Use a different card',
                      style: TextStyle(
                        color: EColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: ESizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, color: EColors.textSecondary.withValues(alpha: 0.3), size: 14),
                  ],
                ),
              ),
            ),
            ),

            const SizedBox(height: ESizes.md),

            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ctrl.cancelPayment();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: EColors.textSecondary.withValues(alpha: 0.4),
                  fontSize: ESizes.fontSizeSm,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Inline payment panel
// ---------------------------------------------------------------------------

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.ctrl});
  final PortalModulesController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
      padding: const EdgeInsets.all(ESizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: EColors.textSecondary, size: 20),
                onPressed: ctrl.cancelPayment,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: ESizes.sm),
              Text(
                ctrl.activeModuleName.value ?? 'Add Module',
                style: const TextStyle(
                  color: EColors.textWhite,
                  fontSize: ESizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESizes.md),
          Text(
            'Enter your payment details',
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.5),
              fontSize: ESizes.fontSizeSm,
            ),
          ),
          const SizedBox(height: ESizes.lg),
          if (ctrl.paymentError.value != null)
            Container(
              margin: const EdgeInsets.only(bottom: ESizes.md),
              padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(color: const Color(0xFFFF4D4D).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF4D4D), size: 16),
                  const SizedBox(width: ESizes.sm),
                  Expanded(
                    child: Text(
                      ctrl.paymentError.value!,
                      style: const TextStyle(color: Color(0xFFFF4D4D), fontSize: ESizes.fontSizeSm),
                    ),
                  ),
                ],
              ),
            ),
          if (kIsWeb)
            Expanded(
              child: const HtmlElementView(viewType: 'stripe-payment-element'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ESizes.lg),
              child: Text(
                'Payment is not supported on this device. Please visit the portal on a desktop browser to complete your purchase.',
                style: TextStyle(
                  color: EColors.textWhite.withValues(alpha: 0.5),
                  fontSize: ESizes.fontSizeSm,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: ESizes.lg),
          NeonButton(
            onTap: ctrl.isPaying.value ? null : ctrl.confirmPayment,
            neonColor: EColors.primary,
            padding: const EdgeInsets.symmetric(vertical: ESizes.sm + 4),
            child: ctrl.isPaying.value
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
                  )
                : const Text(
                    'Pay',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EColors.textWhite,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
          const SizedBox(height: ESizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 12, color: EColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                'Secured by Stripe',
                style: TextStyle(
                  color: EColors.textSecondary.withValues(alpha: 0.4),
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              color: EColors.primary.withValues(alpha: 0.3), size: 40),
          const SizedBox(height: ESizes.md),
          Text(
            'All available modules added.',
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.4),
              fontSize: ESizes.fontSizeSm,
            ),
          ),
        ],
      ),
    );
  }
}
