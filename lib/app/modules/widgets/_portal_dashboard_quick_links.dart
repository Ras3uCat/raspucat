import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';

// Quick links grid — private to portal_dashboard.

class PortalDashboardQuickLinksGrid extends StatelessWidget {
  const PortalDashboardQuickLinksGrid({required this.ctrl});
  final PortalController ctrl;

  static const _links = [
    _QuickLink(
      tab: 1,
      icon: Icons.chat_bubble_outline,
      label: 'Messages',
      sub: 'Send a message to the team',
      unreadNoun: 'message',
    ),
    _QuickLink(
      tab: 2,
      icon: Icons.folder_outlined,
      label: 'Files',
      sub: 'Upload assets or download deliverables',
      unreadNoun: 'file',
    ),
    _QuickLink(
      tab: 3,
      icon: Icons.add_circle_outline,
      label: 'Add Modules',
      sub: 'Expand your project',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadMsgs = ctrl.unreadMessageCount.value;
      final unreadFiles = ctrl.unreadFileCount.value;
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: ESizes.md,
        mainAxisSpacing: ESizes.md,
        childAspectRatio: 2.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _links
            .map(
              (l) => _QuickLinkCard(
                link: l,
                unreadCount: l.tab == 1 ? unreadMsgs : (l.tab == 2 ? unreadFiles : 0),
                onTap: () => ctrl.selectedTab.value = l.tab,
              ),
            )
            .toList(),
      );
    });
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({required this.link, required this.onTap, this.unreadCount = 0});
  final _QuickLink link;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
          decoration: BoxDecoration(
            color: hasUnread
                ? EColors.primary.withValues(alpha: 0.07)
                : EColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(
              color: hasUnread
                  ? EColors.primary.withValues(alpha: 0.35)
                  : EColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(link.icon, color: EColors.primary.withValues(alpha: 0.7), size: 20),
                  if (hasUnread)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: EColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: ESizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      link.label,
                      style: const TextStyle(
                        color: EColors.textWhite,
                        fontSize: ESizes.fontSizeSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasUnread
                          ? '$unreadCount new ${link.unreadNoun}${unreadCount == 1 ? '' : 's'}'
                          : link.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread
                            ? EColors.primary.withValues(alpha: 0.7)
                            : EColors.textSecondary.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: EColors.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink({
    required this.tab,
    required this.icon,
    required this.label,
    required this.sub,
    this.unreadNoun = 'notification',
  });
  final int tab;
  final IconData icon;
  final String label;
  final String sub;
  final String unreadNoun;
}
