part of 'admin_outreach_widget.dart';

Color _scoreColor(int score) {
  if (score >= 70) return Colors.green;
  if (score >= 40) return Colors.orange;
  return Colors.redAccent;
}

Color _statusColor(String status) {
  switch (status) {
    case 'prospect':
      return Colors.grey;
    case 'contacted':
      return Colors.blue;
    case 'replied':
      return EColors.primary;
    case 'call_booked':
      return Colors.purple;
    case 'proposal_sent':
      return Colors.orange;
    case 'closed_won':
      return Colors.green;
    case 'closed_lost':
    case 'unsubscribed':
      return Colors.red.shade900;
    default:
      return Colors.grey;
  }
}

String _relativeTime(DateTime? dt) {
  if (dt == null) return '—';
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  return '${diff.inMinutes}m ago';
}

class _OutreachPipelineView extends StatelessWidget {
  const _OutreachPipelineView({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final leads = ctrl.leadsByStatus;
      if (leads.isEmpty) {
        return const Center(
          child: Text(
            'No leads yet.',
            style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(ESizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PipelineTableHeader(),
            const SizedBox(height: ESizes.sm),
            ...leads.map((lead) => _LeadRow(lead: lead, ctrl: ctrl)),
          ],
        ),
      );
    });
  }
}

class _PipelineTableHeader extends StatelessWidget {
  const _PipelineTableHeader();

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: EColors.softGrey,
      fontSize: ESizes.fontSizeLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('COMPANY', style: labelStyle)),
          Expanded(flex: 2, child: Text('INDUSTRY', style: labelStyle)),
          Expanded(flex: 2, child: Text('LOCATION', style: labelStyle)),
          SizedBox(width: 56, child: Text('SCORE', style: labelStyle)),
          Expanded(flex: 2, child: Text('STATUS', style: labelStyle)),
          Expanded(flex: 2, child: Text('LAST CONTACT', style: labelStyle)),
          SizedBox(width: 80, child: Text('ACTIONS', style: labelStyle)),
        ],
      ),
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead, required this.ctrl});
  final LeadModel lead;
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ctrl.selectedLead.value = lead;
        _showLeadDetailPanel(context, ctrl);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: ESizes.sm),
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.sm),
        decoration: BoxDecoration(
          color: EColors.primary.withAlpha(8),
          border: Border.all(color: EColors.primary.withAlpha(25)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lead.companyName,
                    style: const TextStyle(
                      color: EColors.cyanTintedWhite,
                      fontSize: ESizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lead.sources.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _SourceBadges(sources: lead.sources),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                lead.industry,
                style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                lead.locationDisplay.isEmpty ? '—' : lead.locationDisplay,
                style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 56,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(lead.status).withAlpha(38),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  lead.status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: _statusColor(lead.status),
                    fontSize: ESizes.fontSizeLabel,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _relativeTime(lead.lastContactedAt),
                style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 14, color: EColors.primary),
                    tooltip: 'View',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ctrl.selectedLead.value = lead;
                      _showLeadDetailPanel(context, ctrl);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => ctrl.deleteLead(lead.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadges extends StatelessWidget {
  const _SourceBadges({required this.sources});
  final List<String> sources;

  static const _labels = {
    'google': ('G', Color(0xFF34A853)),
    'yelp': ('Y', Color(0xFFD32323)),
    'angi': ('A', Color(0xFFFF6D00)),
    'apollo': ('Ap', Color(0xFF4A90D9)),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: sources.map((s) {
        final info = _labels[s.toLowerCase()];
        if (info == null) return const SizedBox.shrink();
        final (label, color) = info;
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }).toList(),
    );
  }
}

void _showLeadDetailPanel(BuildContext context, AdminOutreachController ctrl) {
  showDialog(
    context: context,
    builder: (_) => _LeadDetailPanel(ctrl: ctrl),
  );
}
