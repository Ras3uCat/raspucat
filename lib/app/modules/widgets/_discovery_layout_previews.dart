import 'package:raspucat/utils/constants/exports.dart';
import '_discovery_layout_painters.dart';

// Thumbnail card picker for hero variant + nav style options in the discovery form.

class DiscoveryLayoutPicker extends StatelessWidget {
  const DiscoveryLayoutPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.painterFor,
    this.cardWidth = 90.0,
    this.cardHeight = 65.0,
  });

  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  final CustomPainter Function(String key, bool active) painterFor;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ESizes.sm,
      runSpacing: ESizes.sm,
      children: options.map((o) {
        final active = selected == o.$1;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: cardWidth,
            decoration: BoxDecoration(
              color: active
                  ? EColors.primary.withValues(alpha: 0.08)
                  : EColors.primary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              border: Border.all(
                color: active
                    ? EColors.primary.withValues(alpha: 0.7)
                    : EColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ESizes.borderRadiusSM - 1),
                  ),
                  child: CustomPaint(
                    painter: painterFor(o.$1, active),
                    size: Size(cardWidth - 2, cardHeight),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    o.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active
                          ? EColors.primary
                          : EColors.textSecondary.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Painter factory functions ────────────────────────────────────────────────

CustomPainter heroVariantPainter(String key, bool active) => switch (key) {
  'fullbleed' => FullbleedPainter(active),
  'split' => SplitPainter(active),
  'centered' => CenteredPainter(active),
  'video_bg' => VideoBgPainter(active),
  _ => FullbleedPainter(active),
};

CustomPainter navStylePainter(String key, bool active) => switch (key) {
  'sticky' => StickyNavPainter(active),
  'overlay' => OverlayNavPainter(active),
  'minimal' => MinimalNavPainter(active),
  'hamburger' => HamburgerNavPainter(active),
  _ => StickyNavPainter(active),
};
