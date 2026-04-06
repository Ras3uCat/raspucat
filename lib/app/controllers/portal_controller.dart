import 'dart:convert';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/app/data/repositories/portal_files_repository.dart';
import 'package:raspucat/app/data/repositories/portal_messages_repository.dart';
import 'package:raspucat/app/data/repositories/portal_repository.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PortalController extends GetxController {
  final _repo = PortalRepository();
  final _msgRepo = PortalMessagesRepository();
  final _filesRepo = PortalFilesRepository();

  final quotes = <PortalQuote>[].obs;
  final activeQuoteIndex = 0.obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final selectedTab = 0.obs;
  final unreadMessageCount = 0.obs;
  final unreadFileCount = 0.obs;

  // Login state
  final loginEmail = ''.obs;
  final loginSent = false.obs;
  final loginLoading = false.obs;
  final loginError = RxnString();

  // Billing portal state
  final isBillingPortalLoading = false.obs;
  final billingPortalError = RxnString();

  // Cancellation state
  final isCancelLoading = false.obs;
  final cancelError = RxnString();

  PortalQuote? get activeQuote => quotes.isEmpty ? null : quotes[activeQuoteIndex.value];

  @override
  void onInit() {
    super.onInit();
    _loadQuotes();
    ever(selectedTab, (int tab) {
      final qid = activeQuote?.id;
      if (tab == 1 && qid != null) {
        unreadMessageCount.value = 0;
        _msgRepo.markAdminMessagesRead(qid).catchError((_) {});
      }
      if (tab == 2) {
        unreadFileCount.value = 0;
        final qid = activeQuote?.id;
        if (qid != null) {
          _filesRepo.markAdminFilesSeenByClient(qid).catchError((_) {});
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> _loadQuotes() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      quotes.value = await _repo.fetchMyQuotes();
      if (activeQuote != null) {
        unreadMessageCount.value = await _msgRepo.fetchUnreadCount(activeQuote!.id);
      }
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
    // File count fetch is non-fatal — run separately so it can't break portal load
    if (activeQuote != null) {
      _filesRepo
          .fetchAdminFileCount(activeQuote!.id)
          .then((c) => unreadFileCount.value = c)
          .catchError((_) {});
    }
  }

  void selectQuote(int index) {
    activeQuoteIndex.value = index;
    selectedTab.value = 0;
    final qid = activeQuote!.id;
    _msgRepo.fetchUnreadCount(qid).then((c) => unreadMessageCount.value = c).catchError((_) {});
    _filesRepo.fetchAdminFileCount(qid).then((c) => unreadFileCount.value = c).catchError((_) {});
  }

  @override
  Future<void> refresh() => _loadQuotes();

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<void> sendMagicLink(String email) async {
    if (loginLoading.value) return;
    loginError.value = null;
    loginLoading.value = true;
    try {
      // Clear any existing session so the PKCE verifier is written cleanly.
      // Ignore errors — signOut on an already-signed-out session may throw.
      await _repo.signOut().catchError((_) {});
      await _repo.sendMagicLink(email);
      loginSent.value = true;
    } catch (e) {
      loginError.value = 'Could not send link. Please try again.';
    } finally {
      loginLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    Get.offAllNamed(ERoutes.portalLogin);
  }

  // ---------------------------------------------------------------------------
  // Billing portal
  // ---------------------------------------------------------------------------

  Future<void> openBillingPortal() async {
    if (isBillingPortalLoading.value) return;
    billingPortalError.value = null;
    isBillingPortalLoading.value = true;
    try {
      final url = await _repo.fetchBillingPortalUrl(activeQuote!.id);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      billingPortalError.value = 'Could not open billing portal. Please try again.';
    } finally {
      isBillingPortalLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Discovery form
  // ---------------------------------------------------------------------------

  Future<void> saveDiscoveryDraft(Map<String, dynamic> data) async {
    final quote = activeQuote;
    if (quote == null) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'portal-save-discovery',
        body: {'quote_id': quote.id, 'discovery_data': data},
      );
    } catch (_) {
      // Silent — draft saves are best-effort
    }
  }

  Future<bool> submitDiscovery(Map<String, dynamic> data) async {
    final quote = activeQuote;
    if (quote == null) return false;
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'portal-save-discovery',
        body: {'quote_id': quote.id, 'discovery_data': data, 'submit': true},
      );
      final result = resp.data as Map<String, dynamic>?;
      if (result?['ok'] == true) {
        await _loadQuotes(); // Refresh so portal_stage and discoverySubmittedAt update
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> uploadDiscoveryAsset(
    String quoteId,
    String field,
    List<int> bytes,
    String mimeType,
    String fileName,
  ) async {
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'portal-upload-asset',
        body: {
          'quoteId': quoteId,
          'field': field,
          'fileBase64': base64Encode(bytes),
          'mimeType': mimeType,
          'fileName': fileName,
        },
      );
      return (resp.data as Map<String, dynamic>?)?['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Cancellation
  // ---------------------------------------------------------------------------

  Future<bool> cancelSubscription(String deliveryEmail) async {
    if (isCancelLoading.value) return false;
    cancelError.value = null;
    isCancelLoading.value = true;
    try {
      final quote = activeQuote;
      if (quote == null) return false;
      await _repo.cancelSubscription(quote.id, deliveryEmail);
      // Reload quotes so the UI reflects the new subscription_cancel_at
      await _loadQuotes();
      return true;
    } catch (e) {
      cancelError.value = 'Could not cancel subscription. Please try again.';
      return false;
    } finally {
      isCancelLoading.value = false;
    }
  }
}
