import 'package:raspucat/utils/constants/exports.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverySummaryCard extends StatelessWidget {
  const DiscoverySummaryCard({required this.data});
  final Map<String, dynamic> data;

  static List<String> _parseUrls(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(RegExp(r'[\n,]+'))
        .map((s) => s.trim())
        .where((s) => s.startsWith('http://') || s.startsWith('https://'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String? v) => v == null || v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: ESizes.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    k,
                    style: TextStyle(
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    v,
                    style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
                  ),
                ),
              ],
            ),
          );

    Widget urlRow(String k, List<String> urls) => urls.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: ESizes.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    k,
                    style: TextStyle(
                      color: EColors.textSecondary.withValues(alpha: 0.4),
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: urls.map((url) {
                      final display = url.replaceFirst(RegExp(r'https?://'), '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                            child: Text(
                              display,
                              style: TextStyle(
                                color: EColors.primary,
                                fontSize: ESizes.fontSizeSm,
                                decoration: TextDecoration.underline,
                                decorationColor: EColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );

    final bb = (data['brand_brief'] as Map<String, dynamic>?) ?? {};
    final inspoUrls = _parseUrls(bb['inspo_urls'] as String?);

    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('Personality', data['PERSONALITY'] as String?),
          row('Hero variant', data['HERO_VARIANT'] as String?),
          row('Nav style', data['NAV_STYLE'] as String?),
          row('Short name', data['SHORT_NAME'] as String?),
          row('Primary color', data['COLOR_PRIMARY'] as String?),
          row('Font', data['FONT_PRIMARY'] as String?),
          row('Phone', data['PHONE'] as String?),
          row('City', data['CITY'] as String?),
          row('SEO title', data['SEO_TITLE'] as String?),
          row('3 words', bb['three_words'] as String?),
          urlRow('Inspo URLs', inspoUrls),
          row('Reply-to email', data['FROM_EMAIL'] as String?),
          row('Instagram', data['INSTAGRAM_URL'] as String?),
          row('Facebook', data['FACEBOOK_URL'] as String?),
          row('TikTok', data['TIKTOK_URL'] as String?),
          row('YouTube', data['YOUTUBE_URL'] as String?),
        ],
      ),
    );
  }
}
