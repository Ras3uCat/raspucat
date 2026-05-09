import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/modules/widgets/portal_add_modules_view.dart';
import 'package:raspucat/app/modules/widgets/portal_dashboard.dart';
import 'package:raspucat/app/modules/widgets/portal_files_view.dart';
import 'package:raspucat/app/modules/widgets/portal_messages_view.dart';
import 'package:raspucat/app/modules/widgets/portal_stage_pill.dart';
import 'package:raspucat/utils/constants/exports.dart';

part '_portal_screen_nav.dart';

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
          final content = _PortalContent(ctrl: controller);
          return isDesktop
              ? _DesktopShell(tabs: _tabs, ctrl: controller)
              : _MobileShell(tabs: _tabs, ctrl: controller, content: content);
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
        Obx(
          () => NavigationRail(
            backgroundColor: EColors.backgroundDark,
            selectedIndex: ctrl.selectedTab.value,
            onDestinationSelected: (i) => ctrl.selectedTab.value = i,
            extended: false,
            minWidth: 72,
            indicatorColor: EColors.primary.withValues(alpha: 0.15),
            selectedIconTheme: const IconThemeData(color: EColors.primary, size: 22),
            unselectedIconTheme: IconThemeData(
              color: EColors.textSecondary.withValues(alpha: 0.4),
              size: 22,
            ),
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
                if (ctrl.quotes.length > 1) return _ProjectSwitcher(ctrl: ctrl);
                return PortalStagePill(quote: q);
              }),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: ESizes.lg),
              child: IconButton(
                icon: Icon(
                  Icons.logout,
                  color: EColors.textSecondary.withValues(alpha: 0.4),
                  size: 20,
                ),
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
              return NavigationRailDestination(icon: icon, label: Text(t.label));
            }).toList(),
          ),
        ),
        VerticalDivider(width: 1, color: EColors.primary.withValues(alpha: 0.1)),
        Expanded(
          child: Obx(() => _PortalContent(selectedTab: ctrl.selectedTab.value, ctrl: ctrl)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Content switcher
// ---------------------------------------------------------------------------

class _PortalContent extends StatelessWidget {
  const _PortalContent({required this.ctrl, this.selectedTab});
  final PortalController ctrl;
  final int? selectedTab;

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
        index: selectedTab ?? ctrl.selectedTab.value,
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
