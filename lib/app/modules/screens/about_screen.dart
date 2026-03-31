import 'package:raspucat/utils/constants/exports.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = SectionAnimationController.instance;

    return SectionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOnView(
            id: 'about_heading',
            controller: ctrl,
            startOffset: const Offset(0, 25),
            child: FittedBox(
              child: NeonText(
                text: 'ABOUT',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
          const SizedBox(height: ESizes.sm),
          AnimatedOnView(
            id: 'about_subtitle',
            controller: ctrl,
            startOffset: const Offset(0, 40),
            child: Text(
              EText.aboutSubLabel.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: EColors.textSecondary,
                    letterSpacing: 3.0,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: ESizes.spaceBtwSections),
          AnimatedOnView(
            id: 'about_bio',
            controller: ctrl,
            startOffset: const Offset(0, 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                EText.aboutBio,
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSizeMd,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: ESizes.spaceBtwSections),
          AnimatedOnView(
            id: 'about_chips',
            controller: ctrl,
            startOffset: const Offset(0, 15),
            child: Wrap(
              spacing: ESizes.md,
              runSpacing: ESizes.sm,
              alignment: WrapAlignment.center,
              children: const [
                _Chip(label: 'Flutter Specialist'),
                _Chip(label: 'Full-Stack Dev'),
                _Chip(label: 'Open for Missions'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md, vertical: ESizes.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        color: EColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: EColors.primary,
          fontSize: ESizes.fontSizeLabel,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
