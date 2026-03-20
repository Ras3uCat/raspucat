import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/data/models/portal_message_model.dart';

class AdminMessagesController extends GetxController {
  final String quoteId;

  final messages = <PortalMessage>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;
  final scrollController = ScrollController();

  RealtimeChannel? _realtimeChannel;

  AdminMessagesController(this.quoteId);

  String get _token => AdminController.instance.adminToken;

  @override
  void onInit() {
    super.onInit();
    loadMessages();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    _realtimeChannel?.unsubscribe();
    scrollController.dispose();
    super.onClose();
  }

  void _subscribeRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('admin_messages_$quoteId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'portal_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quote_id',
            value: quoteId,
          ),
          callback: (_) => loadMessages(),
        )
        .subscribe();
  }

  Future<void> loadMessages() async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-get-messages',
        body: {'adminToken': _token, 'quoteId': quoteId},
      );
      final data = response.data as Map<String, dynamic>?;
      final list = (data?['messages'] as List<dynamic>? ?? [])
          .map((e) => PortalMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      messages.assignAll(list);
      _scrollToBottom();
      // Refresh badge counts now that messages are marked read server-side
      AdminController.instance.fetchPendingModuleCounts();
    } catch (_) {
      // Leave messages unchanged on error
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || isSending.value) return;

    isSending.value = true;
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-send-message',
        body: {'adminToken': _token, 'quoteId': quoteId, 'messageBody': trimmed},
      );
      await loadMessages();
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
