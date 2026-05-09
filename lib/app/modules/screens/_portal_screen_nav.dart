part of 'portal_screen.dart';

// ---------------------------------------------------------------------------
// Tab definition
// ---------------------------------------------------------------------------

class _TabDef {
  const _TabDef({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ---------------------------------------------------------------------------
// Mobile shell — content + bottom NavigationBar
// ---------------------------------------------------------------------------

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.tabs, required this.ctrl, required this.content});
  final List<_TabDef> tabs;
  final PortalController ctrl;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: EColors.backgroundDark,
        body: content,
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
            Widget baseIcon = Icon(t.icon, color: EColors.textSecondary.withValues(alpha: 0.4));
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
      ),
    );
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
                    color: isActive ? EColors.primary : EColors.primary.withValues(alpha: 0.2),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    e.value.businessName.isNotEmpty ? e.value.businessName[0].toUpperCase() : '?',
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
          Icon(
            Icons.signal_wifi_statusbar_connected_no_internet_4_outlined,
            color: EColors.textSecondary.withValues(alpha: 0.3),
            size: 48,
          ),
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
            child: const Text('Retry', style: TextStyle(color: EColors.primary)),
          ),
        ],
      ),
    );
  }
}
