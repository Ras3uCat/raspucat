part of 'admin_outreach_widget.dart';

class _IndustryFilterBar extends StatelessWidget {
  const _IndustryFilterBar({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    final profiles = ctrl.industryProfiles;
    if (profiles.isEmpty) return const SizedBox.shrink();

    return Obx(() {
      final selected = ctrl.selectedIndustryFilter.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.sm, ESizes.lg, 0),
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              selected: selected == null,
              onTap: () => ctrl.selectedIndustryFilter.value = null,
            ),
            ...profiles.map(
              (p) => Padding(
                padding: const EdgeInsets.only(left: ESizes.xs),
                child: _FilterChip(
                  label: p.name,
                  selected: selected?.toLowerCase() == p.name.toLowerCase(),
                  onTap: () => ctrl.selectedIndustryFilter.value =
                      selected?.toLowerCase() == p.name.toLowerCase() ? null : p.name,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? EColors.primary.withAlpha(40) : Colors.transparent,
          border: Border.all(
            color: selected ? EColors.primary : EColors.primary.withAlpha(50),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? EColors.primary : EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
