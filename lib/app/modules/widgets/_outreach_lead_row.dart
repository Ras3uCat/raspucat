part of 'admin_outreach_widget.dart';

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead, required this.ctrl, required this.index});
  final LeadModel lead;
  final AdminOutreachController ctrl;
  final int index;

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
            SizedBox(
              width: 32,
              child: Text(
                '$index',
                style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          lead.companyName,
                          style: const TextStyle(
                            color: EColors.cyanTintedWhite,
                            fontSize: ESizes.fontSizeSm,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lead.hasReports) ...[
                        const SizedBox(width: 5),
                        Tooltip(
                          message: 'Research prepared',
                          child: Icon(
                            Icons.article_outlined,
                            size: 13,
                            color: EColors.primary.withAlpha(180),
                          ),
                        ),
                      ],
                      if (lead.lastBounceAt != null) ...[
                        const SizedBox(width: 5),
                        Tooltip(
                          message: 'Last email bounced',
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _relativeTime(lead.lastContactedAt),
                    style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                  ),
                  if (lead.isOverdue && !lead.isClosed) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: EColors.overdueAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ] else if (lead.nextFollowupAt != null && !lead.isClosed) ...[
                    const SizedBox(width: 6),
                    Text(
                      _formatFollowupDate(lead.nextFollowupAt!),
                      style: TextStyle(color: EColors.cyanTintedWhite.withAlpha(102), fontSize: 11),
                    ),
                  ],
                ],
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

String _formatFollowupDate(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[dt.month - 1];
  final sameYear = dt.year == DateTime.now().year;
  return sameYear ? '$month ${dt.day}' : '$month ${dt.day}, ${dt.year}';
}
