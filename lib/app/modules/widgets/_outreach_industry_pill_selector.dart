part of 'admin_outreach_widget.dart';

class _IndustryPillSelector extends StatelessWidget {
  const _IndustryPillSelector({required this.selected, required this.ctrl, required this.onToggle});

  final List<String> selected;
  final AdminOutreachController ctrl;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TARGET INDUSTRIES',
          style: TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Obx(() {
          final profiles = ctrl.industryProfiles;
          if (profiles.isEmpty) {
            return Text(
              'No industry profiles yet — run an industry-download first',
              style: TextStyle(
                color: EColors.softGrey.withAlpha(128),
                fontSize: ESizes.fontSizeLabel,
              ),
            );
          }
          return Wrap(
            spacing: ESizes.sm,
            runSpacing: ESizes.sm,
            children: profiles.map((profile) {
              final isSelected = selected.contains(profile.name);
              return GestureDetector(
                onTap: () => onToggle(profile.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? EColors.primary.withAlpha(51) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? EColors.primary : EColors.softGrey.withAlpha(77),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, size: 11, color: EColors.primary),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        profile.name,
                        style: TextStyle(
                          color: isSelected ? EColors.primary : EColors.softGrey,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
