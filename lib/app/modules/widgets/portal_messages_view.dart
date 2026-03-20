import 'package:raspucat/app/controllers/portal_messages_controller.dart';
import 'package:raspucat/app/data/models/portal_message_model.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalMessagesView extends StatelessWidget {
  const PortalMessagesView({super.key, required this.quoteId});
  final String quoteId;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(
      PortalMessagesController(quoteId),
      tag: quoteId,
    );

    return Column(
      children: [
        _MessagesHeader(ctrl: ctrl),
        Expanded(child: _MessagesList(ctrl: ctrl)),
        _MessageInput(ctrl: ctrl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({required this.ctrl});
  final PortalMessagesController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.xl, vertical: ESizes.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline,
              color: EColors.primary, size: 18),
          const SizedBox(width: ESizes.sm),
          const Text(
            'Messages',
            style: TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeLg,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Obx(() => ctrl.isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: EColors.primary, strokeWidth: 1.5),
                )
              : IconButton(
                  icon: Icon(Icons.refresh,
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      size: 18),
                  onPressed: ctrl.loadMessages,
                )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Messages list
// ---------------------------------------------------------------------------

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.ctrl});
  final PortalMessagesController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
              color: EColors.primary, strokeWidth: 2),
        );
      }
      if (ctrl.messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  color: EColors.textSecondary.withValues(alpha: 0.2),
                  size: 40),
              const SizedBox(height: ESizes.md),
              Text(
                'No messages yet.\nSend us a message to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EColors.textSecondary.withValues(alpha: 0.35),
                  fontSize: ESizes.fontSizeSm,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: ctrl.scrollController,
        padding: const EdgeInsets.symmetric(
            horizontal: ESizes.xl, vertical: ESizes.lg),
        itemCount: ctrl.messages.length,
        itemBuilder: (_, i) => _MessageBubble(message: ctrl.messages[i]),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final PortalMessage message;

  @override
  Widget build(BuildContext context) {
    final isClient = message.isFromClient;

    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.md),
      child: Row(
        mainAxisAlignment:
            isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isClient) ...[
            _Avatar(isClient: false),
            const SizedBox(width: ESizes.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isClient
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESizes.md, vertical: ESizes.sm + 2),
                  constraints: const BoxConstraints(maxWidth: 480),
                  decoration: BoxDecoration(
                    color: isClient
                        ? EColors.primary.withValues(alpha: 0.15)
                        : EColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(ESizes.borderRadiusLg),
                      topRight: const Radius.circular(ESizes.borderRadiusLg),
                      bottomLeft: Radius.circular(
                          isClient ? ESizes.borderRadiusLg : ESizes.xs),
                      bottomRight: Radius.circular(
                          isClient ? ESizes.xs : ESizes.borderRadiusLg),
                    ),
                    border: Border.all(
                      color: isClient
                          ? EColors.primary.withValues(alpha: 0.3)
                          : EColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    message.body,
                    style: TextStyle(
                      color: isClient
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
          if (isClient) ...[
            const SizedBox(width: ESizes.sm),
            _Avatar(isClient: true),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isClient});
  final bool isClient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: EColors.primary.withValues(alpha: isClient ? 0.2 : 0.08),
        border: Border.all(
            color: EColors.primary.withValues(alpha: isClient ? 0.4 : 0.15)),
      ),
      child: Icon(
        isClient ? Icons.person_outline : Icons.support_agent_outlined,
        color: EColors.primary.withValues(alpha: 0.8),
        size: 15,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message input
// ---------------------------------------------------------------------------

class _MessageInput extends StatefulWidget {
  const _MessageInput({required this.ctrl});
  final PortalMessagesController ctrl;

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
                hintText: 'Send a message…',
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
                  borderSide:
                      BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide:
                      BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(
                      color: EColors.primary.withValues(alpha: 0.5),
                      width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: ESizes.sm),
          Obx(() => GestureDetector(
                onTap: widget.ctrl.isSending.value ? null : _send,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
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
                          color: EColors.primary, size: 18),
                ),
              )),
        ],
      ),
    );
  }
}
