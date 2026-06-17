import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';
import 'package:raspucat/app/controllers/admin_app_projects_controller.dart';
import 'package:raspucat/app/controllers/admin_availability_controller.dart';
import 'package:raspucat/app/controllers/admin_outreach_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_row.dart';
import 'package:raspucat/app/modules/widgets/admin_filter_bar.dart';
import 'package:raspucat/app/modules/widgets/admin_stats_bar.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_detail_drawer.dart';
import 'package:raspucat/app/modules/widgets/admin_pipeline_view.dart';
import 'package:raspucat/app/modules/widgets/admin_login_gate.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_form.dart';
import 'package:raspucat/app/modules/widgets/admin_app_projects_view.dart';
import 'package:raspucat/app/modules/widgets/admin_availability_widget.dart';
import 'package:raspucat/app/modules/widgets/admin_outreach_widget.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminController());
    Get.put(AdminCatalogController());
    Get.put(AdminAppProjectsController());

    Get.put(AdminAvailabilityController());
    Get.put(AdminOutreachController());
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: Obx(
        () => ctrl.isAuthenticated.value ? _Dashboard(ctrl: ctrl) : AdminLoginGate(ctrl: ctrl),
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.ctrl});
  final AdminController ctrl;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DashboardHeader(
          ctrl: widget.ctrl,
          selectedTab: _tab,
          onTabChanged: (t) => setState(() => _tab = t),
        ),
        if (_tab == 0) ...[
          AdminStatsBar(ctrl: widget.ctrl),
          Obx(
            () => widget.ctrl.showPipeline.value
                ? const SizedBox.shrink()
                : AdminFilterBar(ctrl: widget.ctrl),
          ),
          Expanded(child: _QuoteContent(ctrl: widget.ctrl)),
        ] else if (_tab == 1)
          const Expanded(child: AdminAppProjectsView())
        else if (_tab == 2)
          const Expanded(child: AdminAvailabilityWidget())
        else
          const Expanded(child: AdminOutreachWidget()),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.ctrl,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final AdminController ctrl;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.xl, vertical: ESizes.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Client Projects',
            selected: selectedTab == 0,
            onTap: () => onTabChanged(0),
            badge: Obx(() {
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
            }),
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
          _TabButton(label: 'Outreach', selected: selectedTab == 3, onTap: () => onTabChanged(3)),
          const Spacer(),
          if (selectedTab == 0) ...[
            // quote action buttons
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
            const SizedBox(width: ESizes.xs),
          ] else if (selectedTab == 2) ...[
            NeonButton(
              onTap: Get.find<AdminAvailabilityController>().loadAvailability,
              padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
              enableOverlay: false,
              child: const Icon(Icons.refresh, color: EColors.primary, size: 18),
            ),
            const SizedBox(width: ESizes.xs),
          ] else ...[
            NeonButton(
              onTap: Get.find<AdminOutreachController>().loadSettings,
              padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
              enableOverlay: false,
              child: const Icon(Icons.refresh, color: EColors.primary, size: 18),
            ),
            const SizedBox(width: ESizes.xs),
          ],
          TextButton(
            onPressed: ctrl.logout,
            child: Text('Logout', style: TextStyle(color: EColors.textSecondary)),
          ),
        ],
      ),
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

// ─── Quote content ────────────────────────────────────────────────────────────

class _QuoteContent extends StatelessWidget {
  const _QuoteContent({required this.ctrl});

  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.showPipeline.value) {
        return AdminPipelineView(ctrl: ctrl);
      }
      if (ctrl.isLoadingQuotes.value) {
        return const Center(
          child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
        );
      }
      final filtered = ctrl.filteredQuotes;
      if (filtered.isEmpty) {
        return Center(
          child: Text(
            ctrl.quotes.isEmpty ? 'No quotes yet.' : 'No quotes match the current filters.',
            style: TextStyle(color: EColors.textSecondary),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(ESizes.lg),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: ESizes.sm),
        itemBuilder: (_, i) {
          final q = filtered[i];
          final id = q['id'] as String;
          return Obx(
            () => AdminQuoteRow(
              quote: q,
              state: ctrl.quoteState[id] ?? {},
              ctrl: ctrl,
              onTap: () => AdminQuoteDetailDrawer.show(context, ctrl, id),
              onChargeBalance: () => ctrl.chargeBalance(id),
              onStartSubscription: () => ctrl.startSubscription(id),
              pendingModuleCount: ctrl.pendingModuleCounts[id] ?? 0,
              inProgressModuleCount: ctrl.inProgressModuleCounts[id] ?? 0,
              unreadMessageCount: ctrl.unreadMessageCounts[id] ?? 0,
              newFileCount: ctrl.newFileCounts[id] ?? 0,
            ),
          );
        },
      );
    });
  }
}
