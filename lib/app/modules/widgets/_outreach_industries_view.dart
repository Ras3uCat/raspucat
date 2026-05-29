part of 'admin_outreach_widget.dart';

class _OutreachIndustriesView extends StatelessWidget {
  const _OutreachIndustriesView({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.industryProfiles.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(ESizes.xl),
            child: Text(
              'No industry profiles yet. Run /industry-setup in Claude Code to research an industry.',
              style: TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeLabel),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(ESizes.lg),
        itemCount: ctrl.industryProfiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: ESizes.sm),
        itemBuilder: (_, i) => _IndustryCard(profile: ctrl.industryProfiles[i]),
      );
    });
  }
}
