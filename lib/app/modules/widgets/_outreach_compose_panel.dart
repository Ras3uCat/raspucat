part of 'admin_outreach_widget.dart';

class _OutreachComposePanel extends StatefulWidget {
  const _OutreachComposePanel({required this.ctrl, required this.lead});
  final AdminOutreachController ctrl;
  final LeadModel lead;

  @override
  State<_OutreachComposePanel> createState() => _OutreachComposePanelState();
}

class _OutreachComposePanelState extends State<_OutreachComposePanel> {
  late final TextEditingController _subject;
  late final TextEditingController _body;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _subject = TextEditingController(
      text: "Quick question about ${widget.lead.companyName}'s website",
    );
    _body = TextEditingController();
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _saveDraft() {
    widget.ctrl.saveDraft(widget.lead.id, _subject.text.trim(), _body.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0E1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: EColors.primary.withAlpha(51)),
      ),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(ESizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '// COMPOSE EMAIL',
                      style: TextStyle(
                        color: EColors.primary,
                        fontSize: ESizes.fontSizeLabel,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showPreview = !_showPreview),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showPreview ? EColors.primary.withAlpha(26) : Colors.transparent,
                        border: Border.all(color: EColors.primary.withAlpha(77)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _showPreview ? 'Edit' : 'Preview',
                        style: const TextStyle(
                          color: EColors.primary,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ESizes.lg),
              if (_showPreview)
                _ComposePreview(subject: _subject.text, body: _body.text)
              else
                _ComposeForm(subject: _subject, body: _body),
              const SizedBox(height: ESizes.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
                    ),
                  ),
                  const SizedBox(width: ESizes.lg),
                  Obx(
                    () => GestureDetector(
                      onTap: widget.ctrl.isLoading.value ? null : _saveDraft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ESizes.lg,
                          vertical: ESizes.sm,
                        ),
                        decoration: BoxDecoration(
                          color: EColors.primary.withAlpha(20),
                          border: Border.all(color: EColors.primary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: widget.ctrl.isLoading.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: EColors.primary,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : const Text(
                                'Save Draft',
                                style: TextStyle(
                                  color: EColors.primary,
                                  fontSize: ESizes.fontSizeSm,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeForm extends StatelessWidget {
  const _ComposeForm({required this.subject, required this.body});
  final TextEditingController subject;
  final TextEditingController body;

  static final _fieldBorder = OutlineInputBorder(
    borderSide: BorderSide(color: EColors.primary.withAlpha(51)),
    borderRadius: BorderRadius.circular(4),
  );
  static const _focusBorder = OutlineInputBorder(
    borderSide: BorderSide(color: EColors.primary),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUBJECT',
          style: TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: subject,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
          decoration: InputDecoration(
            enabledBorder: _fieldBorder,
            focusedBorder: _focusBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.sm),
            isDense: true,
          ),
        ),
        const SizedBox(height: ESizes.md),
        const Text(
          'BODY',
          style: TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: body,
          maxLines: 10,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
          decoration: InputDecoration(
            hintText: 'Write your email here...',
            hintStyle: TextStyle(color: EColors.softGrey.withAlpha(128)),
            enabledBorder: _fieldBorder,
            focusedBorder: _focusBorder,
            contentPadding: const EdgeInsets.all(ESizes.sm),
          ),
        ),
      ],
    );
  }
}

class _ComposePreview extends StatelessWidget {
  const _ComposePreview({required this.subject, required this.body});
  final String subject;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(8),
        border: Border.all(color: EColors.primary.withAlpha(31)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject: $subject',
            style: const TextStyle(
              color: EColors.cyanTintedWhite,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESizes.md),
          Text(
            body.isEmpty ? '(no body)' : body,
            style: TextStyle(
              color: body.isEmpty ? EColors.softGrey : EColors.cyanTintedWhite,
              fontSize: ESizes.fontSizeSm,
            ),
          ),
          const SizedBox(height: ESizes.md),
          Text(
            'Branded HTML wrapper applied server-side.',
            style: TextStyle(
              color: EColors.softGrey.withAlpha(153),
              fontSize: ESizes.fontSizeLabel,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
