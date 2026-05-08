import 'dart:ui';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';

class OrbitalNodeCard extends StatelessWidget {
  const OrbitalNodeCard({super.key, required this.item});

  final StickySwapItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 2, height: 12, color: Colors.white.withValues(alpha: 0.5)),
        ClipRRect(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(ESizes.md),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: ESizes.sm,
                        height: ESizes.sm,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: item.color),
                      ),
                      const SizedBox(width: ESizes.xs),
                      Expanded(
                        child: Text(
                          item.title.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ESizes.xs),
                  Text(
                    item.body,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: ESizes.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    child: Container(
                      height: 3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [EColors.primary, EColors.accent]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
