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

part '_admin_dashboard_header.dart';

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
