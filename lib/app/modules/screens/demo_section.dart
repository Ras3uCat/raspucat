import 'package:raspucat/common/widgets/magnetic_widget.dart';
import 'package:raspucat/utils/constants/exports.dart';

class DemoSection extends StatelessWidget {
  const DemoSection({super.key});

  static const _demoUrl = 'https://demo.raspucat.com';

  Future<void> _openDemo() async {
    final uri = Uri.parse(_demoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      child: Center(
        child: SelectionArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '// LIVE DEMO',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ESizes.fontSizeSm,
                  color: EColors.primary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: ESizes.sm),
              FittedBox(
                child: Text(
                  'SEE IT IN ACTION',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    shadows: [
                      Shadow(color: EColors.primary.withValues(alpha: 0.8), blurRadius: 8),
                      Shadow(color: EColors.primary.withValues(alpha: 0.4), blurRadius: 24),
                      Shadow(color: EColors.primary.withValues(alpha: 0.2), blurRadius: 48),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: ESizes.md),
              Text(
                'Experience the full booking flow, admin dashboard,\nand artist portal — exactly as your clients will.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: EColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESizes.spaceBtwSections),
              AnimatedOnView(
                id: 'demo_cta',
                controller: SectionAnimationController.instance,
                startOffset: const Offset(0, 20),
                child: Semantics(
                  label: 'Explore the demo',
                  child: MagneticWidget(
                    child: NeonButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ESizes.xl,
                        vertical: ESizes.md,
                      ),
                      onTap: _openDemo,
                      child: const Text(
                        'EXPLORE THE DEMO',
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
