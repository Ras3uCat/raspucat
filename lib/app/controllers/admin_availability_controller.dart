import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/booking_model.dart';

class AdminAvailabilityController extends GetxController {
  final _client = Supabase.instance.client;

  String _adminToken = '';
  void setToken(String token) => _adminToken = token;

  final rules = RxList<AvailabilityRule>([]);
  final blocks = RxList<AvailabilityBlock>([]);
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final successMessage = RxnString();

  static const _defaultRules = [
    AvailabilityRule(dayOfWeek: 0, startTime: '09:00', endTime: '17:00', enabled: false),
    AvailabilityRule(dayOfWeek: 1, startTime: '09:00', endTime: '17:00', enabled: true),
    AvailabilityRule(dayOfWeek: 2, startTime: '09:00', endTime: '17:00', enabled: true),
    AvailabilityRule(dayOfWeek: 3, startTime: '09:00', endTime: '17:00', enabled: true),
    AvailabilityRule(dayOfWeek: 4, startTime: '09:00', endTime: '17:00', enabled: true),
    AvailabilityRule(dayOfWeek: 5, startTime: '09:00', endTime: '17:00', enabled: true),
    AvailabilityRule(dayOfWeek: 6, startTime: '09:00', endTime: '17:00', enabled: false),
  ];

  // Called by AdminController after login — don't load on onInit (token not set yet).
  Future<void> loadAvailability() async {
    if (_adminToken.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final response = await _client.functions.invoke(
        'admin-manage-availability',
        method: HttpMethod.post,
        body: {'action': 'list', 'adminToken': _adminToken},
      );

      final data = response.data as Map<String, dynamic>?;
      final ruleList = (data?['rules'] as List<dynamic>? ?? [])
          .map((e) => AvailabilityRule.fromJson(e as Map<String, dynamic>))
          .toList();
      final blockList = (data?['blocks'] as List<dynamic>? ?? [])
          .map((e) => AvailabilityBlock.fromJson(e as Map<String, dynamic>))
          .toList();

      rules.assignAll(ruleList.isNotEmpty ? ruleList : _defaultRules);
      blocks.assignAll(blockList);
    } catch (e) {
      errorMessage.value = 'Failed to load availability: $e';
      if (rules.isEmpty) rules.assignAll(_defaultRules);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveRules(List<AvailabilityRule> updatedRules) async {
    isLoading.value = true;
    errorMessage.value = null;
    successMessage.value = null;
    try {
      await _client.functions.invoke(
        'admin-manage-availability',
        method: HttpMethod.post,
        body: {
          'action': 'set-rules',
          'adminToken': _adminToken,
          'rules': updatedRules.map((r) => r.toJson()).toList(),
        },
      );
      rules.assignAll(updatedRules);
      successMessage.value = 'Schedule saved.';
    } catch (e) {
      errorMessage.value = 'Failed to save rules: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> blockTime(DateTime from, DateTime until, String? reason) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final response = await _client.functions.invoke(
        'admin-manage-availability',
        method: HttpMethod.post,
        body: {
          'action': 'block-time',
          'adminToken': _adminToken,
          'blockedFrom': from.toUtc().toIso8601String(),
          'blockedUntil': until.toUtc().toIso8601String(),
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['blockId'] != null) {
        blocks.add(
          AvailabilityBlock(
            id: data!['blockId'] as String,
            from: from,
            until: until,
            reason: reason,
          ),
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to block time: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unblockTime(String blockId) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _client.functions.invoke(
        'admin-manage-availability',
        method: HttpMethod.post,
        body: {'action': 'unblock-time', 'adminToken': _adminToken, 'blockId': blockId},
      );
      blocks.removeWhere((b) => b.id == blockId);
    } catch (e) {
      errorMessage.value = 'Failed to remove block: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
