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
                  const SizedBox(height: ESizes.sm),
                  Text(
                    'Cancel or reschedule your session below.',
                    style: TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeSm,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: ESizes.spaceBtwSections),
                  Obx(() => _ManageBookingBody(ctrl: controller)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── State router ─────────────────────────────────────────────────────────────

class _ManageBookingBody extends StatelessWidget {
  const _ManageBookingBody({required this.ctrl});
  final ManageBookingController ctrl;

  @override
  Widget build(BuildContext context) {
    if (ctrl.successMessage.value != null) {
      return _SuccessState(message: ctrl.successMessage.value!);
    }
    if (ctrl.isLoadingDetails.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: ESizes.xl),
          child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
        ),
      );
    }
    if (ctrl.errorMessage.value != null && !ctrl.isCancelled.value) {
      return _ErrorState(message: ctrl.errorMessage.value!);
    }
    return _ActiveState(ctrl: ctrl);
  }
}

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
        if (details != null) const SizedBox(height: ESizes.lg),
        _ActionCard(
          label: 'CANCEL BOOKING',
          description: 'Remove this booking entirely.',
          icon: Icons.cancel_outlined,
          child: _CancelConfirmButton(ctrl: ctrl),
        ),
        const SizedBox(height: ESizes.md),
        _ActionCard(
          label: 'RESCHEDULE',
          description: 'Pick a new date and time.',
          icon: Icons.calendar_month_outlined,
          child: _RescheduleSection(ctrl: ctrl),
        ),
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

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({required this.details});
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final label =
        details['sessionLabel'] as String? ?? details['sessionType'] as String? ?? 'Session';
    final formattedTime =
        details['formattedTime'] as String? ?? details['startAt'] as String? ?? '';
    final meetUrl = details['meetUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR BOOKING',
            style: TextStyle(
              color: EColors.primary.withValues(alpha: 0.6),
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: ESizes.xs),
          Text(
            label,
            style: const TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeMd,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: ESizes.xs),
          Text(
            formattedTime,
            style: const TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (meetUrl != null) ...[
            const SizedBox(height: ESizes.sm),
            Text(
              'Google Meet link in your confirmation email',
              style: TextStyle(
                color: EColors.primary.withValues(alpha: 0.6),
                fontSize: ESizes.fontSizeLabel,
              ),
            ),
          ],
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
        color: EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
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
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: ESizes.fontSizeSm),
        textAlign: TextAlign.center,
      ),
    );
  }
}
