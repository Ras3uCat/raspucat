import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/counter_text.dart';

class StatsStrip extends StatelessWidget {
  const StatsStrip({
    super.key,
    required this.projectsDeployed,
    required this.activeClients,
    required this.uptimePct,
  });

  final int projectsDeployed;
  final int activeClients;
  final int uptimePct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: ESizes.xl, horizontal: ESizes.lg),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: EColors.primary.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _StatItem(value: projectsDeployed, suffix: '', label: 'Projects Deployed'),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: Center(
              child: _StatItem(value: activeClients, suffix: '', label: 'Active Clients'),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: Center(
              child: _StatItem(value: uptimePct, suffix: '%', label: 'Uptime'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.suffix, required this.label});

  final int value;
  final String suffix;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CounterText(key: ValueKey(label), value: value, suffix: suffix),
        const SizedBox(height: ESizes.xs),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: VerticalDivider(
        color: EColors.primary.withValues(alpha: 0.2),
        width: ESizes.xl,
        thickness: 1,
      ),
    );
  }
}
