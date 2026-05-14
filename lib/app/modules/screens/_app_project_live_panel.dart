import 'package:flutter/material.dart';
import 'package:raspucat/app/data/models/app_project_model.dart';
import 'package:raspucat/app/modules/screens/_app_project_live_carousel.dart';
import 'package:raspucat/app/modules/screens/_app_project_live_ctas.dart';
import 'package:raspucat/app/modules/screens/_app_project_live_features.dart';
import 'package:raspucat/app/modules/screens/_app_project_live_hero.dart';
import 'package:raspucat/common/widgets/magnetic_widget.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

const _kScreenshotAssets = <String, List<String>>{
  'bingequest': [
    'assets/images/projects/bingequest_play_2.png',
    'assets/images/projects/bingequest_play_3.png',
    'assets/images/projects/bingequest_ios_2.png',
    'assets/images/projects/bingequest_ios_3.png',
    'assets/images/projects/bingequest_ios_4.png',
  ],
};

const _kFeaturedSlugs = {'bingequest'};

class LiveAppPanel extends StatelessWidget {
  const LiveAppPanel({super.key, required this.project});

  final AppProject project;

  @override
  Widget build(BuildContext context) {
    final slug = project.slug?.toLowerCase() ?? '';
    final screenshots = _kScreenshotAssets[slug] ?? [];
    final showFeatures = _kFeaturedSlugs.contains(slug);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LiveAppHero(
            appName: project.name,
            appStoreUrl: project.appStoreUrl,
            playStoreUrl: project.playStoreUrl,
          ),
          if (screenshots.isNotEmpty) ...[
            const _ScreenshotsLabel(),
            LiveAppCarousel(screenshots: screenshots),
            const SizedBox(height: ESizes.section2Xs),
          ],
          if (showFeatures) const LiveAppFeatures(),
          if (project.appStoreUrl != null || project.playStoreUrl != null)
            _BottomCta(appStoreUrl: project.appStoreUrl, playStoreUrl: project.playStoreUrl),
          const SizedBox(height: ESizes.section2Xs),
        ],
      ),
    );
  }
}

class _ScreenshotsLabel extends StatelessWidget {
  const _ScreenshotsLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.lg, ESizes.lg, ESizes.md),
      child: Row(
        children: [
          Container(width: ESizes.sm, height: 1, color: EColors.primary),
          const SizedBox(width: ESizes.sm),
          const Text(
            '// IN ACTION',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ESizes.fontSizeLabel,
              color: EColors.primary,
              letterSpacing: 3.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: ESizes.sm),
          Expanded(child: Container(height: 1, color: EColors.primary.withAlpha(51))),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({this.appStoreUrl, this.playStoreUrl});

  final String? appStoreUrl;
  final String? playStoreUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: ESizes.section2Xs, horizontal: ESizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [EColors.primary.withAlpha(10), EColors.primary.withAlpha(25)],
        ),
        border: Border(top: BorderSide(color: EColors.primary.withAlpha(51))),
      ),
      child: Column(
        children: [
          const Text(
            '// GET THE APP',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ESizes.fontSizeLabel,
              color: EColors.primary,
              letterSpacing: 3.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESizes.md),
          const Text(
            'Available on iOS & Android.\nFree to download.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ESizes.fontSizeLg,
              fontWeight: FontWeight.w700,
              color: EColors.cyanTintedWhite,
              height: 1.4,
            ),
          ),
          const SizedBox(height: ESizes.xl),
          MagneticWidget(
            child: LiveAppDownloadCtas(appStoreUrl: appStoreUrl, playStoreUrl: playStoreUrl),
          ),
        ],
      ),
    );
  }
}
