part of 'admin_outreach_widget.dart';

class _EmailBodyPane extends StatefulWidget {
  const _EmailBodyPane({required this.draft, required this.ctrl});

  final OutreachEmailModel draft;
  final AdminOutreachController ctrl;

  @override
  State<_EmailBodyPane> createState() => _EmailBodyPaneState();
}

class _EmailBodyPaneState extends State<_EmailBodyPane> {
  static final _registeredViewTypes = <String>{};

  bool _editing = false;
  bool _saving = false;
  // viewType is kept as a field — computed once per bodyHtml value.
  String _viewType = '';
  late TextEditingController _textCtrl;

  String get _plainText {
    String body = widget.draft.bodyHtml;
    // Convert block-level elements to predictable newlines before stripping tags,
    // so the editor always shows visible blank lines between paragraphs.
    body = body.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    body = body.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    body = body.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '- ');
    body = body.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    body = body.replaceAll(RegExp(r'<[^>]+>'), '');
    return body.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  // Builds preview HTML locally from the draft's bodyHtml — no edge function call.
  String get _previewHtmlContent {
    final raw = widget.draft.bodyHtml.trim();
    final String body;
    if (raw.isEmpty) {
      body =
          '<p style="color:rgba(232,254,255,0.3);font-style:italic;">'
          '(No content yet — use Edit above to add your message.)</p>';
    } else if (RegExp(r'</?(?:p|ul|ol|li|div|h[1-6]|br)\b', caseSensitive: false).hasMatch(raw)) {
      body = raw; // Already has block-level HTML — render as-is.
    } else {
      body = _toHtml(raw); // Plain text — convert to <p> paragraphs first.
    }
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<style>
  body{margin:0;padding:0;background:#000612;font-family:Inter,sans-serif;-webkit-font-smoothing:antialiased;}
  .body{max-width:600px;margin:0 auto;padding:32px 24px;}
  p{color:rgba(232,254,255,0.65);font-size:15px;line-height:1.8;margin:0 0 16px;}
  ul{margin:0 0 16px;padding-left:20px;}
  li{color:rgba(232,254,255,0.65);font-size:15px;line-height:1.8;margin:0 0 6px;}
  .note{font-size:11px;color:rgba(232,254,255,0.2);margin-top:32px;border-top:1px solid rgba(88,227,239,0.08);padding-top:16px;}
</style>
</head>
<body>
<div class="body">
  $body
  <p class="note">Branded header &amp; footer applied when sent.</p>
</div>
</body>
</html>''';
  }

  // Registers a platform view factory for the current bodyHtml and updates _viewType.
  void _syncPreview() {
    final previewHtml = _previewHtmlContent;
    final type = 'email-preview-${widget.draft.id}-${previewHtml.hashCode}';
    if (!_registeredViewTypes.contains(type)) {
      _registeredViewTypes.add(type);
      ui_web.platformViewRegistry.registerViewFactory(type, (_) {
        return html.IFrameElement()
          ..srcdoc = previewHtml
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
      });
    }
    if (_viewType != type) setState(() => _viewType = type);
  }

  void _onTextChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _plainText);
    _textCtrl.addListener(_onTextChanged);
    _syncPreview();
  }

  @override
  void didUpdateWidget(_EmailBodyPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.bodyHtml != widget.draft.bodyHtml) {
      _syncPreview();
    }
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    super.dispose();
  }

  void _startEdit() {
    _textCtrl.text = _plainText;
    setState(() => _editing = true);
  }

  void _cancel() => setState(() => _editing = false);

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.ctrl.updateDraft(widget.draft.id, bodyHtml: _toHtml(_textCtrl.text));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    // _syncPreview() is called automatically via didUpdateWidget when the
    // reactive draft updates after updateDraft completes.
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _EditButton(active: _editing, onTap: _editing ? null : _startEdit),
            const SizedBox(width: 4),
            _TestSendButton(draft: widget.draft, ctrl: widget.ctrl),
            const SizedBox(width: 4),
            _CopyButton(text: widget.draft.bodyHtml, tooltip: 'Copy HTML'),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: EColors.primary.withAlpha(8),
            border: Border.all(
              color: _editing ? EColors.primary.withAlpha(80) : EColors.primary.withAlpha(31),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _editing ? _buildEditor() : _buildPreview(),
        ),
        if (_editing) _buildEditActions(),
      ],
    );
  }

  Widget _buildPreview() {
    if (_viewType.isEmpty) return const SizedBox(height: 100);
    return SizedBox(height: 500, child: HtmlElementView(viewType: _viewType));
  }

  Widget _buildEditor() {
    final hasContent = _textCtrl.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ESizes.md,
            ESizes.md,
            ESizes.xl + ESizes.sm,
            ESizes.md,
          ),
          child: TextField(
            controller: _textCtrl,
            maxLines: null,
            style: TextStyle(
              color: EColors.cyanTintedWhite.withAlpha(220),
              fontSize: ESizes.fontSizeLabel,
              height: 1.7,
            ),
            decoration: InputDecoration(
              hintText: 'Write your email body here.\nUse a blank line between paragraphs.',
              hintStyle: TextStyle(
                color: EColors.softGrey.withAlpha(100),
                fontSize: ESizes.fontSizeLabel,
                height: 1.7,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (hasContent) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
            decoration: BoxDecoration(
              color: EColors.primary.withAlpha(15),
              border: Border(top: BorderSide(color: EColors.primary.withAlpha(40))),
            ),
            child: const Text(
              '// AS SENT',
              style: TextStyle(
                color: EColors.primary,
                fontSize: ESizes.fontSizeLabel,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(ESizes.md),
            child: _EmailBodyLivePreview(text: _textCtrl.text),
          ),
        ],
      ],
    );
  }

  Widget _buildEditActions() {
    return Padding(
      padding: const EdgeInsets.only(top: ESizes.sm),
      child: Row(
        children: [
          if (_saving)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
            )
          else
            TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                foregroundColor: EColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
                side: const BorderSide(color: EColors.primary),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Save', style: TextStyle(fontSize: ESizes.fontSizeLabel)),
            ),
          if (!_saving) ...[
            const SizedBox(width: ESizes.sm),
            TextButton(
              onPressed: _cancel,
              style: TextButton.styleFrom(
                foregroundColor: EColors.softGrey,
                padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: ESizes.fontSizeLabel)),
            ),
          ],
        ],
      ),
    );
  }
}
