import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:raspucat/utils/constants/brand.dart';
import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/module_model.dart';
import 'package:raspucat/app/data/models/pending_module_model.dart';
import 'package:raspucat/app/data/repositories/portal_modules_repository.dart';
import 'package:raspucat/app/data/services/stripe_payment_service.dart';

class PortalModulesController extends GetxController {
  final _repo = PortalModulesRepository();

  final RxList<ModuleModel> availableModules = <ModuleModel>[].obs;
  final RxList<PendingModuleModel> pendingModules = <PendingModuleModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Per-module checkout loading: moduleId → true/false
  final RxMap<String, bool> checkingOut = <String, bool>{}.obs;

  // Inline payment state (shown when no saved card or user picks new card)
  final Rxn<ModuleCheckoutPrep> checkoutPrep = Rxn();
  final RxBool showPaymentElement = false.obs;
  final RxnString activeModuleName = RxnString();
  final RxnString activeModuleId = RxnString();
  final RxBool isPaying = false.obs;
  final RxnString paymentError = RxnString();

  // Show success banner after payment
  final RxBool showSuccessBanner = false.obs;

  PortalController get _portalCtrl => Get.find<PortalController>();

  @override
  void onInit() {
    super.onInit();
    loadModules();
    ever(_portalCtrl.activeQuoteIndex, (_) => loadModules());
  }

  Future<void> loadModules() async {
    final quote = _portalCtrl.activeQuote;
    if (quote == null) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final ownedIds = quote.moduleIds;
      final results = await (
        _repo.fetchAvailableModules(ownedModuleIds: ownedIds, quoteId: quote.id),
        _repo.fetchPendingModules(quote.id),
      ).wait;
      availableModules.assignAll(results.$1);
      pendingModules.assignAll(results.$2);
    } catch (e) {
      errorMessage.value = 'Failed to load modules. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Step 1: prepare checkout — shows dialog with card choice ─────────────────

  Future<void> checkout(String moduleId, String moduleName) async {
    final quote = _portalCtrl.activeQuote;
    if (quote == null) return;

    checkingOut[moduleId] = true;
    checkingOut.refresh();
    try {
      final prep = await _repo.createModuleCheckout(quote.id, moduleId);
      checkoutPrep.value = prep;
      activeModuleName.value = moduleName;
      activeModuleId.value = moduleId;
      paymentError.value = null;
    } catch (e) {
      errorMessage.value = 'Checkout failed. Please try again.';
    } finally {
      checkingOut[moduleId] = false;
      checkingOut.refresh();
    }
  }

  // ── Step 2a: user picks saved card ───────────────────────────────────────────

  Future<void> payWithSavedCard() async {
    final quote = _portalCtrl.activeQuote;
    final prep = checkoutPrep.value;
    if (quote == null || prep == null) return;

    final paymentMethodId = prep.paymentMethodId;
    if (paymentMethodId == null) {
      paymentError.value = 'No saved card on file.';
      return;
    }

    isPaying.value = true;
    paymentError.value = null;
    try {
      const publishableKey = EEnv.stripePublishableKey;
      final error = await StripePaymentService.confirmCardPayment(
        publishableKey,
        prep.clientSecret,
        paymentMethodId,
      );
      if (error != null) {
        paymentError.value = error;
      } else {
        _onPaymentSuccess();
      }
    } catch (e) {
      paymentError.value = 'Payment failed. Please try again.';
    } finally {
      isPaying.value = false;
    }
  }

  // ── Step 2b: user picks new card ─────────────────────────────────────────────

  Future<void> payWithNewCard() async {
    final prep = checkoutPrep.value;
    if (prep == null) return;
    _mountEmbeddedElement(prep);
  }

  // ── Step 3: confirm embedded payment element ─────────────────────────────────

  Future<void> confirmPayment() async {
    isPaying.value = true;
    paymentError.value = null;
    final error = await StripePaymentService.confirmPayment();
    isPaying.value = false;
    if (error != null) {
      paymentError.value = error;
      return;
    }
    _onPaymentSuccess();
  }

  void cancelPayment() {
    checkoutPrep.value = null;
    showPaymentElement.value = false;
    activeModuleName.value = null;
    activeModuleId.value = null;
    paymentError.value = null;
  }

  void dismissSuccessBanner() => showSuccessBanner.value = false;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _onPaymentSuccess() {
    checkoutPrep.value = null;
    showPaymentElement.value = false;
    activeModuleName.value = null;
    activeModuleId.value = null;
    showSuccessBanner.value = true;
    loadModules();
  }

  Future<void> _mountEmbeddedElement(ModuleCheckoutPrep prep) async {
    StripePaymentService.registerViewFactory();
    showPaymentElement.value = true;
    const publishableKey = EEnv.stripePublishableKey;
    // Wait for the HtmlElementView to be rendered before mounting.
    // addPostFrameCallback fires only after the frame is committed to the screen,
    // making this reliable on slow connections unlike a hardcoded delay.
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    await completer.future;
    try {
      StripePaymentService.mountPaymentElement(publishableKey, prep.clientSecret);
    } catch (_) {
      showPaymentElement.value = false;
      paymentError.value = 'Could not load payment form. Please refresh and try again.';
    }
  }
}
