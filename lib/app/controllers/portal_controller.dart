import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/app/data/repositories/portal_files_repository.dart';
import 'package:raspucat/app/data/repositories/portal_messages_repository.dart';
import 'package:raspucat/app/data/repositories/portal_repository.dart';
import 'package:raspucat/utils/constants/exports.dart';
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

  PortalQuote? get activeQuote =>
      quotes.isEmpty ? null : quotes[activeQuoteIndex.value];

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
        unreadMessageCount.value =
            await _msgRepo.fetchUnreadCount(activeQuote!.id);
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
      billingPortalError.value =
          'Could not open billing portal. Please try again.';
    } finally {
      isBillingPortalLoading.value = false;
    }
  }
}
