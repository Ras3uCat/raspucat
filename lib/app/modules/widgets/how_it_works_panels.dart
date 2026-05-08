import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';

// StickySwap version of HowItWorks.
// 6 steps: Discover → Design → Build → Deploy → Expand → Operate.
class HowItWorksPanels extends StatelessWidget {
  const HowItWorksPanels({super.key});

  static const _items = [
    StickySwapItem(
      title: 'Discover',
      body:
          'We audit your goals, audience, and competitors. '
          'You walk away with a prioritised feature list and a fixed quote — '
          'no discovery fees, no vague estimates.',
      icon: Icons.search_outlined,
      color: EColors.primary,
    ),
    StickySwapItem(
      title: 'Design',
      body:
          'Brand-aligned UI in Flutter. Every screen is prototyped '
          'and approved before a line of production code is written.',
      icon: Icons.palette_outlined,
      color: EColors.accent,
    ),
    StickySwapItem(
      title: 'Build',
      body:
          'Clean architecture — GetX state, Supabase backend, Stripe payments. '
          'Track every commit in your client portal in real time.',
      icon: Icons.terminal_outlined,
      color: EColors.gold,
    ),
    StickySwapItem(
      title: 'Deploy',
      body:
          'Final balance charged only after your sign-off. '
          'Your domain, your brand, your code — live and verified.',
      icon: Icons.rocket_launch_outlined,
      color: EColors.primary,
    ),
    StickySwapItem(
      title: 'Expand',
      body:
          'Buy new modules — booking, AI chatbot, loyalty programs — '
          'straight from the portal. No new contracts. No waiting in a queue.',
      icon: Icons.add_circle_outline,
      color: EColors.accent,
    ),
    StickySwapItem(
      title: 'Operate',
      body:
          'Monthly management covers hosting, updates, and support. '
          'The handover package transfers everything — code, credentials, docs.',
      icon: Icons.settings_outlined,
      color: EColors.gold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const StickySwapSection(items: _items, sectionLabel: '// HOW IT WORKS');
  }
}
