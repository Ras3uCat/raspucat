part of 'admin_outreach_widget.dart';

class _LeadDetailPanel extends StatelessWidget {
  const _LeadDetailPanel({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0E1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: EColors.primary.withAlpha(51)),
      ),
      child: SizedBox(
        width: 640,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Obx(() {
          final lead = ctrl.selectedLead.value;
          if (lead == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailHeader(lead: lead, ctrl: ctrl),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ESizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailContactInfo(lead: lead),
                      const SizedBox(height: ESizes.lg),
                      _DetailNotes(lead: lead, ctrl: ctrl),
                      const SizedBox(height: ESizes.lg),
                      _DetailEmailHistory(lead: lead, ctrl: ctrl),
                      const SizedBox(height: ESizes.lg),
                      _DetailActions(lead: lead, ctrl: ctrl),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.lead, required this.ctrl});
  final LeadModel lead;
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.lg, ESizes.md, ESizes.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.primary.withAlpha(31))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.companyName,
                  style: const TextStyle(
                    color: EColors.cyanTintedWhite,
                    fontSize: ESizes.fontSizeMd,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lead.industry}${lead.locationDisplay.isNotEmpty ? ' · ${lead.locationDisplay}' : ''}',
                  style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _scoreColor(lead.score).withAlpha(38),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${lead.score}',
              style: TextStyle(
                color: _scoreColor(lead.score),
                fontSize: ESizes.fontSizeLabel,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: ESizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor(lead.status).withAlpha(38),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              lead.status.replaceAll('_', ' '),
              style: TextStyle(color: _statusColor(lead.status), fontSize: ESizes.fontSizeLabel),
            ),
          ),
          const SizedBox(width: ESizes.sm),
          IconButton(
            icon: const Icon(Icons.close, color: EColors.softGrey, size: 18),
            onPressed: () {
              ctrl.selectedLead.value = null;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

void _showComposePanel(BuildContext context, AdminOutreachController ctrl, LeadModel lead) {
  showDialog(
    context: context,
    builder: (_) => _OutreachComposePanel(ctrl: ctrl, lead: lead),
  );
}
