part of 'plan_card.dart';

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
      constraints: const BoxConstraints(minHeight: 570, minWidth: 300, maxWidth: 300),
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
              color: accentColor.withValues(alpha: glow > 0 ? 0.28 * glow : 0.06),
              blurRadius: glow > 0 ? 28.0 * glow : 4,
              spreadRadius: glow > 0 ? 3.0 * glow : 1,
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(ESizes.borderRadiusLg), child: child),
      ),
    );
  }
}
