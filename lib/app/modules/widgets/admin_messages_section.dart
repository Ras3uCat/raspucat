import 'package:raspucat/app/controllers/admin_messages_controller.dart';
import 'package:raspucat/app/data/models/portal_message_model.dart';
import 'package:raspucat/utils/constants/exports.dart';

class AdminMessagesSection extends StatelessWidget {
  const AdminMessagesSection({super.key, required this.quoteId});
  final String quoteId;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(
      AdminMessagesController(quoteId),
      tag: 'admin_msg_$quoteId',
    );

    return Column(
      children: [
        _header(ctrl),
        Expanded(child: _messagesList(ctrl)),
        _MessageInput(ctrl: ctrl),
      ],
    );
  }

  Widget _header(AdminMessagesController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'CLIENT MESSAGES',
            style: TextStyle(
              color: EColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Obx(() => ctrl.isLoading.value
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: EColors.primary, strokeWidth: 1.5),
                )
              : GestureDetector(
                  onTap: ctrl.loadMessages,
                  child: Icon(Icons.refresh,
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      size: 16),
                )),
        ],
      ),
    );
  }

  Widget _messagesList(AdminMessagesController ctrl) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
        );
      }
      if (ctrl.messages.isEmpty) {
        return Center(
          child: Text(
            'No messages yet.',
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.35),
              fontSize: ESizes.fontSizeSm,
            ),
          ),
        );
      }
      return ListView.builder(
        controller: ctrl.scrollController,
        padding: const EdgeInsets.all(ESizes.md),
        itemCount: ctrl.messages.length,
        itemBuilder: (_, i) => _MessageBubble(message: ctrl.messages[i]),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final PortalMessage message;

  @override
  Widget build(BuildContext context) {
    // From admin's perspective: admin = right (us), client = left (them)
    final isAdmin = !message.isFromClient;
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.md),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAdmin) ...[
            _avatar(isAdmin: false),
            const SizedBox(width: ESizes.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESizes.md, vertical: ESizes.sm + 2),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? EColors.primary.withValues(alpha: 0.15)
                        : EColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(ESizes.borderRadiusLg),
                      topRight: const Radius.circular(ESizes.borderRadiusLg),
                      bottomLeft: Radius.circular(
                          isAdmin ? ESizes.borderRadiusLg : ESizes.xs),
                      bottomRight: Radius.circular(
                          isAdmin ? ESizes.xs : ESizes.borderRadiusLg),
                    ),
                    border: Border.all(
                      color: isAdmin
                          ? EColors.primary.withValues(alpha: 0.3)
                          : EColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    message.body,
                    style: TextStyle(
                      color: isAdmin
                          ? EColors.textWhite
                          : EColors.textSecondary.withValues(alpha: 0.85),
                      fontSize: ESizes.fontSizeSm,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.timeLabel,
                  style: TextStyle(
                    color: EColors.textSecondary.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: ESizes.sm),
            _avatar(isAdmin: true),
          ],
        ],
      ),
    );
  }

  Widget _avatar({required bool isAdmin}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: EColors.primary.withValues(alpha: isAdmin ? 0.2 : 0.06),
        border: Border.all(
            color: EColors.primary.withValues(alpha: isAdmin ? 0.4 : 0.12)),
      ),
      child: Icon(
        isAdmin ? Icons.support_agent_outlined : Icons.person_outline,
        color: EColors.primary.withValues(alpha: 0.8),
        size: 14,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

class _MessageInput extends StatefulWidget {
  const _MessageInput({required this.ctrl});
  final AdminMessagesController ctrl;

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _textCtrl = TextEditingController();

  void _send() {
    final text = _textCtrl.text;
    if (text.trim().isEmpty) return;
    widget.ctrl.sendMessage(text);
    _textCtrl.clear();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              onSubmitted: (_) => _send(),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                  color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
              decoration: InputDecoration(
                hintText: 'Reply to client…',
                hintStyle: TextStyle(
                  color: EColors.textSecondary.withValues(alpha: 0.3),
                  fontSize: ESizes.fontSizeSm,
                ),
                filled: true,
                fillColor: EColors.primary.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: ESizes.md, vertical: ESizes.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(
                      color: EColors.primary.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(
                      color: EColors.primary.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(
                      color: EColors.primary.withValues(alpha: 0.5), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: ESizes.sm),
          Obx(() => GestureDetector(
                onTap: widget.ctrl.isSending.value ? null : _send,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: EColors.primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(ESizes.borderRadiusMd),
                    border: Border.all(
                        color: EColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: widget.ctrl.isSending.value
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              color: EColors.primary, strokeWidth: 1.5),
                        )
                      : const Icon(Icons.send_outlined,
                          color: EColors.primary, size: 16),
                ),
              )),
        ],
      ),
    );
  }
}
