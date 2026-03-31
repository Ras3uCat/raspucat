import 'package:raspucat/utils/constants/exports.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    final isMobile = EDeviceUtils.isMobileWidth(width);

    return SectionContainer(
      child: Center(
        child: SelectionArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CenterLogo(),
              const SizedBox(height: ESizes.spaceBtwSections),
              FittedBox(
                child: NeonText(
                  text: EText.heroHeading.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),

              Text(
                EText.heroSubtext.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: EColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESizes.spaceBtwSections),
              AnimatedOnView(
                id: 'hero_cta',
                controller: SectionAnimationController.instance,
                startOffset: const Offset(0, 20),
                child: Semantics(
                  label: 'Explore work',
                  child: NeonButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ESizes.xl,
                      vertical: ESizes.md,
                    ),
                    onTap: () => EScrollController.instance.scrollTo(
                      MediaQuery.sizeOf(context).height * 2,
                    ),
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
          ],
          ),
        ),
      ),
    );
  }
}
