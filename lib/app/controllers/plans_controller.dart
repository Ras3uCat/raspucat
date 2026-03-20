import 'package:get/get.dart';
import 'package:raspucat/app/data/models/plan_model.dart';
import 'package:raspucat/app/data/models/module_model.dart';
import 'package:raspucat/app/data/models/management_option_model.dart';
import 'package:raspucat/app/data/repositories/plan_repository.dart';

class PlansController extends GetxController {
  static PlansController get instance => Get.find();

  final _repo = PlanRepository();

  final RxList<PlanModel> plans = <PlanModel>[].obs;
  final RxList<ModuleModel> modules = <ModuleModel>[].obs;
  final RxList<ManagementOptionModel> managementOptions =
      <ManagementOptionModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _repo.fetchPlans(),
        _repo.fetchModules(),
        _repo.fetchManagementOptions(),
      ]);
      final fetchedModules = results[1] as List<ModuleModel>;
      modules.assignAll(fetchedModules);
      managementOptions.assignAll(results[2] as List<ManagementOptionModel>);

      // Enrich each plan's feature list from its locked module names.
      // Custom has no locked modules — use a static descriptor list instead.
      const customFeatures = [
        'Core Site Included',
        'Contact form + lead capture',
        'Mobile Responsive & SEO-ready',
        'Choose from 17 add-on modules',
      ];
      final rawPlans = results[0] as List<PlanModel>;
      final proLockedIds = rawPlans
          .firstWhereOrNull((p) => p.id == 'pro')
          ?.lockedModuleIds ?? [];
      final enriched = rawPlans.map((plan) {
        if (plan.isCustom) return plan.withFeatures(customFeatures);
        final names = fetchedModules
            .where((m) => plan.lockedModuleIds.contains(m.id))
            .map((m) => m.name)
            .toList();
        if (plan.id == 'premium') {
          final proNames = fetchedModules
              .where((m) => proLockedIds.contains(m.id))
              .map((m) => m.name)
              .toSet();
          final unique = names.where((n) => !proNames.contains(n)).toList();
          return plan.withFeatures([...unique, '+ Pro included']);
        }
        return plan.withFeatures(names);
      }).toList();
      plans.assignAll(enriched);
    } catch (e) {
      // Silently fall back to static data if Supabase unavailable
    } finally {
      isLoading.value = false;
    }
  }
}
