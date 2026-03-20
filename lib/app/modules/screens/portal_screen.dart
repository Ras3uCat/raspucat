import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/modules/widgets/portal_add_modules_view.dart';
import 'package:raspucat/app/modules/widgets/portal_dashboard.dart';
import 'package:raspucat/app/modules/widgets/portal_files_view.dart';
import 'package:raspucat/app/modules/widgets/portal_messages_view.dart';
import 'package:raspucat/app/modules/widgets/portal_stage_pill.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalScreen extends GetView<PortalController> {
  const PortalScreen({super.key});

  static const _tabs = [
    _TabDef(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _TabDef(icon: Icons.chat_bubble_outline, label: 'Messages'),
    _TabDef(icon: Icons.folder_outlined, label: 'Files'),
    _TabDef(icon: Icons.add_circle_outline, label: 'Add Modules'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return isDesktop
              ? _DesktopShell(tabs: _tabs, ctrl: controller)
              : _MobileShell(tabs: _tabs, ctrl: controller);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop shell — NavigationRail + content
// ---------------------------------------------------------------------------

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.tabs, required this.ctrl});
  final List<_TabDef> tabs;
  final PortalController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx(() => NavigationRail(
              backgroundColor: EColors.backgroundDark,
              selectedIndex: ctrl.selectedTab.value,
              onDestinationSelected: (i) => ctrl.selectedTab.value = i,
              extended: false,
              minWidth: 72,
              indicatorColor: EColors.primary.withValues(alpha: 0.15),
              selectedIconTheme:
                  const IconThemeData(color: EColors.primary, size: 22),
              unselectedIconTheme: IconThemeData(
                  color: EColors.textSecondary.withValues(alpha: 0.4), size: 22),
              selectedLabelTextStyle: const TextStyle(
                color: EColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.4),
                fontSize: 11,
              ),
              leading: Padding(
                padding: const EdgeInsets.only(top: ESizes.lg, bottom: ESizes.xl),
                child: Obx(() {
                  final q = ctrl.activeQuote;
                  if (q == null) return const SizedBox.shrink();
                  if (ctrl.quotes.length > 1) {
                    return _ProjectSwitcher(ctrl: ctrl);
                  }
                  return PortalStagePill(quote: q);
                }),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: ESizes.lg),
                child: IconButton(
                  icon: Icon(Icons.logout,
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      size: 20),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign out?'),
                        content: const Text(
                          'You\'ll need to enter your email address to receive a new magic link to log back in.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) ctrl.signOut();
                  },
                ),
              ),
              destinations: tabs.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final msgBadge = i == 1 && ctrl.unreadMessageCount.value > 0;
                final fileBadge = i == 2 && ctrl.unreadFileCount.value > 0;
                Widget icon = Icon(t.icon);
                if (msgBadge) {
                  icon = Badge(
                    backgroundColor: EColors.primary,
                    label: Text('${ctrl.unreadMessageCount.value}'),
                    child: icon,
                  );
                } else if (fileBadge) {
                  icon = Badge(
                    backgroundColor: EColors.primary,
                    label: Text('${ctrl.unreadFileCount.value}'),
                    child: icon,
                  );
                }
                return NavigationRailDestination(
                  icon: icon,
                  label: Text(t.label),
                );
              }).toList(),
            )),
        VerticalDivider(
          width: 1,
          color: EColors.primary.withValues(alpha: 0.1),
        ),
        Expanded(
          child: Obx(() => _PortalContent(
                selectedTab: ctrl.selectedTab.value,
                ctrl: ctrl,
              )),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile shell — content + bottom NavigationBar
// ---------------------------------------------------------------------------

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.tabs, required this.ctrl});
  final List<_TabDef> tabs;
  final PortalController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: EColors.backgroundDark,
          body: _PortalContent(
            selectedTab: ctrl.selectedTab.value,
            ctrl: ctrl,
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: EColors.backgroundDark,
            indicatorColor: EColors.primary.withValues(alpha: 0.15),
            selectedIndex: ctrl.selectedTab.value,
            onDestinationSelected: (i) => ctrl.selectedTab.value = i,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: tabs.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final msgBadge = i == 1 && ctrl.unreadMessageCount.value > 0;
                final fileBadge = i == 2 && ctrl.unreadFileCount.value > 0;
                Widget baseIcon = Icon(t.icon,
                    color: EColors.textSecondary.withValues(alpha: 0.4));
                if (msgBadge) {
                  baseIcon = Badge(
                    backgroundColor: EColors.primary,
                    label: Text('${ctrl.unreadMessageCount.value}'),
                    child: baseIcon,
                  );
                } else if (fileBadge) {
                  baseIcon = Badge(
                    backgroundColor: EColors.primary,
                    label: Text('${ctrl.unreadFileCount.value}'),
                    child: baseIcon,
                  );
                }
                return NavigationDestination(
                  icon: baseIcon,
                  selectedIcon: Icon(t.icon, color: EColors.primary),
                  label: t.label,
                );
              }).toList(),
          ),
        ));
  }
}

// ---------------------------------------------------------------------------
// Project switcher (shown in nav rail when multiple quotes)
// ---------------------------------------------------------------------------

class _ProjectSwitcher extends StatelessWidget {
  const _ProjectSwitcher({required this.ctrl});
  final PortalController ctrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ctrl.quotes.asMap().entries.map((e) {
          final isActive = e.key == ctrl.activeQuoteIndex.value;
          return Tooltip(
            message: e.value.businessName,
            preferBelow: false,
            child: GestureDetector(
              onTap: () => ctrl.selectQuote(e.key),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? EColors.primary.withValues(alpha: 0.15)
                      : EColors.primary.withValues(alpha: 0.04),
                  border: Border.all(
                    color: isActive
                        ? EColors.primary
                        : EColors.primary.withValues(alpha: 0.2),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    e.value.businessName.isNotEmpty
                        ? e.value.businessName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isActive
                          ? EColors.primary
                          : EColors.textSecondary.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content switcher
// ---------------------------------------------------------------------------

class _PortalContent extends StatelessWidget {
  const _PortalContent({required this.selectedTab, required this.ctrl});
  final int selectedTab;
  final PortalController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
        );
      }
      if (ctrl.hasError.value || ctrl.activeQuote == null) {
        return _PortalErrorState(onRetry: ctrl.refresh);
      }

      return IndexedStack(
        index: selectedTab,
        children: [
          const PortalDashboard(),
          PortalMessagesView(quoteId: ctrl.activeQuote!.id),
          PortalFilesView(quoteId: ctrl.activeQuote!.id),
          const PortalAddModulesView(),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _PortalErrorState extends StatelessWidget {
  const _PortalErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_outlined,
              color: EColors.textSecondary.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: ESizes.md),
          Text(
            'Signal lost.',
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.5),
              fontSize: ESizes.fontSizeMd,
            ),
          ),
          const SizedBox(height: ESizes.md),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: EColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab definition
// ---------------------------------------------------------------------------

class _TabDef {
  const _TabDef({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
