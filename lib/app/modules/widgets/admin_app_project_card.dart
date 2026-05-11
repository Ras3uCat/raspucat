import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/modules/widgets/_admin_app_project_card_parts.dart';

class AdminAppProjectCard extends StatelessWidget {
  const AdminAppProjectCard({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onDelete,
  });

  final AppProject project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: EColors.circuitSlate,
        borderRadius: BorderRadius.circular(ESizes.cardRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(project: project, onEdit: onEdit, onDelete: onDelete),
          AdminAppProjectCardBody(project: project),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.project, required this.onEdit, required this.onDelete});

  final AppProject project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          AppProjectStatusDot(status: project.status),
          const SizedBox(width: ESizes.xs),
          Expanded(
            child: Text(
              project.name,
              style: const TextStyle(
                color: EColors.cyanTintedWhite,
                fontSize: ESizes.fontSizeMd,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ESizes.xs),
          AppProjectStatusBadge(status: project.status),
          const SizedBox(width: ESizes.xs),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: ESizes.iconSm),
            color: EColors.textSecondary,
            tooltip: 'Edit',
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: ESizes.xs),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: ESizes.iconSm),
            color: EColors.error,
            tooltip: 'Delete',
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
