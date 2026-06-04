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
          'We get to know your business, your goals, and your customers. '
          'We research your competitors and align everything to your brand, '
          'then hand you a clear feature list, a competitor report, and an upfront price. '
          'No guessing games, no surprise fees.',
      icon: Icons.search_outlined,
      color: EColors.primary,
    ),
    StickySwapItem(
      title: 'Design',
      body:
          'Every screen is designed around your brand and shown to you for approval '
          'before we write a single line of code. What you see is exactly what gets built.',
      icon: Icons.palette_outlined,
      color: EColors.accent,
    ),
    StickySwapItem(
      title: 'Build',
      body:
          'We build your app to be fast, secure, and connected to everything it needs: '
          'payments, a live database, and real-time updates. Watch progress in your client portal as it happens.',
      icon: Icons.terminal_outlined,
      color: EColors.gold,
    ),
    StickySwapItem(
      title: 'Deploy',
      body:
          'The final payment is only collected after you review and approve the finished product. '
          'Then we launch it on your domain, under your brand, ready for real users.',
      icon: Icons.rocket_launch_outlined,
      color: EColors.primary,
    ),
    StickySwapItem(
      title: 'Expand',
      body:
          'Need something new later? Add features like online booking, an AI chat assistant, '
          'or a loyalty program straight from your portal. No new contracts, no waiting in line.',
      icon: Icons.add_circle_outline,
      color: EColors.accent,
    ),
    StickySwapItem(
      title: 'Operate',
      body:
          'We handle hosting, updates, and support so you can focus on running your business. '
          'If you ever want to move on, we hand over everything: code, logins, and documentation.',
      icon: Icons.settings_outlined,
      color: EColors.gold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const StickySwapSection(items: _items, sectionLabel: '// HOW IT WORKS');
  }
}
