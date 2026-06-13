part of 'admin_outreach_widget.dart';

class _DraftCard extends StatefulWidget {
  const _DraftCard({required this.draft, required this.leadName, required this.ctrl});

  final OutreachEmailModel draft;
  final String leadName;
  final AdminOutreachController ctrl;

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(10),
        border: Border.all(
          color: _expanded ? EColors.primary.withAlpha(80) : EColors.primary.withAlpha(31),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DraftCardHeader(
            draft: widget.draft,
            leadName: widget.leadName,
            ctrl: widget.ctrl,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) _DraftCardBody(draft: widget.draft, ctrl: widget.ctrl),
        ],
      ),
    );
  }
}

class _DraftCardHeader extends StatelessWidget {
  const _DraftCardHeader({
    required this.draft,
    required this.leadName,
    required this.ctrl,
    required this.expanded,
    required this.onToggle,
  });

  final OutreachEmailModel draft;
  final String leadName;
  final AdminOutreachController ctrl;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        child: Row(
          children: [
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: EColors.softGrey,
            ),
            const SizedBox(width: ESizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leadName,
                    style: const TextStyle(
                      color: EColors.cyanTintedWhite,
                      fontSize: ESizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    draft.subject,
                    style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_outlined, size: 16, color: EColors.primary),
              tooltip: 'Send',
              onPressed: () => ctrl.sendEmail(draft.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              tooltip: 'Delete draft',
              onPressed: () => ctrl.deleteDraft(draft.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCardBody extends StatelessWidget {
  const _DraftCardBody({required this.draft, required this.ctrl});
  final OutreachEmailModel draft;
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, 0, ESizes.md, ESizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: EColors.primary, height: 1),
          const SizedBox(height: ESizes.sm),
          _EmailBodyPane(draft: draft, ctrl: ctrl),
          if (draft.notes != null) ...[
            const SizedBox(height: ESizes.sm),
            _InternalNotesPane(notes: draft.notes!),
          ],
        ],
      ),
    );
  }
}

class _InternalNotesPane extends StatelessWidget {
  const _InternalNotesPane({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESizes.md),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(10),
        border: Border(left: BorderSide(color: Colors.amber.withAlpha(120), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// INTERNAL NOTES',
            style: TextStyle(
              color: Colors.amber,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: ESizes.xs),
          SelectableText(
            notes,
            style: TextStyle(
              color: EColors.cyanTintedWhite.withAlpha(180),
              fontSize: ESizes.fontSizeLabel,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
