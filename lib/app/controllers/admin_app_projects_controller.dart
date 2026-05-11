import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/data/repositories/app_project_repository.dart';

class AdminAppProjectsController extends GetxController {
  final _repo = AppProjectRepository();

  final projects = <AppProject>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();

  final provisioningIds = <String>{}.obs;
  final provisionMessages = <String, String>{}.obs;

  String get _adminToken => Get.find<AdminController>().adminToken;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    error.value = null;
    try {
      projects.value = await _repo.fetchAll();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<AppProject?> createProject(Map<String, dynamic> data) async {
    try {
      final created = await _repo.create(data);
      projects.insert(0, created);
      return created;
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }

  Future<void> updateProject(AppProject project) async {
    try {
      final updated = await _repo.update(project.id, project.toJson());
      final idx = projects.indexWhere((p) => p.id == project.id);
      if (idx != -1) projects[idx] = updated;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _repo.delete(id);
      projects.removeWhere((p) => p.id == id);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> provisionEmail(String projectId, String appName, {String? slugOverride}) async {
    provisioningIds.add(projectId);
    provisionMessages.remove(projectId);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-provision-app-email',
        body: {
          'projectId': projectId,
          'appName': appName,
          if (slugOverride != null) 'slugOverride': slugOverride,
          'adminToken': _adminToken,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        provisionMessages[projectId] = '✗ ${data!['error']}';
        return;
      }

      final email = data?['alias_email'] as String? ?? '';
      provisionMessages[projectId] = '✓ Provisioned: $email';
      await _refreshProject(projectId);
    } catch (e) {
      provisionMessages[projectId] = '✗ ${e.toString()}';
    } finally {
      provisioningIds.remove(projectId);
    }
  }

  Future<void> deprovisionEmail(String projectId) async {
    provisioningIds.add(projectId);
    provisionMessages.remove(projectId);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-deprovision-app-email',
        body: {'projectId': projectId, 'adminToken': _adminToken},
      );

      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        provisionMessages[projectId] = '✗ ${data!['error']}';
        return;
      }

      provisionMessages[projectId] = '✓ Deprovisioned.';
      await _refreshProject(projectId);
    } catch (e) {
      provisionMessages[projectId] = '✗ ${e.toString()}';
    } finally {
      provisioningIds.remove(projectId);
    }
  }

  Future<void> _refreshProject(String projectId) async {
    try {
      final all = await _repo.fetchAll();
      projects.value = all;
    } catch (_) {}
  }
}
