part of 'admin_outreach_widget.dart';

String _toHtml(String plainText) {
  final lines = plainText.split('\n');
  final buffer = StringBuffer();
  final bulletLines = <String>[];

  void flushBullets() {
    if (bulletLines.isEmpty) return;
    buffer.write('<ul>');
    for (final b in bulletLines) {
      buffer.write('<li>${b.trim()}</li>');
    }
    buffer.write('</ul>');
    bulletLines.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      flushBullets();
      continue;
    }
    if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
      bulletLines.add(trimmed.substring(2));
    } else {
      flushBullets();
      buffer.write('<p>$trimmed</p>');
    }
  }
  flushBullets();
  return buffer.toString();
}

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
  bool _loadingPreview = false;
  String? _previewHtml;
  late TextEditingController _textCtrl;

  // Changes when _previewHtml changes so HtmlElementView re-renders.
  String get _viewType => 'email-preview-${widget.draft.id}-${_previewHtml?.hashCode ?? 0}';

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

  void _ensureViewRegistered() {
    final preview = _previewHtml;
    if (preview == null) return;
    final type = _viewType;
    if (_registeredViewTypes.contains(type)) return;
    _registeredViewTypes.add(type);
    ui_web.platformViewRegistry.registerViewFactory(type, (_) {
      return html.IFrameElement()
        ..srcdoc = preview
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  Future<void> _loadPreview() async {
    if (!mounted || _loadingPreview) return;
    setState(() => _loadingPreview = true);
    final result = await widget.ctrl.getEmailPreview(widget.draft.id);
    if (!mounted) return;
    setState(() {
      _previewHtml = result;
      _loadingPreview = false;
    });
    _ensureViewRegistered();
  }

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _plainText);
    _loadPreview();
  }

  @override
  void didUpdateWidget(_EmailBodyPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.bodyHtml != widget.draft.bodyHtml) {
      _loadPreview();
    }
  }

  @override
  void dispose() {
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
    _loadPreview();
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
    if (_loadingPreview) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
          ),
        ),
      );
    }
    if (_previewHtml == null) {
      // Preview fetch failed — render body text directly so content is never blank.
      return Padding(
        padding: const EdgeInsets.all(ESizes.md),
        child: SelectableText(
          widget.draft.bodyHtml.isEmpty ? '(empty)' : widget.draft.bodyHtml,
          style: const TextStyle(
            color: EColors.cyanTintedWhite,
            fontSize: ESizes.fontSizeSm,
            height: 1.6,
          ),
        ),
      );
    }
    _ensureViewRegistered();
    return SizedBox(height: 700, child: HtmlElementView(viewType: _viewType));
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, ESizes.md, ESizes.xl + ESizes.sm, ESizes.md),
      child: TextField(
        controller: _textCtrl,
        maxLines: null,
        style: TextStyle(
          color: EColors.cyanTintedWhite.withAlpha(220),
          fontSize: ESizes.fontSizeLabel,
          height: 1.7,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
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
