import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/utils/constants/exports.dart';

// Plan card and module chips — private to portal_dashboard.

class PortalDashboardPlanCard extends StatelessWidget {
  const PortalDashboardPlanCard({required this.quote});
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
              const Icon(Icons.layers_outlined, color: EColors.primary, size: 18),
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

  static String _formatDate(DateTime d) => '${_month(d.month)} ${d.day}, ${d.year}';
  static String _month(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

class _ModuleIdChips extends StatelessWidget {
  const _ModuleIdChips({required this.moduleIds});
  final List<String> moduleIds;

  static const int _maxVisible = 4;

  static String _humanize(String id) {
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (uuidPattern.hasMatch(id)) return id.substring(0, 8).toUpperCase();
    final words = id.split(RegExp(r'[-_]'));
    final titled = words
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
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
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.xs),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: muted ? 0.03 : 0.06),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: EColors.primary.withValues(alpha: muted ? 0.1 : 0.18)),
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
