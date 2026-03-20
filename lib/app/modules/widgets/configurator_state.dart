import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/utils/constants/exports.dart';

/// Holds all state and business logic for the plan configurator flow.
/// Steps: 0=Modules, 1=Management, 2=Details, 3=Payment, 4=Confirmation
class ConfiguratorState {
  ConfiguratorState({required this.plan, required List<ModuleModel> modules}) {
    _initSelections(modules);
  }

  final PlanModel plan;
  final RxInt step = 0.obs;
  final RxMap<String, bool> moduleSelections = <String, bool>{}.obs;
  final Rx<ManagementOptionModel?> selectedManagement =
      Rx<ManagementOptionModel?>(null);
  final RxInt computedSetup = 0.obs;
  final RxInt addonSavings = 0.obs;
  final RxBool isAnnual = false.obs;

  // Step 2 — client details
  String clientName = '';
  String clientEmail = '';
  String businessName = '';

  // Step 3 — payment
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString clientSecret = ''.obs;
  final RxString quoteId = ''.obs;

  void _initSelections(List<ModuleModel> modules) {
    for (final m in modules) {
      final locked = plan.lockedModuleIds.contains(m.id);
      moduleSelections[m.id] = locked;
    }
    _recalcSetup(modules);
  }

  bool isLocked(String moduleId) => plan.lockedModuleIds.contains(moduleId);

  bool isParentSelected(ModuleModel module, List<ModuleModel> modules) {
    if (module.upgradeOf == null) return true;
    final parent = modules.firstWhereOrNull((m) => m.id == module.upgradeOf);
    if (parent == null) return false;
    return moduleSelections[parent.id] ?? false;
  }

  void toggleModule(String id, bool value, List<ModuleModel> modules) {
    if (isLocked(id)) return;
    moduleSelections[id] = value;
    if (!value) {
      for (final m in modules) {
        if (m.upgradeOf != null) {
          final parent = modules.firstWhereOrNull((p) => p.id == id);
          if (parent != null && m.upgradeOf == parent.name) {
            moduleSelections[m.id] = false;
          }
        }
      }
    }
    _recalcSetup(modules);
  }

  void _recalcSetup(List<ModuleModel> modules) {
    int addonTotal = 0;
    for (final m in modules) {
      if (!isLocked(m.id) && (moduleSelections[m.id] ?? false)) {
        addonTotal += m.price;
      }
    }
    int savings = 0;
    if (plan.isCustom && addonTotal > 0) {
      final count = selectedAddonCount;
      final rate = count >= 9
          ? 0.15
          : count >= 6
          ? 0.10
          : count >= 3
          ? 0.05
          : 0.0;
      savings = (addonTotal * rate).round();
      addonTotal -= savings;
    }
    addonSavings.value = savings;
    computedSetup.value = plan.setupPrice + addonTotal;
  }

  int get selectedAddonCount {
    return moduleSelections.entries
        .where((e) => e.value && !isLocked(e.key))
        .length;
  }

  List<String> get selectedModuleIds {
    return moduleSelections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  /// Calls the create-payment-intent Edge Function and stores clientSecret + quoteId.
  /// Returns true on success, false on error (errorMessage will be set).
  Future<bool> createPaymentIntent() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
      if (publishableKey.isEmpty) {
        errorMessage.value = 'Stripe configuration missing.';
        return false;
      }

      final mgmt = selectedManagement.value;
      final response = await Supabase.instance.client.functions.invoke(
        'create-payment-intent',
        body: {
          'clientName': clientName,
          'clientEmail': clientEmail,
          'businessName': businessName,
          'planId': plan.id,
          'moduleIds': selectedModuleIds,
          'managementOptionId': mgmt?.id,
          'billingCycle': mgmt != null
              ? (mgmt.onetimePrice > 0 ? 'onetime' : isAnnual.value ? 'annual' : 'monthly')
              : null,
          'setupTotalCents': computedSetup.value,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['clientSecret'] == null) {
        errorMessage.value =
            (data?['error'] as String?) ?? 'Failed to initialise payment.';
        return false;
      }

      clientSecret.value = data['clientSecret'] as String;
      quoteId.value = (data['quoteId'] as String?) ?? '';
      return true;
    } catch (e) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
