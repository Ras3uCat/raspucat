import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/app/modules/widgets/portal_manage_billing_button.dart';
import 'package:raspucat/app/modules/widgets/portal_stage_pill.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalDashboard extends StatelessWidget {
  const PortalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PortalController>();
    return Obx(() {
      final quote = ctrl.activeQuote;
      if (quote == null) return const SizedBox.shrink();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(ESizes.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(businessName: quote.businessName, ctrl: ctrl),
              const SizedBox(height: ESizes.xl),
              PortalStagePill(quote: quote, large: true),
              const SizedBox(height: ESizes.xl),
              _StatsRow(quote: quote),
              if (quote.subscriptionStartedAt != null || quote.status == 'deposit_paid') ...[
                const SizedBox(height: ESizes.md),
                PortalManageBillingButton(ctrl: ctrl),
              ],
              const SizedBox(height: ESizes.xl),
              _SectionLabel('Quick Access'),
              const SizedBox(height: ESizes.md),
              _QuickLinksGrid(ctrl: ctrl),
              const SizedBox(height: ESizes.xl),
              _SectionLabel('Plan Summary'),
              const SizedBox(height: ESizes.md),
              _PlanCard(quote: quote),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.businessName, required this.ctrl});
  final String businessName;
  final PortalController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.5),
            fontSize: ESizes.fontSizeSm,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        NeonText(
          text: businessName,
          neonColor: EColors.primary,
          isHeadline: false,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.quote});
  final PortalQuote quote;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Project Total',
            value: quote.formattedSetupTotal,
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: ESizes.md),
        Expanded(
          child: _StatCard(
            label: 'Plan',
            value: quote.planLabel,
            icon: Icons.layers_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EColors.primary.withValues(alpha: 0.6), size: 18),
          const SizedBox(height: ESizes.sm),
          Text(
            value,
            style: const TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeMd,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.45),
              fontSize: ESizes.fontSizeLabel,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick links grid
// ---------------------------------------------------------------------------

class _QuickLinksGrid extends StatelessWidget {
  const _QuickLinksGrid({required this.ctrl});
  final PortalController ctrl;

  static const _links = [
    _QuickLink(tab: 1, icon: Icons.chat_bubble_outline, label: 'Messages',
        sub: 'Send a message to the team', unreadNoun: 'message'),
    _QuickLink(tab: 2, icon: Icons.folder_outlined, label: 'Files',
        sub: 'Upload assets or download deliverables', unreadNoun: 'file'),
    _QuickLink(tab: 3, icon: Icons.add_circle_outline, label: 'Add Modules',
        sub: 'Expand your project'),
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
        children: _links.map((l) => _QuickLinkCard(
              link: l,
              unreadCount: l.tab == 1 ? unreadMsgs : (l.tab == 2 ? unreadFiles : 0),
              onTap: () => ctrl.selectedTab.value = l.tab,
            )).toList(),
      );
    });
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard(
      {required this.link, required this.onTap, this.unreadCount = 0});
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
        padding: const EdgeInsets.symmetric(
            horizontal: ESizes.md, vertical: ESizes.sm),
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
                Icon(link.icon,
                    color: EColors.primary.withValues(alpha: 0.7), size: 20),
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
                  Text(link.label,
                      style: const TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeSm,
                          fontWeight: FontWeight.w600)),
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
                          fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 12,
                color: EColors.primary.withValues(alpha: 0.4)),
          ],
        ),
      ),
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink(
      {required this.tab,
      required this.icon,
      required this.label,
      required this.sub,
      this.unreadNoun = 'notification'});
  final int tab;
  final IconData icon;
  final String label;
  final String sub;
  final String unreadNoun;
}

// ---------------------------------------------------------------------------
// Plan card
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.quote});
  final PortalQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined,
                  color: EColors.primary, size: 18),
              const SizedBox(width: ESizes.sm),
              Text(
                quote.planLabel,
                style: const TextStyle(
                  color: EColors.textWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: ESizes.fontSizeMd,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESizes.sm),
          Text(
            '${quote.moduleIds.length} module${quote.moduleIds.length == 1 ? '' : 's'} included',
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.5),
              fontSize: ESizes.fontSizeSm,
            ),
          ),
          if (quote.moduleIds.isNotEmpty) ...[
            const SizedBox(height: ESizes.sm),
            _ModuleIdChips(moduleIds: quote.moduleIds),
          ],
          const SizedBox(height: ESizes.xs),
          Text(
            'Signed ${_formatDate(quote.createdAt)}',
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.35),
              fontSize: ESizes.fontSizeLabel,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${_month(d.month)} ${d.day}, ${d.year}';

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ---------------------------------------------------------------------------
// Module ID chips
// ---------------------------------------------------------------------------

class _ModuleIdChips extends StatelessWidget {
  const _ModuleIdChips({required this.moduleIds});
  final List<String> moduleIds;

  static const int _maxVisible = 4;

  static String _humanize(String id) {
    // If it looks like a UUID (contains only hex + hyphens, length ~36), truncate
    final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false);
    if (uuidPattern.hasMatch(id)) {
      return id.substring(0, 8).toUpperCase();
    }
    // Slug-style: replace hyphens/underscores with spaces and title-case
    final words = id.split(RegExp(r'[-_]'));
    final titled = words.map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
    if (titled.length > 20) return '${titled.substring(0, 20)}…';
    return titled;
  }

  @override
  Widget build(BuildContext context) {
    final visible = moduleIds.take(_maxVisible).toList();
    final overflow = moduleIds.length - _maxVisible;
    return Wrap(
      spacing: ESizes.xs,
      runSpacing: ESizes.xs,
      children: [
        ...visible.map((id) => _ModuleChip(label: _humanize(id))),
        if (overflow > 0) _ModuleChip(label: '+$overflow more', muted: true),
      ],
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({required this.label, this.muted = false});
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.sm,
        vertical: ESizes.xs,
      ),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: muted ? 0.03 : 0.06),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(
          color: EColors.primary.withValues(alpha: muted ? 0.1 : 0.18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted
              ? EColors.textSecondary.withValues(alpha: 0.4)
              : EColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: EColors.textSecondary.withValues(alpha: 0.4),
        fontSize: ESizes.fontSizeLabel,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}
