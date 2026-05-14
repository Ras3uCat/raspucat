import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicStats {
  const PublicStats({
    required this.projectsDeployed,
    required this.activeClients,
    required this.uptimePct,
  });

  final int projectsDeployed;
  final int activeClients;
  final int uptimePct;

  factory PublicStats.fromJson(Map<String, dynamic> json) => PublicStats(
    projectsDeployed: (json['projects_deployed'] as num).toInt(),
    activeClients: (json['active_clients'] as num).toInt(),
    uptimePct: (json['uptime_pct'] as num).toInt(),
  );
}

class PublicStatsRepository {
  final _client = Supabase.instance.client;

  Future<PublicStats> fetchStats() async {
    final raw = await _client.rpc('get_public_stats');
    debugPrint('[PublicStatsRepo] type=${raw.runtimeType} val=$raw');
    final Map<String, dynamic> data = switch (raw) {
      String s => jsonDecode(s) as Map<String, dynamic>,
      Map m => Map<String, dynamic>.from(m),
      _ => throw FormatException('unexpected: ${raw.runtimeType}'),
    };
    return PublicStats.fromJson(data);
  }
}
