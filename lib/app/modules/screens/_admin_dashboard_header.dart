part of 'admin_screen.dart';

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.ctrl,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final AdminController ctrl;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  static const double _mobileBreak = 640;

  Widget _staleBadge() => Obx(() {
    final count = ctrl.staleCount;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: ESizes.md),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.xs, vertical: 2),
      decoration: BoxDecoration(
        color: EColors.gold,
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXxl),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: EColors.textWhite,
          fontSize: ESizes.fontSizeLabel,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  });

  List<Widget> _actionButtons(BuildContext context) => [
    if (selectedTab == 0) ...[
      NeonButton(
        onTap: () => AdminQuoteFormModal.show(context, ctrl),
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        enableOverlay: false,
        child: const Icon(Icons.add, color: EColors.primary, size: 18),
      ),
      const SizedBox(width: ESizes.xs),
      NeonButton(
        onTap: ctrl.fetchQuotes,
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        enableOverlay: false,
        child: const Icon(Icons.refresh, color: EColors.primary, size: 18),
      ),
      Obx(
        () => IconButton(
          icon: Icon(
            ctrl.showPipeline.value ? Icons.list : Icons.view_column_outlined,
            color: EColors.primary,
            size: 20,
          ),
          tooltip: ctrl.showPipeline.value ? 'List view' : 'Pipeline view',
          onPressed: () => ctrl.showPipeline.value = !ctrl.showPipeline.value,
        ),
      ),
    ] else if (selectedTab == 1) ...[
      NeonButton(
        onTap: Get.find<AdminAppProjectsController>().fetchAll,
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        enableOverlay: false,
        child: const Icon(Icons.refresh, color: EColors.primary, size: 18),
      ),
    ] else if (selectedTab == 2) ...[
      NeonButton(
        onTap: Get.find<AdminAvailabilityController>().loadAvailability,
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        enableOverlay: false,
        child: const Icon(Icons.refresh, color: EColors.primary, size: 18),
      ),
    ] else ...[
      NeonButton(
        onTap: Get.find<AdminOutreachController>().loadSettings,
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        enableOverlay: false,
        child: const Icon(Icons.refresh, color: EColors.primary, size: 18),
      ),
    ],
    TextButton(
      onPressed: ctrl.logout,
      child: Text('Logout', style: TextStyle(color: EColors.textSecondary)),
    ),
  ];

  Widget _tabRow() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _TabButton(
          label: 'Client Projects',
          selected: selectedTab == 0,
          onTap: () => onTabChanged(0),
          badge: _staleBadge(),
        ),
        const SizedBox(width: ESizes.md),
        _TabButton(label: 'App Projects', selected: selectedTab == 1, onTap: () => onTabChanged(1)),
        const SizedBox(width: ESizes.md),
        _TabButton(label: 'Availability', selected: selectedTab == 2, onTap: () => onTabChanged(2)),
        const SizedBox(width: ESizes.md),
        _TabButton(label: 'Outreach', selected: selectedTab == 3, onTap: () => onTabChanged(3)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreak;
        final hPad = isMobile ? ESizes.md : ESizes.xl;

        if (isMobile) {
          return Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.15))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: ESizes.sm),
                  child: _tabRow(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, ESizes.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _actionButtons(context),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: ESizes.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.15))),
          ),
          child: Row(
            children: [
              _TabButton(
                label: 'Client Projects',
                selected: selectedTab == 0,
                onTap: () => onTabChanged(0),
                badge: _staleBadge(),
              ),
              const SizedBox(width: ESizes.md),
              _TabButton(
                label: 'App Projects',
                selected: selectedTab == 1,
                onTap: () => onTabChanged(1),
              ),
              const SizedBox(width: ESizes.md),
              _TabButton(
                label: 'Availability',
                selected: selectedTab == 2,
                onTap: () => onTabChanged(2),
              ),
              const SizedBox(width: ESizes.md),
              _TabButton(
                label: 'Outreach',
                selected: selectedTab == 3,
                onTap: () => onTabChanged(3),
              ),
              const Spacer(),
              ..._actionButtons(context),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap, this.badge});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? EColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: NeonText(
              text: label,
              neonColor: selected ? EColors.primary : EColors.textSecondary,
              isHeadline: false,
              style: TextStyle(
                fontSize: ESizes.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: selected ? EColors.primary : EColors.textSecondary,
              ),
            ),
          ),
          if (badge != null) Positioned(top: -4, right: -10, child: badge!),
        ],
      ),
    );
  }
}
