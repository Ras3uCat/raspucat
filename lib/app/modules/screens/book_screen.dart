import 'package:raspucat/app/controllers/booking_controller.dart';
import 'package:raspucat/app/modules/widgets/booking_widget.dart';
import 'package:raspucat/utils/constants/exports.dart';

part '_book_screen_form.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late final BookingController _bookingCtrl;
  final _isSubmitting = false.obs;
  final _successMessage = RxnString();
  final _errorMessage = RxnString();

  @override
  void initState() {
    super.initState();
    _bookingCtrl = Get.put(BookingController(sessionType: 'discovery_call'), tag: 'book_screen');
  }

  @override
  void dispose() {
    Get.delete<BookingController>(tag: 'book_screen');
    super.dispose();
  }

  Future<void> _submit({required String name, required String email, String? message}) async {
    if (_bookingCtrl.selectedSlot.value == null) return;
    _isSubmitting.value = true;
    _errorMessage.value = null;
    try {
      await _bookingCtrl.createBooking(name: name, email: email, message: message);
      _successMessage.value = 'Your session is booked — check your inbox for a confirmation.';
      _bookingCtrl.clearSelection();
    } catch (e) {
      _errorMessage.value = 'Booking failed. Please try again.';
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ESizes.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeonText(text: 'BOOK A CALL', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: ESizes.xs),
                  Text(
                    'Pick a date and time that works for you.',
                    style: TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeSm,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: ESizes.spaceBtwSections),
                  Obx(() {
                    if (_successMessage.value != null) {
                      return _BookConfirmation(message: _successMessage.value!);
                    }
                    return _BookBody(
                      bookingCtrl: _bookingCtrl,
                      isSubmitting: _isSubmitting,
                      errorMessage: _errorMessage,
                      onSubmit: _submit,
                    );
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

class _BookConfirmation extends StatelessWidget {
  const _BookConfirmation({required this.message});
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
            message,
            style: const TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
