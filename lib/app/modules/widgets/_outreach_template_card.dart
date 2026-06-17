part of 'admin_outreach_widget.dart';

class _TemplatesList extends StatelessWidget {
  const _TemplatesList({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.industryProfiles.isEmpty) {
        return const Center(
          child: Text(
            'No industry profiles — run /industry-setup to get started.',
            style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
          ),
        );
      }
      return ListView.separated(
        itemCount: ctrl.industryProfiles.length,
        separatorBuilder: (_, _) => const SizedBox(height: ESizes.sm),
        itemBuilder: (_, i) => _IndustryTemplateCard(profile: ctrl.industryProfiles[i], ctrl: ctrl),
      );
    });
  }
}

class _IndustryTemplateCard extends StatefulWidget {
  const _IndustryTemplateCard({required this.profile, required this.ctrl});
  final IndustryProfileModel profile;
  final AdminOutreachController ctrl;

  @override
  State<_IndustryTemplateCard> createState() => _IndustryTemplateCardState();
}

class _IndustryTemplateCardState extends State<_IndustryTemplateCard> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _subject;
  late TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _subject = TextEditingController(text: widget.profile.emailSubjectTemplate ?? '');
    _body = TextEditingController(text: widget.profile.emailBodyTemplate ?? '');
  }

  @override
  void didUpdateWidget(_IndustryTemplateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _subject.text = widget.profile.emailSubjectTemplate ?? '';
      _body.text = widget.profile.emailBodyTemplate ?? '';
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _startEdit() => setState(() => _editing = true);
  void _cancel() {
    _subject.text = widget.profile.emailSubjectTemplate ?? '';
    _body.text = widget.profile.emailBodyTemplate ?? '';
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.ctrl.updateIndustryTemplate(
      widget.profile.slug,
      _subject.text.trim(),
      _body.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTemplate =
        widget.profile.emailBodyTemplate != null && widget.profile.emailBodyTemplate!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(8),
        border: Border.all(
          color: _editing ? EColors.primary.withAlpha(80) : EColors.primary.withAlpha(31),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ESizes.md, ESizes.sm, ESizes.sm, ESizes.sm),
            child: Row(
              children: [
                Text(
                  '// ${widget.profile.name.toUpperCase()}',
                  style: const TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (!_editing)
                  GestureDetector(
                    onTap: _startEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: EColors.primary.withAlpha(77)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        hasTemplate ? 'Edit' : 'Add Template',
                        style: const TextStyle(
                          color: EColors.primary,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_editing)
            _buildEditor()
          else if (hasTemplate)
            _buildPreview()
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(ESizes.md, 0, ESizes.md, ESizes.sm),
              child: Text(
                'No template yet — click Add Template to write one, or run /industry-setup to auto-generate.',
                style: TextStyle(
                  color: EColors.softGrey.withAlpha(160),
                  fontSize: ESizes.fontSizeLabel,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (_editing) _buildActions(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, 0, ESizes.md, ESizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject: ${widget.profile.emailSubjectTemplate ?? ''}',
            style: TextStyle(
              color: EColors.cyanTintedWhite.withAlpha(160),
              fontSize: ESizes.fontSizeLabel,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: ESizes.sm),
          _EmailBodyLivePreview(text: widget.profile.emailBodyTemplate!),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, 0, ESizes.md, ESizes.sm),
      child: Column(
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
            controller: _subject,
            style: TextStyle(
              color: EColors.cyanTintedWhite.withAlpha(220),
              fontSize: ESizes.fontSizeLabel,
            ),
            decoration: InputDecoration(
              hintText: "Quick question about {COMPANY}'s website",
              hintStyle: TextStyle(
                color: EColors.softGrey.withAlpha(100),
                fontSize: ESizes.fontSizeLabel,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: ESizes.sm),
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
            controller: _body,
            maxLines: null,
            style: TextStyle(
              color: EColors.cyanTintedWhite.withAlpha(220),
              fontSize: ESizes.fontSizeLabel,
              height: 1.7,
            ),
            decoration: InputDecoration(
              hintText:
                  'Hi {FIRST_NAME},\n\nUse {COMPANY}, {BOOKING_LINK}, {DEMO_LINK} as placeholders.',
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
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, 0, ESizes.md, ESizes.sm),
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
