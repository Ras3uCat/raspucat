import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/controllers/booking_controller.dart';
import 'package:raspucat/app/data/repositories/booking_repository.dart';

class ManageBookingController extends GetxController {
  ManageBookingController({BookingRepository? repository})
    : _repo = repository ?? SupabaseBookingRepository();

  final BookingRepository _repo;

  final isLoading = false.obs;
  final isLoadingDetails = true.obs;
  final errorMessage = Rx<String?>(null);
  final successMessage = Rx<String?>(null);
  final showReschedule = false.obs;
  final isCancelled = false.obs;
  final bookingDetails = Rx<Map<String, dynamic>?>(null);

  late final BookingController bookingController;

  String get _token {
    final param = Get.parameters['token'];
    if (param != null && param.isNotEmpty) return param;
    // Fallback for direct browser navigation where GetX may not parse query params
    if (kIsWeb) {
      return Uri.base.queryParameters['token'] ?? '';
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    bookingController = BookingController(sessionType: 'discovery_call');
    Get.put(bookingController, tag: 'manage_reschedule');
    if (_token.isEmpty) {
      errorMessage.value = 'Invalid or missing booking token.';
      isLoadingDetails.value = false;
    } else {
      _fetchBookingDetails();
    }
  }

  @override
  void onClose() {
    Get.delete<BookingController>(tag: 'manage_reschedule');
    super.onClose();
  }

  Future<void> _fetchBookingDetails() async {
    isLoadingDetails.value = true;
    try {
      bookingDetails.value = await _repo.getBookingByToken(_token);
    } catch (e) {
      errorMessage.value = 'Booking not found or link has expired.';
    } finally {
      isLoadingDetails.value = false;
    }
  }

  void toggleReschedule() {
    showReschedule.value = !showReschedule.value;
    if (!showReschedule.value) {
      bookingController.clearSelection();
    }
  }

  Future<void> cancel() async {
    if (_token.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repo.cancelBooking(_token);
      isCancelled.value = true;
      successMessage.value = 'Your booking has been cancelled.';
    } catch (e) {
      errorMessage.value = 'Failed to cancel booking: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reschedule() async {
    if (_token.isEmpty) return;
    final slot = bookingController.selectedSlot.value;
    if (slot == null) {
      errorMessage.value = 'Please select a new time slot first.';
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repo.rescheduleBooking(_token, slot);
      showReschedule.value = false;
      successMessage.value = 'Your booking has been rescheduled.';
    } catch (e) {
      errorMessage.value = 'Failed to reschedule: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
