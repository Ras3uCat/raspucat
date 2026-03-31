import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';

class AdminController extends GetxController {
  static AdminController get instance => Get.find();

  final RxBool isAuthenticated = false.obs;
  final RxBool isLoadingQuotes = false.obs;
  final RxList<Map<String, dynamic>> quotes = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> adminStats = <String, dynamic>{}.obs;

  // Per-quote action state: quoteId → { chargingBalance, startingSub, chargeMsg, subMsg }
  final RxMap<String, Map<String, dynamic>> quoteState = <String, Map<String, dynamic>>{}.obs;

  // Quote detail cache: quoteId → full detail map
  final RxMap<String, Map<String, dynamic>> quoteDetail = <String, Map<String, dynamic>>{}.obs;
  final RxSet<String> loadingDetail = <String>{}.obs;

  // Search & filter state
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'all'.obs;
  final RxString billingFilter = 'all'.obs;

  // Pipeline view toggle
  final RxBool showPipeline = false.obs;

  // Current template version (from app_settings)
  final RxString currentTemplateVersion = ''.obs;

  // Delivery progress: quoteId → list of step rows
  final RxMap<String, List<Map<String, dynamic>>> deliveryProgress =
      <String, List<Map<String, dynamic>>>{}.obs;
  final RxSet<String> loadingDelivery = <String>{}.obs;

  // Site events: quoteId → last 5 site_events rows
  final RxMap<String, List<Map<String, dynamic>>> siteEvents =
      <String, List<Map<String, dynamic>>>{}.obs;
  final RxSet<String> loadingSiteEvents = <String>{}.obs;

  // Pending module counts: quoteId → unacknowledged count
  final RxMap<String, int> pendingModuleCounts = <String, int>{}.obs;
  // In-progress counts: quoteId → acknowledged-but-not-live count
  final RxMap<String, int> inProgressModuleCounts = <String, int>{}.obs;
  // Unread client message counts: quoteId → unread count
  final RxMap<String, int> unreadMessageCounts = <String, int>{}.obs;
  // New client file counts: quoteId → file count
  final RxMap<String, int> newFileCounts = <String, int>{}.obs;

  String _adminToken = '';
  String get adminToken => _adminToken;

  Timer? _pollTimer;

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  int get staleCount => quoteState.values.where((s) => s['isStale'] == true).length;

  List<Map<String, dynamic>> get filteredQuotes {
    final query = searchQuery.value.toLowerCase().trim();
    final status = statusFilter.value;
    final billing = billingFilter.value;

    return quotes.where((q) {
      if (query.isNotEmpty) {
        final name = (q['client_name'] as String? ?? '').toLowerCase();
        final email = (q['client_email'] as String? ?? '').toLowerCase();
        if (!name.contains(query) && !email.contains(query)) return false;
      }
      if (status != 'all' && (q['status'] as String? ?? '') != status) {
        return false;
      }
      if (billing != 'all' && (q['billing_cycle'] as String? ?? '') != billing) {
        return false;
      }
      return true;
    }).toList();
  }

  AdminCatalogController get _catalog => Get.find<AdminCatalogController>();

  Future<bool> login(String password) async {
    if (password.trim().isEmpty) return false;
    _adminToken = password.trim();
    isLoadingQuotes.value = true;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-list-quotes',
        body: {'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] == 'Unauthorized.') {
        _adminToken = '';
        return false;
      }
      final list = data?['quotes'] as List<dynamic>? ?? [];
      quotes.assignAll(list.cast<Map<String, dynamic>>());
      _initQuoteState();
      isAuthenticated.value = true;
      _catalog.setToken(_adminToken);
      await Future.wait([
        fetchQuotes(),
        fetchStats(),
        _catalog.fetchCatalog(),
        fetchPendingModuleCounts(),
        fetchCurrentTemplateVersion(),
      ]);
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => fetchPendingModuleCounts());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[AdminController.login] error: $e');
      _adminToken = '';
      return false;
    } finally {
      isLoadingQuotes.value = false;
    }
  }

  void logout() {
    _pollTimer?.cancel();
    _pollTimer = null;
    isAuthenticated.value = false;
    _adminToken = '';
    quotes.clear();
    quoteState.clear();
    quoteDetail.clear();
    loadingDetail.clear();
    adminStats.clear();
    pendingModuleCounts.clear();
    inProgressModuleCounts.clear();
    unreadMessageCounts.clear();
    newFileCounts.clear();
    currentTemplateVersion.value = '';
    deliveryProgress.clear();
    loadingDelivery.clear();
    siteEvents.clear();
    loadingSiteEvents.clear();
    searchQuery.value = '';
    statusFilter.value = 'all';
    billingFilter.value = 'all';
    showPipeline.value = false;
    _catalog.clearCatalog();
  }

  Future<void> fetchQuotes() async {
    if (_adminToken.isEmpty) return;
    isLoadingQuotes.value = true;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-list-quotes',
        body: {'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      final list = data?['quotes'] as List<dynamic>? ?? [];
      quotes.assignAll(list.cast<Map<String, dynamic>>());
      _initQuoteState();
      fetchStats();
      fetchPendingModuleCounts();
    } catch (_) {
      // Leave quotes unchanged on error
    } finally {
      isLoadingQuotes.value = false;
    }
  }

  Future<void> fetchPendingModuleCounts() async {
    if (_adminToken.isEmpty) return;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-get-pending-modules',
        body: {'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      // Support updated format { unacknowledged_counts, in_progress_counts }
      // with fallback to old { counts } for backward compat
      final unacknowledged =
          data?['unacknowledged_counts'] as Map<String, dynamic>? ??
          data?['counts'] as Map<String, dynamic>? ??
          {};
      final inProgress = data?['in_progress_counts'] as Map<String, dynamic>? ?? {};
      final unreadMsgs = data?['unread_message_counts'] as Map<String, dynamic>? ?? {};
      pendingModuleCounts.assignAll(unacknowledged.map((k, v) => MapEntry(k, (v as num).toInt())));
      inProgressModuleCounts.assignAll(inProgress.map((k, v) => MapEntry(k, (v as num).toInt())));
      unreadMessageCounts.assignAll(unreadMsgs.map((k, v) => MapEntry(k, (v as num).toInt())));
      final newFiles = data?['new_file_counts'] as Map<String, dynamic>? ?? {};
      newFileCounts.assignAll(newFiles.map((k, v) => MapEntry(k, (v as num).toInt())));
    } catch (_) {
      // Non-critical — leave counts unchanged
    }
  }

  Future<void> markModuleLive(String pendingModuleId, String quoteId, String moduleId) async {
    if (_adminToken.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-mark-module-deployed',
        body: {
          'adminToken': _adminToken,
          'quoteId': quoteId,
          'moduleId': moduleId,
          'action': 'deployed',
        },
      );
      await Future.wait([fetchPendingModuleCounts(), fetchQuoteDetail(quoteId)]);
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> updatePortalStage(String quoteId, String stage) async {
    if (_adminToken.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-update-portal-stage',
        body: {'adminToken': _adminToken, 'quoteId': quoteId, 'stage': stage},
      );
      // Refresh detail to reflect new stage
      await fetchQuoteDetail(quoteId);
    } catch (_) {
      // Silently fail — UI will not update
    }
  }

  Future<void> acknowledgeModule(String pendingModuleId, String quoteId) async {
    if (_adminToken.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-acknowledge-module',
        body: {'adminToken': _adminToken, 'pendingModuleId': pendingModuleId},
      );
      await Future.wait([fetchPendingModuleCounts(), fetchQuoteDetail(quoteId)]);
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> fetchStats() async {
    if (_adminToken.isEmpty) return;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-get-stats',
        body: {'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['error'] == null) {
        adminStats.assignAll(data);
      }
    } catch (_) {
      // Leave stats unchanged on error
    }
  }

  void _initQuoteState() {
    for (final q in quotes) {
      final id = q['id'] as String;
      quoteState.putIfAbsent(
        id,
        () => {'chargingBalance': false, 'startingSub': false, 'chargeMsg': null, 'subMsg': null},
      );
      final depositPaidAt = q['deposit_paid_at'] as String?;
      if (q['status'] == 'deposit_paid' && depositPaidAt != null) {
        final paidAt = DateTime.tryParse(depositPaidAt);
        final isStale = paidAt != null && DateTime.now().difference(paidAt).inDays > 7;
        if (isStale) _setQuoteState(id, 'isStale', true);
      }
    }
  }

  Future<void> chargeBalance(String quoteId) async {
    _setQuoteState(quoteId, 'chargingBalance', true);
    _setQuoteState(quoteId, 'chargeMsg', null);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'charge-balance',
        body: {'quoteId': quoteId, 'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'chargeMsg', '❌ ${data!['error']}');
      } else {
        _setQuoteState(quoteId, 'chargeMsg', '✅ Balance charged');
        await Future.wait([fetchQuotes(), fetchStats()]);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'chargeMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'chargingBalance', false);
    }
  }

  Future<void> startSubscription(String quoteId) async {
    _setQuoteState(quoteId, 'startingSub', true);
    _setQuoteState(quoteId, 'subMsg', null);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'start-subscription',
        body: {'quoteId': quoteId, 'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'subMsg', '❌ ${data!['error']}');
      } else {
        _setQuoteState(quoteId, 'subMsg', '✅ Subscription started');
        await Future.wait([fetchQuotes(), fetchStats()]);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'subMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'startingSub', false);
    }
  }

  Future<void> fetchQuoteDetail(String quoteId) async {
    if (_adminToken.isEmpty) return;
    loadingDetail.add(quoteId);
    try {
      final quoteResp = await Supabase.instance.client.functions.invoke(
        'admin-get-quote-detail',
        body: {'quoteId': quoteId, 'adminToken': _adminToken},
      );

      final quoteData = quoteResp.data as Map<String, dynamic>?;
      final detail = quoteData?['quote'] as Map<String, dynamic>?;
      if (detail == null) return;

      // Fetch pending modules separately — non-fatal if it fails
      try {
        final pendingResp = await Supabase.instance.client.functions.invoke(
          'admin-get-pending-modules',
          body: {'adminToken': _adminToken, 'quoteId': quoteId},
        );
        final pendingData = pendingResp.data as Map<String, dynamic>?;
        detail['portal_stage'] = pendingData?['portal_stage'] ?? 'transmitting';
        detail['pending_modules'] = pendingData?['pending_modules'] as List<dynamic>? ?? [];
      } catch (_) {
        detail['portal_stage'] = 'transmitting';
        detail['pending_modules'] = <dynamic>[];
      }

      quoteDetail[quoteId] = detail;
      quoteDetail.refresh();
    } catch (e) {
      // ignore: avoid_print
      print('[fetchQuoteDetail] error: $e');
    } finally {
      loadingDetail.remove(quoteId);
    }
  }

  Future<void> cancelSubscription(String quoteId) async {
    _setQuoteState(quoteId, 'cancellingSubscription', true);
    _setQuoteState(quoteId, 'cancelMsg', null);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-cancel-subscription',
        body: {'quoteId': quoteId, 'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'cancelMsg', '❌ ${data!['error']}');
      } else {
        _setQuoteState(quoteId, 'cancelMsg', '✅ Subscription cancelled');
        quoteDetail.remove(quoteId);
        quoteDetail.refresh();
        await Future.wait([fetchQuotes(), fetchStats()]);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'cancelMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'cancellingSubscription', false);
    }
  }

  Future<void> addModule(String quoteId, String moduleId) async {
    _setQuoteState(quoteId, 'addingModule', true);
    _setQuoteState(quoteId, 'addModuleMsg', null);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-add-module',
        body: {'quoteId': quoteId, 'moduleId': moduleId, 'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'addModuleMsg', '❌ ${data!['error']}');
      } else {
        _setQuoteState(quoteId, 'addModuleMsg', '✅ Module added');
        await Future.wait([fetchQuotes(), fetchQuoteDetail(quoteId)]);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'addModuleMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'addingModule', false);
    }
  }

  Future<void> rejectModule(String pendingModuleId, String quoteId) async {
    if (_adminToken.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-reject-module',
        body: {'adminToken': _adminToken, 'pendingModuleId': pendingModuleId},
      );
      await Future.wait([fetchPendingModuleCounts(), fetchQuoteDetail(quoteId)]);
    } catch (_) {
      // Silently fail
    }
  }

  void clearFileCount(String quoteId) {
    newFileCounts[quoteId] = 0;
    newFileCounts.refresh();
    if (_adminToken.isEmpty) return;
    Supabase.instance.client.functions
        .invoke('admin-mark-files-seen', body: {'adminToken': _adminToken, 'quoteId': quoteId})
        .catchError((_) {});
  }

  Future<void> fetchCurrentTemplateVersion() async {
    if (_adminToken.isEmpty) return;
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'admin-settings',
        body: {'adminToken': _adminToken, 'action': 'get', 'key': 'current_template_version'},
      );
      final data = resp.data as Map<String, dynamic>?;
      currentTemplateVersion.value = data?['value'] as String? ?? '';
    } catch (_) {}
  }

  Future<void> markTemplateUpdated(String quoteId) async {
    if (_adminToken.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-delivery-progress',
        body: {'adminToken': _adminToken, 'quoteId': quoteId, 'action': 'mark_updated'},
      );
      await Future.wait([fetchQuoteDetail(quoteId), fetchQuotes(), fetchCurrentTemplateVersion()]);
    } catch (_) {}
  }

  Future<void> fetchDeliveryProgress(String quoteId) async {
    if (_adminToken.isEmpty) return;
    loadingDelivery.add(quoteId);
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'admin-delivery-progress',
        body: {'adminToken': _adminToken, 'quoteId': quoteId, 'action': 'list'},
      );
      final data = resp.data as Map<String, dynamic>?;
      deliveryProgress[quoteId] = (data?['steps'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      deliveryProgress.refresh();
    } catch (_) {
    } finally {
      loadingDelivery.remove(quoteId);
    }
  }

  Future<void> initDeliveryProgress(String quoteId, List<String> moduleIds) async {
    if (_adminToken.isEmpty) return;
    loadingDelivery.add(quoteId);
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'admin-delivery-progress',
        body: {
          'adminToken': _adminToken,
          'quoteId': quoteId,
          'action': 'init',
          'moduleIds': moduleIds,
        },
      );
      final data = resp.data as Map<String, dynamic>?;
      deliveryProgress[quoteId] = (data?['steps'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      deliveryProgress.refresh();
    } catch (_) {
    } finally {
      loadingDelivery.remove(quoteId);
    }
  }

  Future<void> toggleDeliveryStep(String quoteId, String step, bool checked) async {
    if (_adminToken.isEmpty) return;
    // Optimistic update
    final current = List<Map<String, dynamic>>.from(deliveryProgress[quoteId] ?? []);
    final idx = current.indexWhere((s) => s['step'] == step);
    if (idx >= 0) {
      current[idx] = Map.from(current[idx])
        ..['checked'] = checked
        ..['checked_at'] = checked ? DateTime.now().toIso8601String() : null
        ..['checked_by'] = 'admin';
      deliveryProgress[quoteId] = current;
      deliveryProgress.refresh();
    }
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-delivery-progress',
        body: {
          'adminToken': _adminToken,
          'quoteId': quoteId,
          'action': 'upsert',
          'step': step,
          'checked': checked,
        },
      );
    } catch (_) {
      // Revert on failure
      await fetchDeliveryProgress(quoteId);
    }
  }

  Future<void> saveSiteUrl(String quoteId, String siteUrl) async {
    if (_adminToken.isEmpty) return;
    _setQuoteState(quoteId, 'savingSiteUrl', true);
    _setQuoteState(quoteId, 'siteUrlMsg', null);
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'admin-register-site',
        body: {'adminToken': _adminToken, 'quoteId': quoteId, 'siteUrl': siteUrl},
      );
      final data = resp.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'siteUrlMsg', '❌ ${data!['error']}');
      } else {
        _setQuoteState(quoteId, 'siteUrlMsg', '✅ Site registered');
        await Future.wait([fetchQuotes(), fetchQuoteDetail(quoteId)]);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'siteUrlMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'savingSiteUrl', false);
    }
  }

  Future<void> sendHandoff(String quoteId) async {
    _setQuoteState(quoteId, 'sendingHandoff', true);
    _setQuoteState(quoteId, 'handoffMsg', null);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-send-handoff',
        body: {'quoteId': quoteId, 'action': 'client_package', 'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'handoffMsg', '❌ ${data!['error']}');
      } else if (data?['skipped'] == true) {
        _setQuoteState(quoteId, 'handoffMsg', '✅ Already sent (idempotency)');
      } else {
        _setQuoteState(quoteId, 'handoffMsg', '✅ Handoff sent');
        await fetchQuoteDetail(quoteId);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'handoffMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'sendingHandoff', false);
    }
  }

  Future<void> provisionEmail(String quoteId, String clientName, {String? slugOverride}) async {
    _setQuoteState(quoteId, 'provisioningEmail', true);
    _setQuoteState(quoteId, 'provisionEmailMsg', null);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-provision-client-email',
        body: {
          'quoteId': quoteId,
          'clientName': clientName,
          if (slugOverride != null) 'slugOverride': slugOverride,
          'adminToken': _adminToken,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'provisionEmailMsg', '❌ ${data!['error']}');
      } else {
        _setQuoteState(
          quoteId,
          'provisionEmailMsg',
          '✅ Provisioned: ${data!['provisioned_email']}',
        );
        await fetchQuoteDetail(quoteId);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'provisionEmailMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'provisioningEmail', false);
    }
  }

  Future<void> deprovisionEmail(String quoteId) async {
    _setQuoteState(quoteId, 'deprovisioningEmail', true);
    _setQuoteState(quoteId, 'provisionEmailMsg', null);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-deprovision-client-email',
        body: {'quoteId': quoteId, 'adminToken': _adminToken},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        _setQuoteState(quoteId, 'provisionEmailMsg', '❌ ${data!['error']}');
      } else {
        _setQuoteState(quoteId, 'provisionEmailMsg', '✅ Deprovisioned');
        await fetchQuoteDetail(quoteId);
      }
    } catch (_) {
      _setQuoteState(quoteId, 'provisionEmailMsg', '❌ Something went wrong');
    } finally {
      _setQuoteState(quoteId, 'deprovisioningEmail', false);
    }
  }

  Future<void> fetchSiteEvents(String quoteId) async {
    if (_adminToken.isEmpty) return;
    loadingSiteEvents.add(quoteId);
    try {
      final resp = await Supabase.instance.client
          .from('site_events')
          .select('id, event_type, payload, created_at')
          .eq('quote_id', quoteId)
          .order('created_at', ascending: false)
          .limit(5);
      siteEvents[quoteId] = (resp as List<dynamic>).cast<Map<String, dynamic>>();
      siteEvents.refresh();
    } catch (_) {
    } finally {
      loadingSiteEvents.remove(quoteId);
    }
  }

  Future<String> generateClientJson(String quoteId) async {
    final response = await Supabase.instance.client.functions.invoke(
      'admin-generate-client-json',
      body: {'adminToken': _adminToken, 'quoteId': quoteId},
    );
    final data = response.data as Map<String, dynamic>?;
    if (data?['error'] != null) throw Exception(data!['error'] as String);
    return data?['clientJson'] as String? ?? '{}';
  }

  Future<void> saveDiscoveryData(String quoteId, Map<String, dynamic> data) async {
    await Supabase.instance.client.functions.invoke(
      'admin-save-discovery',
      body: {'adminToken': _adminToken, 'quoteId': quoteId, 'discovery_data': data},
    );
  }

  void _setQuoteState(String quoteId, String key, dynamic value) {
    final current = Map<String, dynamic>.from(quoteState[quoteId] ?? {});
    current[key] = value;
    quoteState[quoteId] = current;
    quoteState.refresh();
  }
}
