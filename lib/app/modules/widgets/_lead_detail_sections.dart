part of 'admin_outreach_widget.dart';

class _DetailContactInfo extends StatelessWidget {
  const _DetailContactInfo({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    final painPoints = lead.painPointMatches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// CONTACT',
          style: TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        if (lead.sources.isNotEmpty) ...[
          _SourceBadges(sources: lead.sources),
          const SizedBox(height: ESizes.sm),
        ],
        if (lead.decisionMakerName != null)
          _ContactRow(
            icon: Icons.person_outline,
            value: lead.decisionMakerTitle != null
                ? '${lead.decisionMakerName} · ${lead.decisionMakerTitle}'
                : lead.decisionMakerName!,
          ),
        if (lead.website != null)
          _ContactRow(icon: Icons.language, value: lead.website!, isLink: true),
        if (lead.phone != null) _ContactRow(icon: Icons.phone_outlined, value: lead.phone!),
        if (lead.email != null) _ContactRow(icon: Icons.email_outlined, value: lead.email!),
        if (lead.website == null &&
            lead.phone == null &&
            lead.email == null &&
            lead.decisionMakerName == null)
          const Text(
            'No contact info.',
            style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
          ),
        if (painPoints.isNotEmpty) ...[
          const SizedBox(height: ESizes.sm),
          _PainPointTags(painPoints: painPoints),
        ],
      ],
    );
  }
}

const _painPointLabels = <String, String>{
  'no_booking_cta': 'No booking',
  'no_ssl': 'No HTTPS',
  'poor_mobile': 'Poor mobile',
  'slow_site': 'Slow site',
  'mediocre_speed': 'Mediocre speed',
  'diy_platform': 'Wix/DIY site',
};

class _PainPointTags extends StatelessWidget {
  const _PainPointTags({required this.painPoints});
  final List<String> painPoints;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: painPoints.map((p) {
        final label = _painPointLabels[p] ?? p;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(38),
            border: Border.all(color: Colors.amber.withAlpha(77)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value, this.isLink = false});
  final IconData icon;
  final String value;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: EColors.primary, size: 14),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLink ? EColors.primary : EColors.cyanTintedWhite,
                fontSize: ESizes.fontSizeLabel,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 12, color: EColors.softGrey),
            tooltip: 'Copy',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _DetailNotes extends StatefulWidget {
  const _DetailNotes({required this.lead, required this.ctrl});
  final LeadModel lead;
  final AdminOutreachController ctrl;

  @override
  State<_DetailNotes> createState() => _DetailNotesState();
}

class _DetailNotesState extends State<_DetailNotes> {
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.lead.notes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// NOTES',
          style: TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        TextField(
          controller: _notesCtrl,
          maxLines: 4,
          style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeLabel),
          onEditingComplete: () =>
              widget.ctrl.updateLead(widget.lead.id, {'notes': _notesCtrl.text}),
          decoration: InputDecoration(
            hintText: 'Add notes...',
            hintStyle: TextStyle(color: EColors.softGrey.withAlpha(128)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: EColors.primary.withAlpha(51)),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: EColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.all(ESizes.sm),
          ),
        ),
      ],
    );
  }
}
