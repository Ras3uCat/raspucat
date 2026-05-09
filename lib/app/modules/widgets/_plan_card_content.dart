part of 'plan_card.dart';

class _PlanCardContent extends StatelessWidget {
  const _PlanCardContent({required this.plan, required this.accentColor, required this.onCta});

  final PlanModel plan;
  final Color accentColor;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 36,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BadgeOrIcon(plan: plan, accentColor: accentColor),
                ),
              ),
              const SizedBox(height: ESizes.sm),
              NeonText(
                text: plan.name.toUpperCase(),
                neonColor: accentColor,
                isHeadline: false,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: ESizes.md),
              Text(
                plan.price,
                style: TextStyle(
                  color: EColors.gold,
                  fontSize: ESizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (plan.monthlyPrice.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  plan.monthlyPrice,
                  style: TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSizeLabel,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  EText.planHandoverNote,
                  style: TextStyle(
                    color: EColors.textSecondary.withValues(alpha: 0.55),
                    fontSize: ESizes.fontSizeLabel - 1,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              if (plan.bundleSavings != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: EColors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    border: Border.all(color: EColors.gold.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    plan.bundleSavings!,
                    style: TextStyle(
                      color: EColors.gold,
                      fontSize: ESizes.fontSizeLabel,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: Text(
                  plan.idealFor,
                  style: TextStyle(
                    color: EColors.textSecondary,
                    fontSize: ESizes.fontSizeLabel,
                    height: 1.4,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: ESizes.md),
              Divider(color: EColors.primary.withValues(alpha: 0.15), thickness: 1),
              const SizedBox(height: ESizes.md),
              SizedBox(
                height: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...plan.features
                        .take(4)
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✓  ',
                                  style: TextStyle(
                                    color: EColors.primary,
                                    fontSize: ESizes.fontSizeSm,
                                    height: 1.4,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    f,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: EColors.textWhite.withValues(alpha: 0.8),
                                      fontSize: ESizes.fontSizeSm,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (plan.features.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          plan.features.last.startsWith('+')
                              ? plan.features.last
                              : '+ ${plan.features.length - 4} more included',
                          style: TextStyle(
                            color: EColors.textSecondary,
                            fontSize: ESizes.fontSizeSm,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: ESizes.lg),
            child: SizedBox(
              width: double.infinity,
              child: NeonButton(
                onTap: onCta,
                neonColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: ESizes.md, horizontal: ESizes.lg),
                child: Center(
                  child: Text(
                    'Select Plan',
                    style: const TextStyle(
                      color: EColors.textWhite,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeOrIcon extends StatelessWidget {
  const _BadgeOrIcon({required this.plan, required this.accentColor});

  final PlanModel plan;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (plan.isCustom) {
      return Text('◆', style: TextStyle(color: EColors.accent, fontSize: 22, height: 1));
    }
    if (plan.isFeatured) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 3),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          'MOST POPULAR',
          style: TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
