import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/module_model.dart';
import 'package:raspucat/app/data/models/pending_module_model.dart';

class PortalModulesRepository {
  final _client = Supabase.instance.client;

  Future<List<ModuleModel>> fetchAvailableModules({
    required List<String> ownedModuleIds,
    required String quoteId,
  }) async {
    final [allData, pendingData] = await Future.wait([
      _client.from('modules').select().order('sort_order'),
      _client
          .from('client_modules_pending')
          .select('module_id')
          .eq('quote_id', quoteId)
          .isFilter('live_at', null),
    ]);

    final pendingIds = (pendingData as List)
        .map((p) => (p as Map<String, dynamic>)['module_id'] as String)
        .toSet();
    final ownedSet = ownedModuleIds.toSet();

    return (allData as List)
        .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
        .where((m) => !ownedSet.contains(m.id) && !pendingIds.contains(m.id))
        .toList();
  }

  Future<List<PendingModuleModel>> fetchPendingModules(String quoteId) async {
    final data = await _client
        .from('client_modules_pending')
        .select('id, acknowledged_at, modules(id, name, description, price, price_note)')
        .eq('quote_id', quoteId)
        .isFilter('live_at', null)
        .order('purchased_at');

    return (data as List)
        .map((e) => PendingModuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ModuleCheckoutPrep> createModuleCheckout(String quoteId, String moduleId) async {
    final response = await _client.functions.invoke(
      'create-module-checkout',
      body: {'quote_id': quoteId, 'module_id': moduleId},
    );

    if (response.status != 200) {
      final error = (response.data as Map<String, dynamic>?)?['error'] ?? 'Checkout failed';
      throw Exception(error);
    }

    final data = response.data as Map<String, dynamic>;
    return ModuleCheckoutPrep(
      clientSecret: data['clientSecret'] as String,
      hasSavedCard: data['hasSavedCard'] as bool? ?? false,
      last4: data['last4'] as String?,
      brand: data['brand'] as String?,
      paymentMethodId: data['paymentMethodId'] as String?,
    );
  }

  Future<bool> confirmSavedCard(String quoteId, String moduleId, String paymentIntentId) async {
    final response = await _client.functions.invoke(
      'create-module-checkout',
      body: {
        'quote_id': quoteId,
        'module_id': moduleId,
        'payment_intent_id': paymentIntentId,
      },
    );

    // ignore: avoid_print
    print('[confirmSavedCard] status: ${response.status}, data: ${response.data}');

    if (response.status != 200) {
      final error = (response.data as Map<String, dynamic>?)?['error'] ?? 'Payment failed';
      throw Exception(error);
    }

    final data = response.data as Map<String, dynamic>;
    return data['success'] == true;
  }
}

class ModuleCheckoutPrep {
  final String clientSecret;
  final bool hasSavedCard;
  final String? last4;
  final String? brand;
  final String? paymentMethodId;

  const ModuleCheckoutPrep({
    required this.clientSecret,
    required this.hasSavedCard,
    this.last4,
    this.brand,
    this.paymentMethodId,
  });

  String get paymentIntentId => clientSecret.split('_secret_').first;
}
