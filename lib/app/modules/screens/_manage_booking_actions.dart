part of 'manage_booking_screen.dart';

// ─── Cancel with confirmation step ───────────────────────────────────────────

class _CancelConfirmButton extends StatefulWidget {
  const _CancelConfirmButton({required this.ctrl});
  final ManageBookingController ctrl;

  @override
  State<_CancelConfirmButton> createState() => _CancelConfirmButtonState();
}

class _CancelConfirmButtonState extends State<_CancelConfirmButton> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    if (!_confirming) {
      return NeonButton(
        onTap: () => setState(() => _confirming = true),
        padding: const EdgeInsets.symmetric(vertical: ESizes.sm, horizontal: ESizes.md),
        child: const Text(
          'CANCEL BOOKING',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontSize: ESizes.fontSizeSm,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Are you sure? This cannot be undone.',
          style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
        ),
        const SizedBox(height: ESizes.sm),
        Row(
          children: [
            Expanded(
              child: NeonButton(
                onTap: () => setState(() => _confirming = false),
                padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
                child: const Text(
                  'KEEP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    fontSize: ESizes.fontSizeLabel,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ESizes.sm),
            Expanded(
              child: Obx(
                () => NeonButton(
                  onTap: widget.ctrl.isLoading.value ? null : widget.ctrl.cancel,
                  padding: const EdgeInsets.symmetric(vertical: ESizes.sm),
                  child: widget.ctrl.isLoading.value
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.redAccent,
                          ),
                        )
                      : const Text(
                          'YES, CANCEL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            fontSize: ESizes.fontSizeLabel,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Reschedule with expandable calendar ─────────────────────────────────────

class _RescheduleSection extends StatelessWidget {
  const _RescheduleSection({required this.ctrl});
  final ManageBookingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonButton(
            onTap: ctrl.toggleReschedule,
            padding: const EdgeInsets.symmetric(vertical: ESizes.sm, horizontal: ESizes.md),
            child: Text(
              ctrl.showReschedule.value ? 'HIDE CALENDAR' : 'PICK NEW TIME',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                fontSize: ESizes.fontSizeSm,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: ctrl.showReschedule.value
                ? Padding(
                    padding: const EdgeInsets.only(top: ESizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BookingWidget(controller: ctrl.bookingController),
                        const SizedBox(height: ESizes.md),
                        Obx(
                          () => NeonButton(
                            onTap:
                                ctrl.bookingController.selectedSlot.value == null ||
                                    ctrl.isLoading.value
                                ? null
                                : ctrl.reschedule,
                            padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                            child: ctrl.isLoading.value
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: EColors.primary,
                                    ),
                                  )
                                : const Text(
                                    'CONFIRM RESCHEDULE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: EColors.primary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      fontSize: ESizes.fontSizeSm,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
