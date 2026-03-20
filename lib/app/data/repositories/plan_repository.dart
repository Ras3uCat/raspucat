import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/plan_model.dart';
import 'package:raspucat/app/data/models/module_model.dart';
import 'package:raspucat/app/data/models/management_option_model.dart';

class PlanRepository {
  final _client = Supabase.instance.client;

  Future<List<PlanModel>> fetchPlans() async {
    final response = await _client
        .from('plans')
        .select()
        .order('sort_order', ascending: true);
    return (response as List<dynamic>)
        .map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ModuleModel>> fetchModules() async {
    final response = await _client
        .from('modules')
        .select()
        .order('sort_order', ascending: true);
    return (response as List<dynamic>)
        .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ManagementOptionModel>> fetchManagementOptions() async {
    final response = await _client
        .from('management_options')
        .select()
        .order('sort_order', ascending: true);
    return (response as List<dynamic>)
        .map((e) => ManagementOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
