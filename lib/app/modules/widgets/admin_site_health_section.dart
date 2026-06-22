import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

part '_admin_site_health_widgets.dart';

class AdminSiteHealthSection extends StatefulWidget {
  const AdminSiteHealthSection({super.key, required this.quote, required this.ctrl});

  final Map<String, dynamic> quote;
  final AdminController ctrl;

  @override
  State<AdminSiteHealthSection> createState() => _AdminSiteHealthSectionState();
}

class _AdminSiteHealthSectionState extends State<AdminSiteHealthSection> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final quoteId = widget.quote['id'] as String;
    if (widget.ctrl.siteEvents[quoteId] == null) {
      widget.ctrl.fetchSiteEvents(quoteId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    final quoteId = quote['id'] as String;
    final uptimeStatus = quote['uptime_status'] as String? ?? 'unknown';
    final lastCheckRaw = quote['last_uptime_check_at'] as String?;
    final lastAuditRaw = quote['last_audited_at'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Text(
                '// SITE HEALTH',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSizeLabel,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: EColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: ESizes.sm),
          _HealthRow(
            label: 'Uptime',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UptimeDot(status: uptimeStatus),
                const SizedBox(width: 6),
                Text(
                  _uptimeLabel(uptimeStatus),
                  style: TextStyle(
                    color: _uptimeColor(uptimeStatus),
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lastCheckRaw != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· ${_relativeTime(lastCheckRaw)}',
                    style: const TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: ESizes.xs),
          _LighthouseScores(quote: quote),
          if (lastAuditRaw != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last audit: ${_relativeTime(lastAuditRaw)}',
                style: const TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            ),
          const SizedBox(height: ESizes.sm),
          Obx(() {
            final events = widget.ctrl.siteEvents[quoteId] ?? [];
            final loading = widget.ctrl.loadingSiteEvents.contains(quoteId);
            if (loading) {
              return const SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              );
            }
            if (events.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent events',
                  style: TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...events.map((e) => _EventRow(event: e)),
              ],
            );
          }),
        ],
      ],
    );
  }

  String _uptimeLabel(String status) => switch (status) {
    'up' => 'Up',
    'down' => 'Down',
    'degraded' => 'Degraded',
    _ => 'Unknown',
  };

  Color _uptimeColor(String status) => switch (status) {
    'up' => EColors.primary,
    'down' => const Color(0xFFFF4D4D),
    'degraded' => EColors.gold,
    _ => EColors.textSecondary,
  };

  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
