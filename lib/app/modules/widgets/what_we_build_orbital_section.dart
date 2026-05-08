import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';
import 'package:raspucat/common/widgets/orbital_timeline.dart';

class WhatWeBuildOrbitalSection extends StatelessWidget {
  const WhatWeBuildOrbitalSection({super.key});

  static const _items = [
    StickySwapItem(
      title: 'Marketing Sites',
      body:
          'Blazing-fast Flutter web — conversion-optimised landing pages '
          'with animated sections, SEO-ready semantics, and retro-futuristic flair.',
      icon: Icons.web_outlined,
      color: EColors.primary,
    ),
    StickySwapItem(
      title: 'Client Portals',
      body:
          'Real-time portals where your clients track progress, upload files, '
          'send messages, and confirm milestones — all without emailing you.',
      icon: Icons.dashboard_outlined,
      color: EColors.accent,
    ),
    StickySwapItem(
      title: 'E-Commerce',
      body:
          'Stripe-powered storefronts with product catalogues, secure checkout, '
          'webhook-driven order flows, and live inventory management.',
      icon: Icons.storefront_outlined,
      color: EColors.gold,
    ),
    StickySwapItem(
      title: 'SaaS Apps',
      body:
          'Full-stack SaaS: Supabase auth and RLS, subscription billing, '
          'role-based access, and modular feature flags — shipped fast.',
      icon: Icons.rocket_launch_outlined,
      color: EColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const OrbitalTimeline(items: _items);
  }
}
