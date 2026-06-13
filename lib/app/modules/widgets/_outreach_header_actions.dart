part of 'admin_outreach_widget.dart';

class _AddLeadButton extends StatelessWidget {
  const _AddLeadButton({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLeadFormDialog(context, ctrl, null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 8),
        decoration: BoxDecoration(
          color: EColors.primary.withAlpha(20),
          border: Border.all(color: EColors.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: EColors.primary, size: 14),
            SizedBox(width: 6),
            Text(
              'Add Lead',
              style: TextStyle(
                color: EColors.primary,
                fontSize: ESizes.fontSizeLabel,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindLeadsButton extends StatelessWidget {
  const _FindLeadsButton({
    required this.ctrl,
    required this.busy,
    required this.blocked,
    required this.missingProfiles,
  });
  final AdminOutreachController ctrl;
  final bool busy;
  final bool blocked;
  final List<String> missingProfiles;

  @override
  Widget build(BuildContext context) {
    final disabled = busy || blocked;
    return Tooltip(
      message: blocked ? 'Run /industry-download first for: ${missingProfiles.join(', ')}' : '',
      child: GestureDetector(
        onTap: disabled ? null : ctrl.runDiscovery,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 8),
          decoration: BoxDecoration(
            color: EColors.primary.withAlpha(disabled ? 10 : 20),
            border: Border.all(color: EColors.primary.withAlpha(disabled ? 51 : 255)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
                )
              else
                Icon(
                  blocked ? Icons.block : Icons.travel_explore,
                  color: EColors.primary.withAlpha(disabled ? 77 : 255),
                  size: 14,
                ),
              const SizedBox(width: 6),
              Text(
                busy ? 'Searching...' : 'Find Leads',
                style: TextStyle(
                  color: EColors.primary.withAlpha(disabled ? 77 : 255),
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastDiscoveryChip extends StatelessWidget {
  const _LastDiscoveryChip({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = ctrl.settings.value;
    if (s.lastDiscoveryAt == null) return const SizedBox.shrink();
    final diff = DateTime.now().difference(s.lastDiscoveryAt!);
    final when = diff.inDays > 0
        ? '${diff.inDays}d ago'
        : diff.inHours > 0
        ? '${diff.inHours}h ago'
        : 'just now';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
      decoration: BoxDecoration(
        color: EColors.primary.withAlpha(10),
        border: Border.all(color: EColors.primary.withAlpha(38)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Last run: ${s.lastDiscoveryCount} leads · $when',
        style: TextStyle(color: EColors.primary.withAlpha(153), fontSize: ESizes.fontSizeLabel),
      ),
    );
  }
}

class _PipelineViewToggle extends StatelessWidget {
  const _PipelineViewToggle({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isKanban = ctrl.pipelineViewMode.value == 1;
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: EColors.primary.withAlpha(51)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleSegment(
              icon: Icons.view_list_outlined,
              active: !isKanban,
              tooltip: 'List view',
              onTap: () => ctrl.pipelineViewMode.value = 0,
              isFirst: true,
            ),
            _ToggleSegment(
              icon: Icons.view_column_outlined,
              active: isKanban,
              tooltip: 'Kanban view',
              onTap: () => ctrl.pipelineViewMode.value = 1,
              isFirst: false,
            ),
          ],
        ),
      );
    });
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
    required this.isFirst,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: active ? EColors.primary.withAlpha(26) : Colors.transparent,
            border: Border(
              right: isFirst ? BorderSide(color: EColors.primary.withAlpha(51)) : BorderSide.none,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: active ? EColors.primary : EColors.primary.withAlpha(102),
          ),
        ),
      ),
    );
  }
}
