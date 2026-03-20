import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/plan_configurator_overlay.dart';

class PlanCard extends StatefulWidget {
  const PlanCard({super.key, required this.plan, required this.hoveredId});

  final PlanModel plan;
  final ValueNotifier<String?> hoveredId;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.plan.isFeatured) _pulseController.repeat(reverse: true);
    widget.hoveredId.addListener(_onHoverChanged);
  }

  @override
  void dispose() {
    widget.hoveredId.removeListener(_onHoverChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onHoverChanged() {
    if (!widget.plan.isFeatured) return;
    final hovered = widget.hoveredId.value;
    if (hovered == null) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  // Glow rules:
  //   this card hovered        → 1.0 (full)
  //   another card hovered,
  //     this is featured       → 0.15 (dim hold)
  //   nothing hovered,
  //     this is featured       → pulse value
  //   nothing hovered,
  //     not featured           → 0.0
  double get _effectiveGlow {
    final hovered = widget.hoveredId.value;
    if (hovered == widget.plan.id) return 1.0;
    if (hovered != null && widget.plan.isFeatured) return 0.15;
    if (widget.plan.isFeatured) return _pulseAnim.value;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = widget.plan.isCustom
        ? EColors.accent
        : EColors.primary;

    // Content built once — not inside any builder — preserves NeonButton hover state.
    final content = _PlanCardContent(
      plan: widget.plan,
      accentColor: accentColor,
      onCta: () => Get.dialog(
        PlanConfiguratorOverlay(plan: widget.plan),
        barrierColor: Colors.transparent,
      ),
    );

    return MouseRegion(
      onEnter: (_) => widget.hoveredId.value = widget.plan.id,
      onExit: (_) => widget.hoveredId.value = null,
      cursor: SystemMouseCursors.basic,
      child: widget.plan.isFeatured
          // Featured: AnimatedBuilder drives the pulse; ValueListenableBuilder
          // also drives rebuilds when another card is hovered (dimming).
          ? ValueListenableBuilder<String?>(
              valueListenable: widget.hoveredId,
              builder: (_, __, ___) => AnimatedBuilder(
                animation: _pulseAnim,
                child: content,
                builder: (_, child) => _CardShell(
                  plan: widget.plan,
                  accentColor: accentColor,
                  glow: _effectiveGlow,
                  child: child!,
                ),
              ),
            )
          : ValueListenableBuilder<String?>(
              valueListenable: widget.hoveredId,
              builder: (_, __, ___) => _CardShell(
                plan: widget.plan,
                accentColor: accentColor,
                glow: _effectiveGlow,
                child: content,
              ),
            ),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.plan,
    required this.accentColor,
    required this.glow,
    required this.child,
  });

  final PlanModel plan;
  final Color accentColor;
  final double glow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderAlpha = (0.2 + 0.6 * glow).clamp(0.2, 0.8);
    final borderWidth = 1.0 + 0.5 * glow;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 570,
        minWidth: 300,
        maxWidth: 300,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EColors.backgroundDark.withValues(alpha: glow > 0 ? 0.05 : 0.01),
              EColors.backgroundDark.withValues(alpha: 0.88),
            ],
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: borderAlpha),
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(
                alpha: glow > 0 ? 0.28 * glow : 0.06,
              ),
              blurRadius: glow > 0 ? 28.0 * glow : 4,
              spreadRadius: glow > 0 ? 3.0 * glow : 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
          child: child,
        ),
      ),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _PlanCardContent extends StatelessWidget {
  const _PlanCardContent({
    required this.plan,
    required this.accentColor,
    required this.onCta,
  });

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
                  'or \$400 one-time handover',
                  style: TextStyle(
                    color: EColors.textSecondary.withValues(alpha: 0.55),
                    fontSize: ESizes.fontSizeLabel - 1,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              // Always reserve pill height so all cards align vertically.
              if (plan.bundleSavings != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: EColors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    border: Border.all(
                      color: EColors.gold.withValues(alpha: 0.35),
                    ),
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
              // Always reserve two lines of height so cards align regardless
              // of whether idealFor wraps to one or two lines.
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
              Divider(
                color: EColors.primary.withValues(alpha: 0.15),
                thickness: 1,
              ),
              const SizedBox(height: ESizes.md),
              // Fixed-height block — 4 feature slots + 1 overflow row = 150px.
              // Keeps all cards the same height regardless of feature count.
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
                                      color: EColors.textWhite.withValues(
                                        alpha: 0.8,
                                      ),
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
                padding: const EdgeInsets.symmetric(
                  vertical: ESizes.md,
                  horizontal: ESizes.lg,
                ),
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

// ─── Badge / Icon zone ────────────────────────────────────────────────────────

class _BadgeOrIcon extends StatelessWidget {
  const _BadgeOrIcon({required this.plan, required this.accentColor});

  final PlanModel plan;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (plan.isCustom) {
      return Text(
        '◆',
        style: TextStyle(color: EColors.accent, fontSize: 22, height: 1),
      );
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
