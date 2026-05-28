import 'package:raspucat/app/modules/widgets/portal_discovery_fields.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_readonly.dart';
import 'package:raspucat/utils/constants/exports.dart';
import '_discovery_color_picker_field.dart';
import '_discovery_font_selector.dart';
import '_portal_discovery_sections_b.dart';
import '_discovery_layout_previews.dart';
import '_discovery_upload_field.dart';
export '_portal_discovery_sections_b.dart';

// Section widgets for the discovery form. Private to this view.

typedef _KV = void Function(String key, String value);

class PortalDiscoveryPersonalitySection extends StatelessWidget {
  const PortalDiscoveryPersonalitySection({
    required this.personalities,
    required this.selected,
    required this.onChanged,
  });
  final List<(String, String)> personalities;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '1. Personality',
    'What is the overall vibe and aura of your brand?',
    child: DiscoveryRadioGroup(options: personalities, selected: selected, onChanged: onChanged),
  );
}

class PortalDiscoveryLayoutSection extends StatelessWidget {
  const PortalDiscoveryLayoutSection({
    required this.heroVariants,
    required this.navStyles,
    required this.heroVariant,
    required this.navStyle,
    required this.onHeroChanged,
    required this.onNavChanged,
  });
  final List<(String, String)> heroVariants;
  final List<(String, String)> navStyles;
  final String? heroVariant;
  final String? navStyle;
  final ValueChanged<String> onHeroChanged;
  final ValueChanged<String> onNavChanged;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '2. Layout',
    'How should your site look at first glance?',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscoverySubLabel('Hero style'),
        const SizedBox(height: ESizes.xs),
        DiscoveryLayoutPicker(
          options: heroVariants,
          selected: heroVariant,
          onChanged: onHeroChanged,
          painterFor: heroVariantPainter,
          cardWidth: 92,
          cardHeight: 62,
        ),
        const SizedBox(height: ESizes.md),
        DiscoverySubLabel('Navigation style'),
        const SizedBox(height: ESizes.xs),
        DiscoveryLayoutPicker(
          options: navStyles,
          selected: navStyle,
          onChanged: onNavChanged,
          painterFor: navStylePainter,
          cardWidth: 92,
          cardHeight: 40,
        ),
      ],
    ),
  );
}

class PortalDiscoveryColorsSection extends StatelessWidget {
  const PortalDiscoveryColorsSection({
    required this.primaryCtrl,
    required this.secondaryCtrl,
    required this.accentCtrl,
    required this.surfaceCtrl,
    required this.onSurfaceCtrl,
    required this.onSet,
  });
  final TextEditingController primaryCtrl, secondaryCtrl, accentCtrl, surfaceCtrl, onSurfaceCtrl;
  final _KV onSet;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '3. Colors',
    'Enter your brand hex codes (without #)',
    child: Column(
      children: [
        DiscoveryColorPickerField(
          'Primary — buttons & links',
          primaryCtrl,
          'COLOR_PRIMARY',
          onChanged: (v) => onSet('COLOR_PRIMARY', v),
        ),
        DiscoveryColorPickerField(
          'Secondary — secondary UI',
          secondaryCtrl,
          'COLOR_SECONDARY',
          onChanged: (v) => onSet('COLOR_SECONDARY', v),
        ),
        DiscoveryColorPickerField(
          'Accent — highlights & hover',
          accentCtrl,
          'COLOR_ACCENT',
          onChanged: (v) => onSet('COLOR_ACCENT', v),
        ),
        DiscoveryColorPickerField(
          'Background — page surface',
          surfaceCtrl,
          'COLOR_SURFACE',
          onChanged: (v) => onSet('COLOR_SURFACE', v),
        ),
        DiscoveryColorPickerField(
          'Text — usually FFF or 111',
          onSurfaceCtrl,
          'COLOR_ON_SURFACE',
          onChanged: (v) => onSet('COLOR_ON_SURFACE', v),
        ),
      ],
    ),
  );
}

class PortalDiscoveryFontsSection extends StatelessWidget {
  const PortalDiscoveryFontsSection({
    required this.primaryCtrl,
    required this.secondaryCtrl,
    required this.onSet,
  });
  final TextEditingController primaryCtrl, secondaryCtrl;
  final _KV onSet;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '4. Fonts',
    'Start typing to search Google Fonts',
    child: Column(
      children: [
        DiscoveryFontSelector(
          label: 'Headline font',
          controller: primaryCtrl,
          onChanged: (v) => onSet('FONT_PRIMARY', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryFontSelector(
          label: 'Body / UI font',
          controller: secondaryCtrl,
          onChanged: (v) => onSet('FONT_SECONDARY', v),
        ),
      ],
    ),
  );
}

class PortalDiscoveryBrandBriefSection extends StatelessWidget {
  const PortalDiscoveryBrandBriefSection({
    super.key,
    required this.shortNameCtrl,
    required this.logoUrl,
    required this.onLogoUpload,
    required this.threeWordsCtrl,
    required this.celebrityCtrl,
    required this.targetCustCtrl,
    required this.inspoUrlsCtrl,
    required this.onSet,
    required this.onBrandBrief,
    this.prefillLogoUrl,
    this.onLogoUrlChanged,
  });
  final TextEditingController shortNameCtrl,
      threeWordsCtrl,
      celebrityCtrl,
      targetCustCtrl,
      inspoUrlsCtrl;
  final String? logoUrl;
  final String? prefillLogoUrl;
  final Future<String?> Function(String, String, String) onLogoUpload;
  final ValueChanged<String>? onLogoUrlChanged;
  final _KV onSet;
  final _KV onBrandBrief;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '5. Brand Brief',
    "Help us understand your brand's soul",
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscoveryLabeledField(
          'Short display name (≤12 chars, e.g. "Acme")',
          shortNameCtrl,
          hint: 'e.g. Acme, Brewed, Zara',
          maxLength: 12,
          onChanged: (v) => onSet('SHORT_NAME', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLogoField(
          logoUrl: logoUrl,
          prefillLogoUrl: prefillLogoUrl,
          onLogoUpload: onLogoUpload,
          onLogoUrlChanged: onLogoUrlChanged,
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Describe your brand in 3 words',
          threeWordsCtrl,
          hint: 'e.g. Bold, Warm, Honest',
          onChanged: (v) => onBrandBrief('three_words', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'If your brand were a celebrity, who would it be and why?',
          celebrityCtrl,
          hint: 'e.g. Oprah — approachable, inspiring, premium',
          maxLines: 2,
          onChanged: (v) => onBrandBrief('celebrity', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Who is your primary customer?',
          targetCustCtrl,
          hint: 'e.g. Women 30–45 who value organic skincare',
          onChanged: (v) => onBrandBrief('target_customer', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          '1–2 websites you love the look of (optional)',
          inspoUrlsCtrl,
          hint: 'e.g. apple.com, allbirds.com',
          onChanged: (v) => onBrandBrief('inspo_urls', v),
        ),
      ],
    ),
  );
}
