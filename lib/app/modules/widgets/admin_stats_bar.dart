import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

class AdminStatsBar extends StatelessWidget {
  const AdminStatsBar({super.key, required this.ctrl});
  final AdminController ctrl;

  static String _fmtDollars(int? cents) {
    if (cents == null) return '—';
    final dollars = (cents / 100).round();
    final s = dollars.toString();
    if (s.length <= 3) return '\$$s';
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = ctrl.adminStats;
      final isEmpty = stats.isEmpty;

      final activeClients = isEmpty ? null : stats['active_clients'] as int?;
      final pendingCents =
          isEmpty ? null : stats['pending_balance_cents'] as int?;
      final mrrCents = isEmpty ? null : stats['mrr_cents'] as int?;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.xl,
          vertical: ESizes.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Active Clients',
                value: isEmpty ? '—' : '${activeClients ?? 0}',
              ),
            ),
            const SizedBox(width: ESizes.md),
            Expanded(
              child: _StatCard(
                label: 'Pending Balance',
                value: isEmpty ? '—' : _fmtDollars(pendingCents),
              ),
            ),
            const SizedBox(width: ESizes.md),
            Expanded(
              child: _StatCard(
                label: 'Est. MRR',
                value: isEmpty ? '—' : '${_fmtDollars(mrrCents)}/mo',
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm + 4,
      ),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSizeLabel,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                color: EColors.textWhite,
                fontSize: ESizes.fontSizeMd,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: EColors.primary.withValues(alpha: 0.7),
                    blurRadius: 8,
                  ),
                  Shadow(
                    color: EColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
