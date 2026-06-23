part of 'admin_outreach_widget.dart';

class _SentList extends StatelessWidget {
  const _SentList({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.sentEmails.isEmpty) {
        return const Center(
          child: Text(
            'No sent emails yet.',
            style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
          ),
        );
      }
      return ListView.separated(
        itemCount: ctrl.sentEmails.length,
        separatorBuilder: (_, _) => const SizedBox(height: ESizes.sm),
        itemBuilder: (context, i) {
          final email = ctrl.sentEmails[i];
          final lead = ctrl.leads.where((l) => l.id == email.leadId).firstOrNull;
          return _SentCard(email: email, leadName: lead?.companyName ?? '—');
        },
      );
    });
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({required this.email, required this.leadName});
  final OutreachEmailModel email;
  final String leadName;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusDisplay();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.04),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: ESizes.sm, top: 2),
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
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
                  email.subject,
                  style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                ),
              ],
            ),
          ),
          const SizedBox(width: ESizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (email.sentAt != null)
                Text(
                  'Sent ${_relativeTime(email.sentAt!)}',
                  style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _statusDisplay() {
    if (email.clickedAt != null) {
      return ('Clicked ${_relativeTime(email.clickedAt!)}', EColors.primary);
    }
    if (email.openedAt != null) {
      return ('Opened ${_relativeTime(email.openedAt!)}', EColors.primary);
    }
    return ('Awaiting open', EColors.softGrey);
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
