import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/controllers/booking_controller.dart';
import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/modules/widgets/booking_widget.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';
import 'package:raspucat/common/widgets/buttons/neon_button.dart';
import 'package:raspucat/common/widgets/text/neon_text.dart';

class PortalBookingView extends StatefulWidget {
  const PortalBookingView({super.key});

  @override
  State<PortalBookingView> createState() => _PortalBookingViewState();
}

class _PortalBookingViewState extends State<PortalBookingView> {
  late final BookingController _bookingCtrl;
  final _isSubmitting = false.obs;
  final _successMessage = RxnString();
  final _errorMessage = RxnString();

  @override
  void initState() {
    super.initState();
    _bookingCtrl = Get.put(
      BookingController(sessionType: 'project_checkin'),
      tag: 'portal_booking',
    );
  }

  @override
  void dispose() {
    Get.delete<BookingController>(tag: 'portal_booking');
    super.dispose();
  }

  Future<void> _book() async {
    if (_bookingCtrl.selectedSlot.value == null) return;
    final portalCtrl = Get.find<PortalController>();
    final quoteId = portalCtrl.activeQuote?.id;

    _isSubmitting.value = true;
    _errorMessage.value = null;
    try {
      final user = portalCtrl.activeQuote;
      await _bookingCtrl.createBooking(
        name: user?.businessName ?? '',
        email: user?.clientEmail ?? '',
        quoteId: quoteId,
      );
      _successMessage.value = 'Check-in session booked.';
      _bookingCtrl.clearSelection();
    } catch (e) {
      _errorMessage.value = 'Booking failed: $e';
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonText(
            text: 'BOOK A CHECK-IN',
            isHeadline: false,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: EColors.primary, letterSpacing: 2.0),
          ),
          const SizedBox(height: ESizes.xs),
          const Text(
            'Schedule a project check-in session.',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
          ),
          const SizedBox(height: ESizes.lg),
          Obx(() {
            if (_successMessage.value != null) {
              return _BookingSuccess(message: _successMessage.value!);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BookingWidget(controller: _bookingCtrl),
                const SizedBox(height: ESizes.lg),
                if (_errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: ESizes.md),
                    child: Text(
                      _errorMessage.value!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: ESizes.fontSizeLabel,
                      ),
                    ),
                  ),
                Obx(
                  () => NeonButton(
                    onTap: _bookingCtrl.selectedSlot.value == null || _isSubmitting.value
                        ? null
                        : _book,
                    padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                    child: _isSubmitting.value
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: EColors.primary,
                            ),
                          )
                        : const Text(
                            'BOOK SESSION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: EColors.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              fontSize: ESizes.fontSizeSm,
                            ),
                          ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BookingSuccess extends StatelessWidget {
  const _BookingSuccess({required this.message});
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
