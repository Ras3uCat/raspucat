import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';

class PortalRepository {
  final _client = Supabase.instance.client;

  String get _portalRedirectUrl {
    final base = dotenv.env['APP_URL'] ?? 'https://raspucat.com';
    return '$base/portal';
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<void> sendMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim().toLowerCase(),
      emailRedirectTo: _portalRedirectUrl,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Quotes
  // ---------------------------------------------------------------------------

  Future<String> fetchBillingPortalUrl(String quoteId) async {
    final session = await _client.functions
        .invoke('portal-billing-session', method: HttpMethod.post, body: {'quoteId': quoteId})
        .timeout(const Duration(seconds: 10));

    final data = session.data as Map<String, dynamic>?;
    if (data == null || data['url'] == null) {
      throw Exception(data?['error'] ?? 'No billing account found.');
    }
    return data['url'] as String;
  }

  Future<List<PortalQuote>> fetchMyQuotes() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Auto-link any unlinked quotes matching this email on first login.
    try {
      await _client
          .from('quotes')
          .update({'user_id': user.id})
          .eq('client_email', user.email ?? '')
          .isFilter('user_id', null);
    } catch (e) {
      // ignore: avoid_print
      print('[PortalRepository.fetchMyQuotes] auto-link error: $e');
    }

    final rows = await _client
        .from('quotes')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => PortalQuote.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
