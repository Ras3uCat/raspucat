part of 'admin_outreach_widget.dart';

class _OutreachDraftsView extends StatelessWidget {
  const _OutreachDraftsView({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Obx(() {
        if (ctrl.drafts.isEmpty) {
          return const Center(
            child: Text(
              'No drafts.',
              style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '// DRAFTS',
                  style: TextStyle(
                    color: EColors.primary,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                Obx(
                  () => ctrl.isSending.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: EColors.primary,
                            strokeWidth: 1.5,
                          ),
                        )
                      : GestureDetector(
                          onTap: ctrl.sendBatch,
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
            ),
            const SizedBox(height: ESizes.md),
            Expanded(
              child: ListView.separated(
                itemCount: ctrl.drafts.length,
                separatorBuilder: (_, _) => const SizedBox(height: ESizes.sm),
                itemBuilder: (context, i) {
                  final draft = ctrl.drafts[i];
                  final lead = ctrl.leads.where((l) => l.id == draft.leadId).firstOrNull;
                  return _DraftRow(draft: draft, leadName: lead?.companyName ?? '—', ctrl: ctrl);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.draft, required this.leadName, required this.ctrl});

  final OutreachEmailModel draft;
  final String leadName;
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(10),
        border: Border.all(color: EColors.primary.withAlpha(31)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
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
                  draft.subject,
                  style: const TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeLabel),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, size: 16, color: EColors.primary),
            tooltip: 'Send',
            onPressed: () => ctrl.sendEmail(draft.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            tooltip: 'Delete draft',
            onPressed: () => ctrl.deleteDraft(draft.id),
          ),
        ],
      ),
    );
  }
}
