import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/data/repositories/public_stats_repository.dart';

class LandingController extends GetxController {
  final _repo = PublicStatsRepository();

  final projectsDeployed = 0.obs;
  final activeClients = 0.obs;
  final uptimePct = 99.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _repo.fetchStats();
      projectsDeployed.value = stats.projectsDeployed;
      activeClients.value = stats.activeClients;
      uptimePct.value = stats.uptimePct;
    } catch (e, st) {
      debugPrint('[LandingController] fetchStats error: $e\n$st');
    }
  }
}
