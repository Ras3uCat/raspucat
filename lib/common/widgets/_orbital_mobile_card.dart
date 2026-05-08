import 'dart:ui';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';

class OrbitalMobileCard extends StatelessWidget {
  const OrbitalMobileCard({super.key, required this.item});

  final StickySwapItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(ESizes.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withValues(alpha: 0.12),
                  border: Border.all(color: item.color.withValues(alpha: 0.4), width: 1),
                ),
                child: Icon(item.icon, size: ESizes.iconMd, color: item.color),
              ),
              const SizedBox(width: ESizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ESizes.xs),
                    Text(
                      item.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
