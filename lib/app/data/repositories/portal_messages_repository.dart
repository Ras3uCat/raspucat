import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/data/models/portal_message_model.dart';

class PortalMessagesRepository {
  final _client = Supabase.instance.client;

  Future<List<PortalMessage>> fetchMessages(String quoteId) async {
    final data = await _client
        .from('portal_messages')
        .select()
        .eq('quote_id', quoteId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => PortalMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage(String quoteId, String body) async {
    await _client.from('portal_messages').insert({
      'quote_id': quoteId,
      'sender': 'client',
      'body': body.trim(),
    });
  }

  Future<void> markAdminMessagesRead(String quoteId) async {
    await _client
        .from('portal_messages')
        .update({'client_read_at': DateTime.now().toIso8601String()})
        .eq('quote_id', quoteId)
        .eq('sender', 'admin')
        .isFilter('client_read_at', null);
  }

  Future<int> fetchUnreadCount(String quoteId) async {
    final data = await _client
        .from('portal_messages')
        .select('id')
        .eq('quote_id', quoteId)
        .eq('sender', 'admin')
        .isFilter('client_read_at', null);
    return (data as List).length;
  }
}
