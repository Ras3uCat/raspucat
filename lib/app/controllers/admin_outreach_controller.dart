import 'package:get/get.dart';
import 'package:raspucat/app/data/models/lead_model.dart';
import 'package:raspucat/app/data/models/industry_profile_model.dart';
import 'package:raspucat/app/data/repositories/outreach_repository.dart';

class AdminOutreachController extends GetxController {
  String _adminToken = '';
  String get adminToken => _adminToken;
  void setToken(String token) {
    _adminToken = token;
    _repo = SupabaseOutreachRepository(token);
  }

  late OutreachRepository _repo;

  final leads = RxList<LeadModel>([]);
  final drafts = RxList<OutreachEmailModel>([]);
  final sentEmails = RxList<OutreachEmailModel>([]);
  final settings = Rx<OutreachSettings>(OutreachSettings.defaults);
  final industryProfiles = RxList<IndustryProfileModel>([]);
  final selectedLead = Rx<LeadModel?>(null);
  final activeSubTab = 0.obs; // 0=Pipeline, 1=Drafts, 2=Settings
  final selectedIndustryFilter = RxnString();
  final pipelineViewMode = 0.obs; // 0=list, 1=kanban
  final isLoading = false.obs;
  final isSending = false.obs;
  final isDiscovering = false.obs;
  final errorMessage = RxnString();
  final successMessage = RxnString();

  // Called by AdminController after login
  Future<void> loadSettings() async {
    if (_adminToken.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _repo.listLeads(),
        _repo.listDrafts(),
        _repo.getSettings(),
        _repo.listIndustryProfiles(),
        _repo.listSent(),
      ]);
      leads.assignAll(results[0] as List<LeadModel>);
      drafts.assignAll(results[1] as List<OutreachEmailModel>);
      final s = results[2] as OutreachSettings?;
      if (s != null) settings.value = s;
      industryProfiles.assignAll(results[3] as List<IndustryProfileModel>);
      sentEmails.assignAll(results[4] as List<OutreachEmailModel>);
    } catch (e) {
      errorMessage.value = 'Failed to load outreach data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadLeads() async {
    try {
      final result = await _repo.listLeads();
      leads.assignAll(result);
      if (selectedLead.value != null) {
        final updated = result.where((l) => l.id == selectedLead.value!.id).firstOrNull;
        selectedLead.value = updated;
      }
    } catch (e) {
      errorMessage.value = 'Failed to reload leads: $e';
    }
  }

  Future<void> createLead(Map<String, dynamic> fields) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final lead = await _repo.createLead(fields);
      leads.insert(0, lead);
      successMessage.value = 'Lead added.';
    } catch (e) {
      errorMessage.value = 'Failed to add lead: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLead(String leadId, Map<String, dynamic> fields) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final updated = await _repo.updateLead(leadId, fields);
      final idx = leads.indexWhere((l) => l.id == leadId);
      if (idx >= 0) leads[idx] = updated;
      if (selectedLead.value?.id == leadId) selectedLead.value = updated;
    } catch (e) {
      errorMessage.value = 'Failed to update lead: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteLead(String leadId) async {
    try {
      await _repo.deleteLead(leadId);
      leads.removeWhere((l) => l.id == leadId);
      if (selectedLead.value?.id == leadId) selectedLead.value = null;
    } catch (e) {
      errorMessage.value = 'Failed to delete lead: $e';
    }
  }

  Future<void> saveDraft(String leadId, String subject, String bodyHtml) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final draft = await _repo.createDraft(leadId, subject, bodyHtml);
      drafts.add(draft);
      successMessage.value = 'Draft saved.';
    } catch (e) {
      errorMessage.value = 'Failed to save draft: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDraft(String emailId, {String? subject, String? bodyHtml}) async {
    try {
      final updated = await _repo.updateDraft(emailId, subject: subject, bodyHtml: bodyHtml);
      final idx = drafts.indexWhere((d) => d.id == emailId);
      if (idx != -1) drafts[idx] = updated;
      successMessage.value = 'Draft updated.';
    } catch (e) {
      errorMessage.value = 'Failed to update draft: $e';
    }
  }

  Future<void> deleteDraft(String emailId) async {
    try {
      await _repo.deleteDraft(emailId);
      drafts.removeWhere((d) => d.id == emailId);
    } catch (e) {
      errorMessage.value = 'Failed to delete draft: $e';
    }
  }

  Future<void> reloadSent() async {
    try {
      final result = await _repo.listSent();
      sentEmails.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Failed to reload sent emails: $e';
    }
  }

  Future<void> sendEmail(String emailId) async {
    isSending.value = true;
    errorMessage.value = null;
    try {
      await _repo.sendEmail(emailId);
      drafts.removeWhere((d) => d.id == emailId);
      await Future.wait([reloadLeads(), reloadSent()]);
      successMessage.value = 'Email sent.';
    } catch (e) {
      errorMessage.value = 'Failed to send email: $e';
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendTestEmail(String emailId) async {
    try {
      await _repo.sendTestEmail(emailId);
      successMessage.value = 'Test email sent to ras3ucat@gmail.com';
    } catch (e) {
      errorMessage.value = 'Failed to send test email: $e';
    }
  }

  Future<String?> getEmailPreview(String emailId) async {
    try {
      return await _repo.getEmailPreview(emailId);
    } catch (e) {
      errorMessage.value = 'Failed to load preview: $e';
      return null;
    }
  }

  Future<void> sendBatch() async {
    isSending.value = true;
    errorMessage.value = null;
    try {
      final result = await _repo.sendBatch();
      final sent = result['sent'] ?? 0;
      final failed = result['failed'] ?? 0;
      drafts.clear();
      await Future.wait([reloadLeads(), reloadSent()]);
      successMessage.value =
          'Sent $sent email${sent == 1 ? '' : 's'}${failed > 0 ? ', $failed failed' : ''}.';
    } catch (e) {
      errorMessage.value = 'Failed to send batch: $e';
    } finally {
      isSending.value = false;
    }
  }

  Future<void> saveSettings(OutreachSettings updated) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final saved = await _repo.updateSettings(updated);
      settings.value = saved;
      successMessage.value = 'Settings saved.';
    } catch (e) {
      errorMessage.value = 'Failed to save settings: $e';
    } finally {
      isLoading.value = false;
    }
  }

  List<LeadModel> get leadsByStatus {
    final all = leads.toList()
      ..sort((a, b) {
        final statusOrder = [
          'prospect',
          'contacted',
          'replied',
          'call_booked',
          'proposal_sent',
          'closed_won',
          'closed_lost',
          'unsubscribed',
        ];
        final ai = statusOrder.indexOf(a.status);
        final bi = statusOrder.indexOf(b.status);
        if (ai != bi) return ai.compareTo(bi);
        return b.score.compareTo(a.score);
      });
    return all;
  }

  List<OutreachEmailModel> draftsForLead(String leadId) =>
      drafts.where((d) => d.leadId == leadId).toList();

  List<LeadModel> get filteredLeadsByStatus {
    final filter = selectedIndustryFilter.value;
    if (filter == null) return leadsByStatus;
    return leadsByStatus.where((l) => l.industry.toLowerCase() == filter.toLowerCase()).toList();
  }

  Future<void> runDiscovery() async {
    isDiscovering.value = true;
    errorMessage.value = null;
    try {
      final result = await _repo.runDiscovery().timeout(
        const Duration(seconds: 300),
        onTimeout: () =>
            throw Exception('Discovery timed out — try again or reduce target cities.'),
      );
      final inserted = result['inserted'] as int? ?? 0;
      final updated = result['updated'] as int? ?? 0;
      final audited = result['audited'] as int? ?? 0;
      await Future.wait([reloadLeads(), _refreshSettings()]);
      successMessage.value =
          'Found $inserted new leads, updated $updated, audited $audited websites.';

      // Audit remaining sites + enrich high-scorers in background passes
      _repo.runDiscoveryAction('audit-websites').ignore();
      _repo.runDiscoveryAction('enrich-apollo').ignore();
    } catch (e) {
      errorMessage.value = 'Discovery failed: $e';
    } finally {
      isDiscovering.value = false;
    }
  }

  Future<void> updateIndustryTemplate(String slug, String subject, String body) async {
    try {
      await _repo.updateIndustryTemplate(slug, subject, body);
      final idx = industryProfiles.indexWhere((p) => p.slug == slug);
      if (idx != -1) {
        industryProfiles[idx] = industryProfiles[idx].copyWith(
          emailSubjectTemplate: subject,
          emailBodyTemplate: body,
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to save template: $e';
    }
  }

  Future<void> loadIndustryProfiles() async {
    try {
      final profiles = await _repo.listIndustryProfiles();
      industryProfiles.assignAll(profiles);
    } catch (e) {
      errorMessage.value = 'Failed to load industry profiles: $e';
    }
  }

  Future<void> _refreshSettings() async {
    try {
      final s = await _repo.getSettings();
      if (s != null) settings.value = s;
    } catch (_) {}
  }

  bool hasProfileForIndustry(String industry) {
    final lower = industry.toLowerCase();
    return industryProfiles.any(
      (p) => lower.contains(p.slug.replaceAll('-', ' ')) || lower.contains(p.name.toLowerCase()),
    );
  }

  /// True when every configured industry has a synced profile.
  bool get canRunDiscovery {
    final industries = settings.value.targetIndustries;
    if (industries.isEmpty) return false;
    return industries.every(hasProfileForIndustry);
  }

  /// Industries missing a profile — shown in the disabled button tooltip.
  List<String> get missingProfiles =>
      settings.value.targetIndustries.where((i) => !hasProfileForIndustry(i)).toList();
}
