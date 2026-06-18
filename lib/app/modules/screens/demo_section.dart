import 'package:raspucat/common/widgets/magnetic_widget.dart';
import 'package:raspucat/utils/constants/exports.dart';

class DemoSection extends StatefulWidget {
  const DemoSection({super.key});

  @override
  State<DemoSection> createState() => _DemoSectionState();
}

class _DemoSectionState extends State<DemoSection> {
  static const _demoUrl = 'https://demo.raspucat.com';
  bool _imageHovered = false;

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
                'Experience the full booking flow, admin dashboard,\nand artist portal, exactly as your clients will.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: EColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESizes.spaceBtwSections),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _imageHovered = true),
                onExit: (_) => setState(() => _imageHovered = false),
                child: GestureDetector(
                  onTap: _openDemo,
                  child: AnimatedScale(
                    scale: _imageHovered ? 1.025 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
                        border: Border.all(
                          color: EColors.primary.withValues(alpha: _imageHovered ? 0.7 : 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: EColors.primary.withValues(alpha: _imageHovered ? 0.35 : 0.15),
                            blurRadius: _imageHovered ? 48 : 32,
                            spreadRadius: _imageHovered ? 4 : 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
                        child: Image.asset(
                          'assets/images/demo_preview.gif',
                          width: 620,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
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
