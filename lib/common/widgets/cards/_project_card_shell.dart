import 'package:raspucat/utils/constants/exports.dart';

class ProjectCardShell extends StatelessWidget {
  const ProjectCardShell({super.key, required this.glow, required this.child});

  final double glow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderAlpha = (0.2 + 0.6 * glow).clamp(0.2, 0.8);

    return Container(
      width: ESizes.carouselWidth,
      margin: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EColors.backgroundDark.withValues(alpha: glow > 0 ? 0.05 : 0.01),
            EColors.backgroundDark,
          ],
        ),
        border: Border.all(
          color: EColors.primary.withValues(alpha: borderAlpha),
          width: 1.0 + 0.5 * glow,
        ),
        boxShadow: [
          BoxShadow(
            color: EColors.primary.withValues(alpha: glow > 0 ? 0.22 * glow : 0.08),
            blurRadius: glow > 0 ? 24 * glow : 5,
            spreadRadius: glow > 0 ? 2 * glow : 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}
