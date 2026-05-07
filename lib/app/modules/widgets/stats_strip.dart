import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/counter_text.dart';

// Horizontal stats strip: numbers count up from 0 on viewport entry.
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key});

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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _StatItem(value: 12, suffix: '', label: 'Projects Shipped'),
          _StatDivider(),
          _StatItem(value: 4, suffix: '', label: 'Active Clients'),
          _StatDivider(),
          _StatItem(value: 99, suffix: '%', label: 'Uptime'),
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
        CounterText(value: value, suffix: suffix),
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
