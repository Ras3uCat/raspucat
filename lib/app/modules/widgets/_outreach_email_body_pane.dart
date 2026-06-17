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

  void _onTextChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _plainText);
    _textCtrl.addListener(_onTextChanged);
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
      // Preview fetch failed — show parsed body + retry so content is never blank.
      return Padding(
        padding: const EdgeInsets.all(ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Preview unavailable',
                  style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadPreview,
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: EColors.primary,
                      fontSize: ESizes.fontSizeLabel,
                      decoration: TextDecoration.underline,
                      decorationColor: EColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (_plainText.trim().isNotEmpty) ...[
              const SizedBox(height: ESizes.md),
              _EmailBodyLivePreview(text: _plainText),
            ],
          ],
        ),
      );
    }
    _ensureViewRegistered();
    return SizedBox(height: 700, child: HtmlElementView(viewType: _viewType));
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
