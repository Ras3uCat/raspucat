part of 'admin_outreach_widget.dart';

class _EditButton extends StatelessWidget {
  const _EditButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Edit body',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: active ? EColors.primary.withAlpha(60) : EColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.edit_outlined, size: 12, color: EColors.primary),
        ),
      ),
    );
  }
}

class _TestSendButton extends StatefulWidget {
  const _TestSendButton({required this.draft, required this.ctrl});

  final OutreachEmailModel draft;
  final AdminOutreachController ctrl;

  @override
  State<_TestSendButton> createState() => _TestSendButtonState();
}

class _TestSendButtonState extends State<_TestSendButton> {
  bool _loading = false;

  Future<void> _send() async {
    setState(() => _loading = true);
    await widget.ctrl.sendTestEmail(widget.draft.id);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Send test to ras3ucat@gmail.com',
      child: GestureDetector(
        onTap: _loading ? null : _send,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: EColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(3),
          ),
          child: _loading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
                )
              : const Icon(Icons.science_outlined, size: 12, color: EColors.primary),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text, required this.tooltip});
  final String text;
  final String tooltip;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _copied ? 'Copied!' : widget.tooltip,
      child: GestureDetector(
        onTap: _copy,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: EColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            _copied ? Icons.check : Icons.copy_outlined,
            size: 12,
            color: EColors.primary,
          ),
        ),
      ),
    );
  }
}
