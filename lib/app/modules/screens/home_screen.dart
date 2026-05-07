import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/animations/text_reveal.dart';
import 'package:raspucat/common/widgets/magnetic_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollCtrl = EScrollController.instance;
    final viewportH = MediaQuery.sizeOf(context).height;

    return SectionContainer(
      child: Center(
        child: SelectionArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CenterLogo(),
              const SizedBox(height: ESizes.spaceBtwSections),

              // Priority 8: parallax background is applied at DesktopLayout level
              // (BackgroundTriangles wraps there with Obx + Transform.translate).

              // Priority 1: word-by-word reveal on hero heading.
              FittedBox(
                child: TextReveal(
                  text: EText.heroHeading.toUpperCase(),
                  style:
                      Theme.of(context).textTheme.headlineLarge?.copyWith(
                        shadows: [
                          Shadow(color: EColors.primary.withValues(alpha: 0.8), blurRadius: 8),
                          Shadow(color: EColors.primary.withValues(alpha: 0.4), blurRadius: 24),
                          Shadow(color: EColors.primary.withValues(alpha: 0.2), blurRadius: 48),
                        ],
                      ) ??
                      const TextStyle(),
                  textAlign: TextAlign.center,
                  trigger: true,
                  wordDelayMs: 200,
                ),
              ),

              Text(
                EText.heroSubtext.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: EColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESizes.spaceBtwSections),

              // Priority 3: magnetic drift on hero CTA.
              AnimatedOnView(
                id: 'hero_cta',
                controller: SectionAnimationController.instance,
                startOffset: const Offset(0, 20),
                child: Semantics(
                  label: 'Explore work',
                  child: MagneticWidget(
                    child: NeonButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.xl,
                        vertical: ESizes.md,
                      ),
                      onTap: () => scrollCtrl.scrollTo(viewportH * 2),
                      child: Text(
                        'EXPLORE WORK',
                        style: TextStyle(
                          color: EColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          fontSize: ESizes.fontSizeSm,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
