import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_app_projects_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_app_project_card.dart';
import 'package:raspucat/app/modules/widgets/admin_app_project_form.dart';

class AdminAppProjectsView extends StatelessWidget {
  const AdminAppProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminAppProjectsController>();

    return Column(
      children: [
        _ViewHeader(ctrl: ctrl),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
              );
            }

            if (ctrl.error.value != null) {
              return _ErrorState(message: ctrl.error.value!, onRetry: ctrl.fetchAll);
            }

            if (ctrl.projects.isEmpty) {
              return _EmptyState(onAdd: () => AdminAppProjectFormModal.show(context));
            }

            return _ProjectGrid(ctrl: ctrl);
          }),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ViewHeader extends StatelessWidget {
  const _ViewHeader({required this.ctrl});

  final AdminAppProjectsController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          const Text(
            '// App Projects',
            style: TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSizeSm,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          NeonButton(
            onTap: () => AdminAppProjectFormModal.show(context),
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            enableOverlay: false,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: EColors.primary, size: ESizes.iconSm),
                SizedBox(width: ESizes.xs),
                Text(
                  'Add Project',
                  style: TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeSm),
                ),
              ],
            ),
          ),
          const SizedBox(width: ESizes.xs),
          NeonButton(
            onTap: ctrl.fetchAll,
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            enableOverlay: false,
            child: const Icon(Icons.refresh, color: EColors.primary, size: ESizes.iconSm),
          ),
        ],
      ),
    );
  }
}

// ─── Grid ────────────────────────────────────────────────────────────────────

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({required this.ctrl});

  final AdminAppProjectsController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Wrap(
        spacing: ESizes.md,
        runSpacing: ESizes.md,
        children: ctrl.projects.map((project) {
          return AdminAppProjectCard(
            project: project,
            onEdit: () => AdminAppProjectFormModal.show(context, initial: project),
            onDelete: () => showDialog<void>(
              context: context,
              builder: (_) => _DeleteConfirmDialog(
                name: project.name,
                onConfirm: () => ctrl.deleteProject(project.id),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rocket_launch_outlined, size: ESizes.iconLg, color: EColors.textSecondary),
          const SizedBox(height: ESizes.md),
          Text(
            'No app projects yet.',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
          ),
          const SizedBox(height: ESizes.md),
          NeonButton(
            onTap: onAdd,
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            enableOverlay: false,
            child: const Text(
              'Add Project',
              style: TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeSm),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: ESizes.iconLg, color: EColors.error),
          const SizedBox(height: ESizes.md),
          Text(
            message,
            style: const TextStyle(color: EColors.error, fontSize: ESizes.fontSizeSm),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESizes.md),
          NeonButton(
            onTap: onRetry,
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            enableOverlay: false,
            child: const Text(
              'Retry',
              style: TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeSm),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delete confirm ──────────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.name, required this.onConfirm});

  final String name;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EColors.circuitSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.cardRadiusMd),
        side: BorderSide(color: EColors.error.withValues(alpha: 0.3)),
      ),
      title: const Text(
        'Delete Project?',
        style: TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeMd),
      ),
      content: Text(
        'This will permanently delete "$name". This cannot be undone.',
        style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: EColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Delete', style: TextStyle(color: EColors.error)),
        ),
      ],
    );
  }
}
