import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/controllers/manage_booking_controller.dart';
import 'package:raspucat/app/modules/widgets/booking_widget.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';
import 'package:raspucat/common/widgets/buttons/neon_button.dart';
import 'package:raspucat/common/widgets/text/neon_text.dart';

part '_manage_booking_actions.dart';

class ManageBookingScreen extends GetView<ManageBookingController> {
  const ManageBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ESizes.xl),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeonText(
                    text: 'MANAGE BOOKING',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: ESizes.spaceBtwSections),
                  Obx(() {
                    if (controller.successMessage.value != null) {
                      return _SuccessState(message: controller.successMessage.value!);
                    }
                    if (controller.isLoadingDetails.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: ESizes.xl),
                          child: CircularProgressIndicator(
                            color: EColors.primary,
                            strokeWidth: 1.5,
                          ),
                        ),
                      );
                    }
                    if (controller.errorMessage.value != null && !controller.isCancelled.value) {
                      return _ErrorState(message: controller.errorMessage.value!);
                    }
                    return _ActiveState(ctrl: controller);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Active state ─────────────────────────────────────────────────────────────

class _ActiveState extends StatelessWidget {
  const _ActiveState({required this.ctrl});
  final ManageBookingController ctrl;

  @override
  Widget build(BuildContext context) {
    final details = ctrl.bookingDetails.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (details != null) _BookingDetailsCard(details: details),
        const SizedBox(height: ESizes.lg),
        const _Divider(label: 'CANCEL'),
        const SizedBox(height: ESizes.md),
        Text(
          'Remove this booking entirely. You\'ll receive a confirmation email.',
          style: TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSizeLabel,
            height: 1.5,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        _CancelConfirmButton(ctrl: ctrl),
        const SizedBox(height: ESizes.lg),
        const _Divider(label: 'RESCHEDULE'),
        const SizedBox(height: ESizes.md),
        Text(
          'Pick a new date and time for this session.',
          style: TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSizeLabel,
            height: 1.5,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        _RescheduleSection(ctrl: ctrl),
        if (ctrl.errorMessage.value != null)
          Padding(
            padding: const EdgeInsets.only(top: ESizes.md),
            child: Text(
              ctrl.errorMessage.value!,
              style: const TextStyle(color: Colors.redAccent, fontSize: ESizes.fontSizeLabel),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: ESizes.sm),
        Expanded(child: Divider(color: EColors.primary.withValues(alpha: 0.25), height: 1)),
      ],
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({required this.details});
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final label =
        details['sessionLabel'] as String? ?? details['sessionType'] as String? ?? 'Session';
    final formattedTime =
        details['formattedTime'] as String? ?? details['startAt'] as String? ?? '';
    final status = details['status'] as String? ?? 'confirmed';

    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: EColors.primary, size: 14),
              const SizedBox(width: ESizes.xs),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              if (status == 'cancelled') ...[
                const SizedBox(width: ESizes.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CANCELLED',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ESizes.sm),
          Text(
            formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: ESizes.fontSizeMd,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Terminal states ──────────────────────────────────────────────────────────

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.xl),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: EColors.primary,
            size: ESizes.iconLg,
          ),
          const SizedBox(height: ESizes.md),
          Text(
            message.toUpperCase(),
            style: const TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: ESizes.fontSizeSm),
        textAlign: TextAlign.center,
      ),
    );
  }
}
