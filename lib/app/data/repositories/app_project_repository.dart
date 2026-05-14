import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';

class AppProjectRepository {
  final _client = Supabase.instance.client;

  Future<List<AppProject>> fetchAll() async {
    final rows = await _client.from('app_projects').select().order('created_at', ascending: false);
    return rows.map((e) => AppProject.fromJson(e)).toList();
  }

  Future<AppProject> create(Map<String, dynamic> data) async {
    final row = await _client.from('app_projects').insert(data).select().single();
    return AppProject.fromJson(row);
  }

  Future<AppProject> update(String id, Map<String, dynamic> data) async {
    final row = await _client.from('app_projects').update(data).eq('id', id).select().single();
    return AppProject.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('app_projects').delete().eq('id', id);
  }

  Future<AppProject?> fetchBySlug(String slug) async {
    final row = await _client
        .from('app_projects')
        .select(
          'id, name, description, status, slug, web_url, app_store_url, play_store_url, tech_stack, created_at, updated_at',
        )
        .ilike('slug', slug)
        .maybeSingle();
    if (row == null) return null;
    return AppProject.fromJson(row);
  }
}
