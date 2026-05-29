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

class _DetailSiteAudit extends StatelessWidget {
  const _DetailSiteAudit({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    final audit = lead.websiteAudit;
    if (audit == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// SITE AUDIT',
            style: TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: ESizes.sm),
          Text(
            'Not yet audited.',
            style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
          ),
        ],
      );
    }

    final platform = audit['platform'] as String? ?? 'unknown';
    final hasHttps = audit['hasHttps'] as bool? ?? false;
    final hasViewport = audit['hasViewport'] as bool? ?? false;
    final hasBookingCta = audit['hasBookingCta'] as bool? ?? false;
    final pagespeedScore = audit['pagespeedScore'] as int?;
    final lastAuditedAt = audit['lastAuditedAt'] as String?;
    final painPoints = lead.painPointMatches;

    Color speedColor(int? score) {
      if (score == null) return EColors.softGrey;
      if (score >= 70) return Colors.green;
      if (score >= 50) return Colors.orange;
      return Colors.redAccent;
    }

    Widget auditRow(String label, String value, {Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? EColors.cyanTintedWhite,
                fontSize: ESizes.fontSizeLabel,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    Widget boolRow(String label, bool value, {bool invertColor = false}) {
      final isGood = invertColor ? !value : value;
      return auditRow(
        label,
        value ? 'Yes' : 'No',
        valueColor: isGood ? Colors.green : Colors.redAccent,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// SITE AUDIT',
          style: TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: EColors.primary.withAlpha(6),
            border: Border.all(color: EColors.primary.withAlpha(30)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              auditRow('Platform', platform),
              if (pagespeedScore != null)
                auditRow(
                  'PageSpeed',
                  '$pagespeedScore / 100',
                  valueColor: speedColor(pagespeedScore),
                ),
              boolRow('HTTPS', hasHttps),
              boolRow('Mobile viewport', hasViewport),
              boolRow('Booking CTA', hasBookingCta),
              if (lastAuditedAt != null) auditRow('Audited', lastAuditedAt.split('T').first),
              if (painPoints.isNotEmpty) ...[
                const SizedBox(height: ESizes.sm),
                _PainPointTags(painPoints: painPoints),
              ],
            ],
          ),
        ),
      ],
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
