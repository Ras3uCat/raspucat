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
      if (ctrl.pipelineViewMode.value == 1) {
        return _OutreachKanbanView(ctrl: ctrl);
      }
      final leads = ctrl.filteredLeadsByStatus;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IndustryFilterBar(ctrl: ctrl),
          if (leads.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No leads yet.',
                  style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ESizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PipelineTableHeader(),
                    const SizedBox(height: ESizes.sm),
                    ...leads.asMap().entries.map(
                      (e) => _LeadRow(lead: e.value, ctrl: ctrl, index: e.key + 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          SizedBox(width: 32, child: Text('#', style: labelStyle)),
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
