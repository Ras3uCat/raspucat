import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/plan_configurator_overlay.dart';

part '_plan_card_shell.dart';
part '_plan_card_content.dart';

class PlanCard extends StatefulWidget {
  const PlanCard({super.key, required this.plan, required this.hoveredId});

  final PlanModel plan;
  final ValueNotifier<String?> hoveredId;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
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
    final Color accentColor = widget.plan.isCustom ? EColors.accent : EColors.primary;

    // Content built once — not inside any builder — preserves NeonButton hover state.
    final content = _PlanCardContent(
      plan: widget.plan,
      accentColor: accentColor,
      onCta: () => Get.dialog(
        PlanConfiguratorOverlay(plan: widget.plan),
        barrierColor: Colors.transparent,
        barrierDismissible: false,
      ),
    );

    return MouseRegion(
      onEnter: (_) => widget.hoveredId.value = widget.plan.id,
      onExit: (_) => widget.hoveredId.value = null,
      cursor: SystemMouseCursors.basic,
      child: widget.plan.isFeatured
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
