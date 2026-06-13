part of 'admin_outreach_widget.dart';

class _OutreachHeader extends StatelessWidget {
  const _OutreachHeader({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.lg, ESizes.lg, 0),
      child: Row(
        children: [
          const Text(
            '// OUTREACH',
            style: TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: ESizes.lg),
          Obx(
            () => _SubTabPills(
              activeIndex: ctrl.activeSubTab.value,
              labels: const ['Pipeline', 'Drafts', 'Settings', 'Industries'],
              onTap: (i) => ctrl.activeSubTab.value = i,
            ),
          ),
          const Spacer(),
          Obx(() {
            if (ctrl.activeSubTab.value != 0) return const SizedBox.shrink();
            return _PipelineViewToggle(ctrl: ctrl);
          }),
          const SizedBox(width: ESizes.sm),
          Obx(() {
            if (ctrl.settings.value.lastDiscoveryAt == null) return const SizedBox.shrink();
            return _LastDiscoveryChip(ctrl: ctrl);
          }),
          const SizedBox(width: ESizes.sm),
          Obx(
            () => _FindLeadsButton(
              ctrl: ctrl,
              busy: ctrl.isDiscovering.value,
              blocked: !ctrl.canRunDiscovery,
              missingProfiles: ctrl.missingProfiles,
            ),
          ),
          const SizedBox(width: ESizes.sm),
          _AddLeadButton(ctrl: ctrl),
        ],
      ),
    );
  }
}

class _SubTabPills extends StatelessWidget {
  const _SubTabPills({required this.activeIndex, required this.labels, required this.onTap});
  final int activeIndex;
  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.only(right: ESizes.sm),
          child: GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? EColors.primary.withAlpha(26) : Colors.transparent,
                border: Border.all(
                  color: isActive ? EColors.primary : EColors.primary.withAlpha(51),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: isActive ? EColors.primary : EColors.primary.withAlpha(153),
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError, required this.onDismiss});

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.redAccent : EColors.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.sm, ESizes.lg, 0),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(77)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 14),
          const SizedBox(width: ESizes.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: ESizes.fontSizeLabel),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, color: color, size: 14),
          ),
        ],
      ),
    );
  }
}
