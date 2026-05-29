import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/booking_model.dart';

abstract class BookingRepository {
  Future<List<AvailabilitySlot>> getAvailableSlots(DateTime date);
  Future<Map<String, dynamic>> createBooking({
    required String sessionType,
    required AvailabilitySlot slot,
    required String name,
    required String email,
    String? message,
    String? quoteId,
    String? leadId,
  });
  Future<void> cancelBooking(String token);
  Future<void> rescheduleBooking(String token, AvailabilitySlot newSlot);
}

class SupabaseBookingRepository implements BookingRepository {
  final _client = Supabase.instance.client;

  @override
  Future<List<AvailabilitySlot>> getAvailableSlots(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _client.functions.invoke(
      'get-available-slots',
      method: HttpMethod.get,
      queryParameters: {'date': dateStr},
    );

    final data = response.data as Map<String, dynamic>?;
    final slots = (data?['slots'] as List<dynamic>? ?? [])
        .map((e) => AvailabilitySlot.fromUtcIso(e as String))
        .where((s) => !s.isPast)
        .toList();
    return slots;
  }

  @override
  Future<Map<String, dynamic>> createBooking({
    required String sessionType,
    required AvailabilitySlot slot,
    required String name,
    required String email,
    String? message,
    String? quoteId,
    String? leadId,
  }) async {
    final body = <String, dynamic>{
      'sessionType': sessionType,
      'startAt': slot.startAt.toUtc().toIso8601String(),
      'name': name,
      'email': email,
      if (message != null && message.isNotEmpty) 'message': message,
      if (quoteId != null) 'quoteId': quoteId,
      if (leadId != null) 'leadId': leadId,
    };

    final response = await _client.functions.invoke(
      'create-booking',
      method: HttpMethod.post,
      body: body,
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) throw Exception('No response from create-booking');
    return data;
  }

  @override
  Future<void> cancelBooking(String token) async {
    final response = await _client.functions.invoke(
      'manage-booking',
      method: HttpMethod.post,
      body: {'token': token, 'action': 'cancel'},
    );

    final data = response.data as Map<String, dynamic>?;
    if (data?['success'] != true) {
      throw Exception(data?['error'] ?? 'Cancel failed');
    }
  }

  @override
  Future<void> rescheduleBooking(String token, AvailabilitySlot newSlot) async {
    final response = await _client.functions.invoke(
      'manage-booking',
      method: HttpMethod.post,
      body: {
        'token': token,
        'action': 'reschedule',
        'newStartAt': newSlot.startAt.toUtc().toIso8601String(),
      },
    );

    final data = response.data as Map<String, dynamic>?;
    if (data?['success'] != true) {
      throw Exception(data?['error'] ?? 'Reschedule failed');
    }
  }
}
