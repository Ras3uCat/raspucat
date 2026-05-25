import 'package:get/get.dart';
import 'package:raspucat/app/data/models/booking_model.dart';
import 'package:raspucat/app/data/repositories/booking_repository.dart';

class BookingController extends GetxController {
  BookingController({String sessionType = 'discovery_call', BookingRepository? repository})
    : _sessionType = sessionType,
      _repo = repository ?? SupabaseBookingRepository();

  final String _sessionType;
  final BookingRepository _repo;

  final selectedDate = Rx<DateTime?>(null);
  final slots = RxList<AvailabilitySlot>([]);
  final selectedSlot = Rx<AvailabilitySlot?>(null);
  final isLoadingSlots = false.obs;
  final errorMessage = RxnString();

  String get sessionType => _sessionType;

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    selectedSlot.value = null;
    slots.clear();
    isLoadingSlots.value = true;
    errorMessage.value = null;
    try {
      final result = await _repo.getAvailableSlots(date);
      slots.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Failed to load slots';
    } finally {
      isLoadingSlots.value = false;
    }
  }

  void selectSlot(AvailabilitySlot slot) {
    selectedSlot.value = slot;
  }

  void clearSelection() {
    selectedDate.value = null;
    selectedSlot.value = null;
    slots.clear();
    errorMessage.value = null;
  }

  Future<Map<String, dynamic>> createBooking({
    required String name,
    required String email,
    String? message,
    String? quoteId,
  }) async {
    final slot = selectedSlot.value;
    if (slot == null) throw Exception('No slot selected');
    return _repo.createBooking(
      sessionType: _sessionType,
      slot: slot,
      name: name,
      email: email,
      message: message,
      quoteId: quoteId,
    );
  }
}
