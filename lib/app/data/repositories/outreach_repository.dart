import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/lead_model.dart';
import 'package:raspucat/app/data/models/industry_profile_model.dart';

abstract class OutreachRepository {
  Future<List<LeadModel>> listLeads({String? status, int limit, int offset});
  Future<LeadModel> createLead(Map<String, dynamic> fields);
  Future<LeadModel> updateLead(String leadId, Map<String, dynamic> fields);
  Future<void> deleteLead(String leadId);

  Future<List<OutreachEmailModel>> listDrafts({String? leadId});
  Future<OutreachEmailModel> createDraft(String leadId, String subject, String bodyHtml);
  Future<void> deleteDraft(String emailId);
  Future<void> sendEmail(String emailId);
  Future<Map<String, int>> sendBatch();

  Future<OutreachSettings?> getSettings();
  Future<OutreachSettings> updateSettings(OutreachSettings settings);

  Future<Map<String, dynamic>> runDiscovery({List<String>? industries, List<String>? cities});
  Future<void> runDiscoveryAction(String action);
  Future<List<IndustryProfileModel>> listIndustryProfiles();
  Future<IndustryProfileModel> syncIndustryProfile(IndustryProfileModel profile);
  Future<LeadModel> syncLeadReports(
    String leadId, {
    String? blueprintMd,
    String? brandBriefHtml,
    String? competitorHtml,
    String? brandAlignmentHtml,
    String? customPlanMd,
  });
}

class SupabaseOutreachRepository implements OutreachRepository {
  SupabaseOutreachRepository(this._adminToken);

  final String _adminToken;
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> _invoke(String fn, Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(
      fn,
      method: HttpMethod.post,
      body: {'adminToken': _adminToken, ...body},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<LeadModel>> listLeads({String? status, int limit = 100, int offset = 0}) async {
    final data = await _invoke('admin-leads', {
      'action': 'list',
      if (status != null) 'status': status,
      'limit': limit,
      'offset': offset,
    });
    return (data['leads'] as List<dynamic>? ?? [])
        .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeadModel> createLead(Map<String, dynamic> fields) async {
    final data = await _invoke('admin-leads', {'action': 'create', ...fields});
    return LeadModel.fromJson(data['lead'] as Map<String, dynamic>);
  }

  @override
  Future<LeadModel> updateLead(String leadId, Map<String, dynamic> fields) async {
    final data = await _invoke('admin-leads', {'action': 'update', 'leadId': leadId, ...fields});
    return LeadModel.fromJson(data['lead'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteLead(String leadId) async {
    await _invoke('admin-leads', {'action': 'delete', 'leadId': leadId});
  }

  @override
  Future<List<OutreachEmailModel>> listDrafts({String? leadId}) async {
    final data = await _invoke('admin-outreach-email', {
      'action': 'list-drafts',
      if (leadId != null) 'leadId': leadId,
    });
    return (data['drafts'] as List<dynamic>? ?? [])
        .map((e) => OutreachEmailModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OutreachEmailModel> createDraft(String leadId, String subject, String bodyHtml) async {
    final data = await _invoke('admin-outreach-email', {
      'action': 'draft',
      'leadId': leadId,
      'subject': subject,
      'bodyHtml': bodyHtml,
    });
    return OutreachEmailModel.fromJson(data['email'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDraft(String emailId) async {
    await _invoke('admin-outreach-email', {'action': 'delete-draft', 'emailId': emailId});
  }

  @override
  Future<void> sendEmail(String emailId) async {
    await _invoke('admin-outreach-email', {'action': 'send', 'emailId': emailId});
  }

  @override
  Future<Map<String, int>> sendBatch() async {
    final data = await _invoke('admin-outreach-email', {'action': 'send-batch'});
    return {
      'sent': (data['sent'] as num? ?? 0).toInt(),
      'failed': (data['failed'] as num? ?? 0).toInt(),
    };
  }

  @override
  Future<OutreachSettings?> getSettings() async {
    final data = await _invoke('admin-outreach-email', {'action': 'settings-get'});
    final raw = data['settings'];
    if (raw == null) return null;
    return OutreachSettings.fromJson(raw as Map<String, dynamic>);
  }

  @override
  Future<OutreachSettings> updateSettings(OutreachSettings settings) async {
    final data = await _invoke('admin-outreach-email', {
      'action': 'settings-update',
      ...settings.toJson(),
    });
    return OutreachSettings.fromJson(data['settings'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> runDiscovery({
    List<String>? industries,
    List<String>? cities,
  }) async {
    final data = await _invoke('admin-lead-discovery', {
      'action': 'run',
      if (industries != null) 'industries': industries,
      if (cities != null) 'cities': cities,
    });
    return data;
  }

  @override
  Future<void> runDiscoveryAction(String action) async {
    await _invoke('admin-lead-discovery', {'action': action});
  }

  @override
  Future<List<IndustryProfileModel>> listIndustryProfiles() async {
    final data = await _invoke('admin-leads', {'action': 'list-industries'});
    return (data['profiles'] as List<dynamic>? ?? [])
        .map((e) => IndustryProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<IndustryProfileModel> syncIndustryProfile(IndustryProfileModel profile) async {
    final data = await _invoke('admin-leads', {'action': 'sync-industry', ...profile.toJson()});
    return IndustryProfileModel.fromJson(data['profile'] as Map<String, dynamic>);
  }

  @override
  Future<LeadModel> syncLeadReports(
    String leadId, {
    String? blueprintMd,
    String? brandBriefHtml,
    String? competitorHtml,
    String? brandAlignmentHtml,
    String? customPlanMd,
  }) async {
    final data = await _invoke('admin-leads', {
      'action': 'sync-reports',
      'leadId': leadId,
      if (blueprintMd != null) 'blueprintMd': blueprintMd,
      if (brandBriefHtml != null) 'brandBriefHtml': brandBriefHtml,
      if (competitorHtml != null) 'competitorHtml': competitorHtml,
      if (brandAlignmentHtml != null) 'brandAlignmentHtml': brandAlignmentHtml,
      if (customPlanMd != null) 'customPlanMd': customPlanMd,
    });
    return LeadModel.fromJson(data['lead'] as Map<String, dynamic>);
  }
}
