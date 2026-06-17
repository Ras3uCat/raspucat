part of 'admin_outreach_widget.dart';

class _OutreachDraftsView extends StatefulWidget {
  const _OutreachDraftsView({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  State<_OutreachDraftsView> createState() => _OutreachDraftsViewState();
}

class _OutreachDraftsViewState extends State<_OutreachDraftsView> {
  bool _showTemplates = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: ESizes.md),
          Expanded(
            child: _showTemplates
                ? _TemplatesList(ctrl: widget.ctrl)
                : _DraftsList(ctrl: widget.ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _DraftsTabButton(
          label: '// DRAFTS',
          selected: !_showTemplates,
          onTap: () => setState(() => _showTemplates = false),
        ),
        const SizedBox(width: ESizes.md),
        _DraftsTabButton(
          label: '// TEMPLATES',
          selected: _showTemplates,
          onTap: () => setState(() => _showTemplates = true),
        ),
        const Spacer(),
        if (!_showTemplates)
          Obx(
            () => widget.ctrl.isSending.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
                  )
                : GestureDetector(
                    onTap: widget.ctrl.sendBatch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: EColors.primary.withAlpha(20),
                        border: Border.all(color: EColors.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Send Batch',
                        style: TextStyle(
                          color: EColors.primary,
                          fontSize: ESizes.fontSizeLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _DraftsTabButton extends StatelessWidget {
  const _DraftsTabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? EColors.primary.withAlpha(20) : Colors.transparent,
          border: Border.all(color: selected ? EColors.primary : EColors.primary.withAlpha(51)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? EColors.primary : EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DraftsList extends StatelessWidget {
  const _DraftsList({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.drafts.isEmpty) {
        return const Center(
          child: Text(
            'No drafts.',
            style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
          ),
        );
      }
      return ListView.separated(
        itemCount: ctrl.drafts.length,
        separatorBuilder: (_, _) => const SizedBox(height: ESizes.sm),
        itemBuilder: (context, i) {
          final draft = ctrl.drafts[i];
          final lead = ctrl.leads.where((l) => l.id == draft.leadId).firstOrNull;
          return _DraftCard(draft: draft, leadName: lead?.companyName ?? '—', ctrl: ctrl);
        },
      );
    });
  }
}
