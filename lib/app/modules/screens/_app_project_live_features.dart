import 'package:flutter/material.dart';
import 'package:raspucat/common/widgets/tilt_card.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.body,
    this.accentColor = EColors.primary,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accentColor;
}

const _kFeatures = [
  _Feature(
    icon: Icons.favorite_rounded,
    title: 'Queue Health',
    body: 'Every title gets a score. Stop rewatching the same three shows.',
  ),
  _Feature(
    icon: Icons.mood_rounded,
    title: 'Mood Filter',
    body: "Not in the mood for drama? Filter your queue by tonight's vibe.",
    accentColor: EColors.accent,
  ),
  _Feature(
    icon: Icons.play_circle_fill_rounded,
    title: 'Streaming Tracker',
    body: 'Know exactly which service has it — and when it expires.',
  ),
  _Feature(
    icon: Icons.group_rounded,
    title: 'Shared Watchlists',
    body: 'Build lists with friends. See what they\'re watching and rating.',
    accentColor: EColors.accent,
  ),
];

class LiveAppFeatures extends StatefulWidget {
  const LiveAppFeatures({super.key});

  @override
  State<LiveAppFeatures> createState() => _LiveAppFeaturesState();
}

class _LiveAppFeaturesState extends State<LiveAppFeatures> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.section2Xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(),
          const SizedBox(height: ESizes.xl),
          isMobile
              ? Column(
                  children: [
                    for (int i = 0; i < _kFeatures.length; i++) ...[
                      _AnimatedCard(ctrl: _ctrl, index: i, feature: _kFeatures[i]),
                      if (i < _kFeatures.length - 1) const SizedBox(height: ESizes.md),
                    ],
                  ],
                )
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: ESizes.md,
                  mainAxisSpacing: ESizes.md,
                  childAspectRatio: 1.6,
                  children: [
                    for (int i = 0; i < _kFeatures.length; i++)
                      _AnimatedCard(ctrl: _ctrl, index: i, feature: _kFeatures[i]),
                  ],
                ),
        ],
      ),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({required this.ctrl, required this.index, required this.feature});

  final AnimationController ctrl;
  final int index;
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final start = index * 0.15;
    final end = (start + 0.55).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - anim.value)), child: child),
      ),
      child: TiltCard(child: _FeatureCard(feature: feature)),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.circuitSlate.withAlpha(230),
        border: Border.all(color: feature.accentColor.withAlpha(77), width: 1),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(feature.icon, color: feature.accentColor, size: ESizes.iconMd),
          const SizedBox(height: ESizes.sm),
          Text(
            feature.title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ESizes.fontSizeSm,
              color: feature.accentColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: ESizes.xs),
          Text(
            feature.body,
            style: const TextStyle(
              fontSize: ESizes.fontSizeSm,
              color: EColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// FEATURES',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: ESizes.fontSizeLabel,
            color: EColors.primary,
            letterSpacing: 3.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Text(
          'Everything your\nwatchlist was missing.',
          style: TextStyle(
            fontSize: ESizes.fontSizeTitle,
            fontWeight: FontWeight.w800,
            color: EColors.cyanTintedWhite,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
