import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/booking_model.dart';

class AdminAvailabilityController extends GetxController {
  final _client = Supabase.instance.client;

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

  @override
  void onInit() {
    super.onInit();
    loadAvailability();
  }

  Future<void> loadAvailability() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final response = await _client.functions.invoke(
        'admin-manage-availability',
        method: HttpMethod.post,
        body: {'action': 'list'},
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
        body: {'action': 'set-rules', 'rules': updatedRules.map((r) => r.toJson()).toList()},
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
          'action': 'block',
          'from': from.toUtc().toIso8601String(),
          'until': until.toUtc().toIso8601String(),
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['block'] != null) {
        blocks.add(AvailabilityBlock.fromJson(data!['block'] as Map<String, dynamic>));
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
        body: {'action': 'unblock', 'blockId': blockId},
      );
      blocks.removeWhere((b) => b.id == blockId);
    } catch (e) {
      errorMessage.value = 'Failed to remove block: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
