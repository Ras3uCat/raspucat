part of 'admin_outreach_widget.dart';

const _kKanbanColumns = [
  ('prospect', 'Prospect'),
  ('contacted', 'Contacted'),
  ('replied', 'Replied'),
  ('call_booked', 'Call Booked'),
  ('proposal_sent', 'Proposal Sent'),
  ('closed_won', 'Closed Won'),
  ('closed_lost', 'Closed Lost'),
];

class _OutreachKanbanView extends StatelessWidget {
  const _OutreachKanbanView({required this.ctrl, this.searchQuery = ''});
  final AdminOutreachController ctrl;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allLeads = ctrl.leads;
      final leads = searchQuery.isEmpty
          ? allLeads
          : allLeads.where((l) => l.companyName.toLowerCase().contains(searchQuery)).toList();
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(ESizes.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _kKanbanColumns.map((col) {
              final (status, label) = col;
              final colLeads = leads.where((l) => l.status == status).toList()
                ..sort((a, b) => b.score.compareTo(a.score));
              return _KanbanColumn(status: status, label: label, leads: colLeads, ctrl: ctrl);
            }).toList(),
          ),
        ),
      );
    });
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.label,
    required this.leads,
    required this.ctrl,
  });

  final String status;
  final String label;
  final List<LeadModel> leads;
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(5),
        border: Border.all(color: EColors.primary.withAlpha(20)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: color.withAlpha(60))),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: ESizes.sm),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: ESizes.fontSizeLabel,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '${leads.length}',
                  style: TextStyle(color: color.withAlpha(153), fontSize: ESizes.fontSizeLabel),
                ),
              ],
            ),
          ),
          if (leads.isEmpty)
            Padding(
              padding: const EdgeInsets.all(ESizes.md),
              child: Text(
                'None',
                style: TextStyle(
                  color: EColors.softGrey.withAlpha(102),
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            )
          else
            ...leads.map((lead) => _KanbanCard(lead: lead, ctrl: ctrl)),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.lead, required this.ctrl});
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
        margin: const EdgeInsets.fromLTRB(ESizes.sm, ESizes.sm, ESizes.sm, 0),
        padding: const EdgeInsets.all(ESizes.sm),
        decoration: BoxDecoration(
          color: EColors.primary.withAlpha(8),
          border: Border.all(color: EColors.primary.withAlpha(25)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.industry,
                    style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
              ],
            ),
            if (lead.lastContactedAt != null) ...[
              const SizedBox(height: 3),
              Text(
                _relativeTime(lead.lastContactedAt),
                style: TextStyle(color: EColors.softGrey.withAlpha(128), fontSize: 10),
              ),
            ],
            if (lead.isOverdue && !lead.isClosed) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: EColors.overdueAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'overdue',
                    style: const TextStyle(color: EColors.overdueAmber, fontSize: 10),
                  ),
                ],
              ),
            ] else if (lead.nextFollowupAt != null && !lead.isClosed) ...[
              const SizedBox(height: 4),
              Text(
                _formatFollowupDate(lead.nextFollowupAt!),
                style: TextStyle(color: EColors.cyanTintedWhite.withAlpha(102), fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
