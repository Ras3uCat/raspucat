part of 'admin_outreach_widget.dart';

class _DetailEmailHistory extends StatelessWidget {
  const _DetailEmailHistory({required this.lead, required this.ctrl});
  final LeadModel lead;
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final emails = ctrl.draftsForLead(lead.id);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// EMAIL HISTORY',
            style: TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: ESizes.sm),
          if (emails.isEmpty)
            const Text(
              'No emails yet.',
              style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
            )
          else
            ...emails.map((e) => _EmailHistoryRow(email: e)),
        ],
      );
    });
  }
}

class _EmailHistoryRow extends StatelessWidget {
  const _EmailHistoryRow({required this.email});
  final OutreachEmailModel email;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESizes.sm),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(8),
        border: Border.all(color: EColors.primary.withAlpha(25)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              email.subject,
              style: const TextStyle(
                color: EColors.cyanTintedWhite,
                fontSize: ESizes.fontSizeLabel,
              ),
            ),
          ),
          if (email.isDraft)
            const _StatusDot(label: 'Draft', color: Colors.orange)
          else ...[
            if (email.openedAt != null) const _StatusDot(label: 'Opened', color: EColors.primary),
            if (email.clickedAt != null) const _StatusDot(label: 'Clicked', color: Colors.purple),
            if (email.repliedAt != null) const _StatusDot(label: 'Replied', color: Colors.green),
            if (email.openedAt == null && email.clickedAt == null && email.repliedAt == null)
              const _StatusDot(label: 'Sent', color: Colors.grey),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: ESizes.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(color: color, fontSize: ESizes.fontSizeLabel),
          ),
        ],
      ),
    );
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({required this.lead, required this.ctrl});
  final LeadModel lead;
  final AdminOutreachController ctrl;

  static const _stages = [
    'prospect',
    'contacted',
    'replied',
    'call_booked',
    'proposal_sent',
    'closed_won',
    'closed_lost',
    'unsubscribed',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// ACTIONS',
          style: TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Wrap(
          spacing: ESizes.sm,
          runSpacing: ESizes.sm,
          children: [
            _ActionButton(label: 'Edit', onTap: () => _showLeadFormDialog(context, ctrl, lead)),
            _MoveStageDropdown(lead: lead, ctrl: ctrl, stages: _stages),
            if (lead.status == 'prospect' || lead.status == 'contacted')
              _ActionButton(
                label: 'Compose Email',
                onTap: () => _showComposePanel(context, ctrl, lead),
              ),
            if (lead.status == 'call_booked')
              _ActionButton(
                label: 'Copy Discovery Script Prompt',
                onTap: () => _copyDiscoveryPrompt(lead),
              ),
            if (lead.status == 'proposal_sent')
              _ActionButton(label: 'Copy Closer Deck Prompt', onTap: () => _copyCloserPrompt(lead)),
          ],
        ),
      ],
    );
  }

  void _copyDiscoveryPrompt(LeadModel l) {
    final text =
        '/discovery-script\n\n'
        'Industry: ${l.industry}\n'
        'Company: ${l.companyName}\n'
        'Location: ${l.locationDisplay}\n'
        'Website: ${l.website ?? 'unknown'}';
    Clipboard.setData(ClipboardData(text: text));
  }

  void _copyCloserPrompt(LeadModel l) {
    final text =
        '/closer-deck\n\n'
        'Company: ${l.companyName}\n'
        'Industry: ${l.industry}\n'
        'Location: ${l.locationDisplay}\n\n'
        '[Paste your discovery call transcript below]';
    Clipboard.setData(ClipboardData(text: text));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 6),
        decoration: BoxDecoration(
          color: EColors.primary.withAlpha(15),
          border: Border.all(color: EColors.primary.withAlpha(77)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MoveStageDropdown extends StatelessWidget {
  const _MoveStageDropdown({required this.lead, required this.ctrl, required this.stages});
  final LeadModel lead;
  final AdminOutreachController ctrl;
  final List<String> stages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(15),
        border: Border.all(color: EColors.primary.withAlpha(77)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: lead.status,
          dropdownColor: const Color(0xFF0A0E1A),
          style: const TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeLabel),
          icon: const Icon(Icons.keyboard_arrow_down, color: EColors.primary, size: 16),
          items: stages
              .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))))
              .toList(),
          onChanged: (s) {
            if (s != null && s != lead.status) {
              ctrl.updateLead(lead.id, {'status': s});
            }
          },
        ),
      ),
    );
  }
}
