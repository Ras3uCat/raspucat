import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/modules/screens/_app_project_live_ctas.dart';
import 'package:raspucat/common/widgets/magnetic_widget.dart';
import 'package:raspucat/common/widgets/text/neon_text.dart';
import 'package:raspucat/routes/routes.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

const _kHeroFontSize = 52.0;
const _kTagline = 'YOUR WATCHLIST.\nRANKED. FILTERED. OBSESSED.';

class LiveAppHero extends StatefulWidget {
  const LiveAppHero({super.key, required this.appName, this.appStoreUrl, this.playStoreUrl});

  final String appName;
  final String? appStoreUrl;
  final String? playStoreUrl;

  @override
  State<LiveAppHero> createState() => _LiveAppHeroState();
}

class _LiveAppHeroState extends State<LiveAppHero> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _titleAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _ctaAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();

    _titleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _taglineAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
    _ctaAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.xl, ESizes.lg, ESizes.section2Xs),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF040E1A), Color(0xFF000612)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(alignment: Alignment.centerLeft, child: _BackLink()),
          const SizedBox(height: ESizes.section2Xs),
          AnimatedBuilder(
            animation: _titleAnim,
            builder: (_, child) => Opacity(
              opacity: _titleAnim.value,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - _titleAnim.value)),
                child: child,
              ),
            ),
            child: NeonText(
              text: widget.appName.toUpperCase(),
              neonColor: EColors.primary,
              isHeadline: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: _kHeroFontSize,
                fontWeight: FontWeight.w900,
                color: EColors.cyanTintedWhite,
                letterSpacing: 6.0,
              ),
            ),
          ),
          const SizedBox(height: ESizes.lg),
          AnimatedBuilder(
            animation: _taglineAnim,
            builder: (_, child) => Opacity(
              opacity: _taglineAnim.value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - _taglineAnim.value)),
                child: child,
              ),
            ),
            child: const Text(
              _kTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: ESizes.fontSizeMd,
                color: EColors.textSecondary,
                letterSpacing: 2.5,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: ESizes.xl),
          AnimatedBuilder(
            animation: _ctaAnim,
            builder: (_, child) => Opacity(opacity: _ctaAnim.value, child: child),
            child: Column(
              children: [
                _PlatformBadges(),
                const SizedBox(height: ESizes.lg),
                if (widget.appStoreUrl != null || widget.playStoreUrl != null)
                  MagneticWidget(
                    child: LiveAppDownloadCtas(
                      appStoreUrl: widget.appStoreUrl,
                      playStoreUrl: widget.playStoreUrl,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Badge(label: 'iOS'),
        const SizedBox(width: ESizes.sm),
        _Badge(label: 'Android'),
        const SizedBox(width: ESizes.sm),
        _Badge(label: 'Free', color: EColors.accent),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.color = EColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(128)),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXxl),
        color: color.withAlpha(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: ESizes.fontSizeLabel,
          color: color,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.offAllNamed(ERoutes.home),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios, size: ESizes.iconXs, color: EColors.textSecondary),
          SizedBox(width: ESizes.xs),
          Text(
            'raspucat.com',
            style: TextStyle(
              fontSize: ESizes.fontSizeLabel,
              color: EColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
