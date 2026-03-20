import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/portal_message_model.dart';
import 'package:raspucat/app/data/repositories/portal_messages_repository.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalMessagesController extends GetxController {
  final _repo = PortalMessagesRepository();
  final String quoteId;

  final messages = <PortalMessage>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;
  final scrollController = ScrollController();

  RealtimeChannel? _realtimeChannel;

  PortalMessagesController(this.quoteId);

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
        .channel('portal_messages_$quoteId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'portal_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quote_id',
            value: quoteId,
          ),
          callback: (payload) {
            loadMessages();
            // Increment nav badge when a new admin message arrives
            try {
              Get.find<PortalController>().unreadMessageCount.value++;
            } catch (_) {}
          },
        )
        .subscribe();
  }

  Future<void> loadMessages() async {
    isLoading.value = true;
    try {
      final result = await _repo.fetchMessages(quoteId);
      messages.assignAll(result);
      _scrollToBottom();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || isSending.value) return;

    isSending.value = true;
    try {
      await _repo.sendMessage(quoteId, trimmed);
      await loadMessages();
    } finally {
      isSending.value = false;
    }
  }

  int get unreadCount =>
      messages.where((m) => m.isUnreadByClient).length;

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
