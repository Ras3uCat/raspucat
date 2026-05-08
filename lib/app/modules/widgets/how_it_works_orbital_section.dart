import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';

class HowItWorksOrbitalSection extends StatelessWidget {
  const HowItWorksOrbitalSection({super.key});

  static const _items = [
    StickySwapItem(
      title: 'Pick your plan.',
      body:
          'Choose a preset plan or build from scratch. Toggle add-ons, watch the price update live. No surprises — your total is locked before you commit.',
      icon: Icons.tune_outlined,
      color: EColors.primary,
    ),
    StickySwapItem(
      title: 'Secure your slot.',
      body:
          'A deposit locks in your build. Stripe-powered — takes 30 seconds. Your remaining balance is charged only when the site is live.',
      icon: Icons.lock_outlined,
      color: EColors.accent,
    ),
    StickySwapItem(
      title: 'We build. You watch.',
      body:
          'Track your project stage, share assets, send messages, and see every update in real time — no chasing emails.',
      icon: Icons.terminal_outlined,
      color: EColors.gold,
    ),
    StickySwapItem(
      title: 'Live. Verified. Yours.',
      body:
          'Final balance is charged only after you confirm the site is ready. Your domain, your brand, your business — online and running.',
      icon: Icons.rocket_launch_outlined,
      color: EColors.primary,
    ),
    StickySwapItem(
      title: 'Add features anytime.',
      body:
          'Buy new modules — booking, AI chatbot, loyalty programs — straight from the portal. No new contracts. No waiting in a queue.',
      icon: Icons.add_circle_outline,
      color: EColors.accent,
    ),
    StickySwapItem(
      title: 'Stay running.',
      body:
          'Monthly management covers hosting, updates, and support. The handover package transfers everything — code, credentials, docs.',
      icon: Icons.settings_outlined,
      color: EColors.gold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const StickySwapSection(items: _items, sectionLabel: '// HOW IT WORKS');
  }
}
