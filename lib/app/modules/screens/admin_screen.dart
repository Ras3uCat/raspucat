import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_row.dart';
import 'package:raspucat/app/modules/widgets/admin_filter_bar.dart';
import 'package:raspucat/app/modules/widgets/admin_stats_bar.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_detail_drawer.dart';
import 'package:raspucat/app/modules/widgets/admin_pipeline_view.dart';
import 'package:raspucat/app/modules/widgets/admin_login_gate.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_form.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminController());
    Get.put(AdminCatalogController());

    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: Obx(() => ctrl.isAuthenticated.value
          ? _Dashboard(ctrl: ctrl)
          : AdminLoginGate(ctrl: ctrl)),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ESizes.xl,
            vertical: ESizes.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: EColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              Obx(() {
                final count = ctrl.staleCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NeonText(
                      text: 'Quotes',
                      neonColor: EColors.primary,
                      isHeadline: false,
                      style: const TextStyle(
                        fontSize: ESizes.fontSizeLg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -10,
                        child: Tooltip(
                          message: 'Deposit paid over 7 days ago — consider charging the remaining balance or following up.',
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: EColors.gold,
                              borderRadius: BorderRadius.circular(
                                ESizes.borderRadiusXxl,
                              ),
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
                          ),
                        ),
                      ),
                  ],
                );
              }),
              const Spacer(),
              NeonButton(
                onTap: () => AdminQuoteFormModal.show(context, ctrl),
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md,
                  vertical: ESizes.sm,
                ),
                enableOverlay: false,
                child: const Icon(Icons.add, color: EColors.primary, size: 18),
              ),
              const SizedBox(width: ESizes.xs),
              NeonButton(
                onTap: ctrl.fetchQuotes,
                padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md,
                  vertical: ESizes.sm,
                ),
                enableOverlay: false,
                child: const Icon(Icons.refresh, color: EColors.primary, size: 18),
              ),
              Obx(() => IconButton(
                    icon: Icon(
                      ctrl.showPipeline.value
                          ? Icons.list
                          : Icons.view_column_outlined,
                      color: EColors.primary,
                      size: 20,
                    ),
                    tooltip: ctrl.showPipeline.value ? 'List view' : 'Pipeline view',
                    onPressed: () =>
                        ctrl.showPipeline.value = !ctrl.showPipeline.value,
                  )),
              TextButton(
                onPressed: ctrl.logout,
                child: Text(
                  'Logout',
                  style: TextStyle(color: EColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        // Stats bar
        AdminStatsBar(ctrl: ctrl),
        // Filter bar — hidden in pipeline mode
        Obx(() => ctrl.showPipeline.value ? const SizedBox.shrink() : AdminFilterBar(ctrl: ctrl)),
        // Content — list or pipeline
        Expanded(
          child: Obx(() {
            if (ctrl.showPipeline.value) {
              return AdminPipelineView(ctrl: ctrl);
            }
            if (ctrl.isLoadingQuotes.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: EColors.primary,
                  strokeWidth: 2,
                ),
              );
            }
            final filtered = ctrl.filteredQuotes;
            if (filtered.isEmpty) {
              return Center(
                child: Text(
                  ctrl.quotes.isEmpty
                      ? 'No quotes yet.'
                      : 'No quotes match the current filters.',
                  style: TextStyle(color: EColors.textSecondary),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(ESizes.lg),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: ESizes.sm),
              itemBuilder: (_, i) {
                final q = filtered[i];
                final id = q['id'] as String;
                return Obx(() => AdminQuoteRow(
                      quote: q,
                      state: ctrl.quoteState[id] ?? {},
                      ctrl: ctrl,
                      onTap: () =>
                          AdminQuoteDetailDrawer.show(context, ctrl, id),
                      onChargeBalance: () => ctrl.chargeBalance(id),
                      onStartSubscription: () => ctrl.startSubscription(id),
                      pendingModuleCount:
                          ctrl.pendingModuleCounts[id] ?? 0,
                      inProgressModuleCount:
                          ctrl.inProgressModuleCounts[id] ?? 0,
                      unreadMessageCount:
                          ctrl.unreadMessageCounts[id] ?? 0,
                      newFileCount:
                          ctrl.newFileCounts[id] ?? 0,
                    ));
              },
            );
          }),
        ),
      ],
    );
  }
}
