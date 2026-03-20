import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

/// Handles catalog data (plans, modules, management options) and quote form
/// actions (create / update). Kept separate from AdminController to respect
/// the 300-line-per-file constraint.
class AdminCatalogController extends GetxController {
  static AdminCatalogController get instance => Get.find();

  final RxList<dynamic> plans = <dynamic>[].obs;
  final RxList<dynamic> modules = <dynamic>[].obs;
  final RxList<dynamic> managementOptions = <dynamic>[].obs;

  String _adminToken = '';

  void setToken(String token) => _adminToken = token;

  void clearCatalog() {
    plans.clear();
    modules.clear();
    managementOptions.clear();
    _adminToken = '';
  }

  Future<void> fetchCatalog() async {
    try {
      final results = await Future.wait([
        Supabase.instance.client.from('plans').select().order('sort_order'),
        Supabase.instance.client.from('modules').select().order('sort_order'),
        Supabase.instance.client
            .from('management_options')
            .select()
            .order('sort_order'),
      ]);
      plans.assignAll(results[0] as List);
      modules.assignAll(results[1] as List);
      managementOptions.assignAll(results[2] as List);
    } catch (_) {
      // Leave catalog unchanged on error
    }
  }

  /// Returns true on success, false on failure.
  Future<bool> createQuote(Map<String, dynamic> data) async {
    if (_adminToken.isEmpty) return false;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-create-quote',
        body: {...data, 'adminToken': _adminToken},
      );
      final body = response.data as Map<String, dynamic>?;
      if (body?['error'] != null) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns true on success, false on failure.
  Future<bool> updateQuote(String quoteId, Map<String, dynamic> data) async {
    if (_adminToken.isEmpty) return false;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-update-quote',
        body: {...data, 'quoteId': quoteId, 'adminToken': _adminToken},
      );
      final body = response.data as Map<String, dynamic>?;
      if (body?['error'] != null) return false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
