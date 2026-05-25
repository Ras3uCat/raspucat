import 'package:raspucat/app/controllers/booking_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Required Supabase table:
// create table contact_submissions (
//   id uuid primary key default gen_random_uuid(),
//   created_at timestamptz default now(),
//   name text not null,
//   email text not null,
//   message text not null,
//   read boolean default false
// );
// Enable RLS and add: allow insert for anon role.

class ContactController extends GetxController {
  static ContactController get instance => Get.find();

  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final messageCtrl = TextEditingController();

  final isSubmitting = false.obs;
  final isSubmitted = false.obs;
  final errorMessage = RxnString();
  final bookingEnabled = false.obs;
  final meetUrl = RxnString();

  BookingController? _bookingCtrl;

  bool get hasBooking => _bookingCtrl?.selectedSlot.value != null;

  void attachBookingController(BookingController ctrl) {
    _bookingCtrl = ctrl;
  }

  void detachBookingController() {
    _bookingCtrl = null;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    messageCtrl.dispose();
    _bookingCtrl = null;
    super.onClose();
  }

  String? validateRequired(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final valid = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());
    return valid ? null : 'Enter a valid email';
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    isSubmitting.value = true;
    errorMessage.value = null;
    try {
      await Supabase.instance.client.from('contact_submissions').insert({
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'message': messageCtrl.text.trim(),
      });

      if (hasBooking && _bookingCtrl != null) {
        try {
          final result = await _bookingCtrl!.createBooking(
            name: nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            message: messageCtrl.text.trim(),
          );
          meetUrl.value = result['meetUrl'] as String?;
        } catch (e) {
          // Booking failure does not block contact submission success
          // ignore: avoid_print
          print('[ContactController] booking error: $e');
        }
      }

      isSubmitted.value = true;
    } catch (e) {
      errorMessage.value = 'Transmission failed: $e';
      // ignore: avoid_print
      print('[ContactController] submit error: $e');
    } finally {
      isSubmitting.value = false;
    }
  }
}
