import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/horizontal_scroll_panels.dart';

// Horizontal scroll version of HowItWorks.
// 4 panels: Discover → Design → Build → Deploy.
// Replaces the vertical HowItWorksSection on desktop.
class HowItWorksPanels extends StatelessWidget {
  const HowItWorksPanels({super.key});

  @override
  Widget build(BuildContext context) {
    return HorizontalScrollPanels(
      title: 'HOW IT WORKS',
      panels: const [
        _StepPanel(
          step: '01',
          headline: 'Discover',
          body:
              'We audit your goals, audience, and competitors. '
              'You walk away with a prioritised feature list and a fixed quote — '
              'no discovery fees, no vague estimates.',
          icon: Icons.search_outlined,
        ),
        _StepPanel(
          step: '02',
          headline: 'Design',
          body:
              'Brand-aligned UI in Flutter. Every screen is prototyped '
              'and approved before a line of production code is written.',
          icon: Icons.palette_outlined,
        ),
        _StepPanel(
          step: '03',
          headline: 'Build',
          body:
              'Clean architecture — GetX state, Supabase backend, Stripe payments. '
              'Track every commit in your client portal in real time.',
          icon: Icons.terminal_outlined,
        ),
        _StepPanel(
          step: '04',
          headline: 'Deploy',
          body:
              'Final balance charged only after your sign-off. '
              'Your domain, your brand, your code — live and running.',
          icon: Icons.rocket_launch_outlined,
        ),
      ],
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({
    required this.step,
    required this.headline,
    required this.body,
    required this.icon,
  });

  final String step;
  final String headline;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EColors.backgroundDark,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(ESizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EColors.primary.withValues(alpha: 0.08),
                        border: Border.all(color: EColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Icon(icon, color: EColors.primary, size: ESizes.iconMd),
                    ),
                    const SizedBox(width: ESizes.md),
                    Text(
                      '// $step',
                      style: TextStyle(
                        color: EColors.primary.withValues(alpha: 0.6),
                        fontSize: ESizes.fontSizeLabel,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ESizes.xl),
                NeonText(
                  text: headline.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: ESizes.lg),
                Text(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: EColors.textSecondary, height: 1.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
