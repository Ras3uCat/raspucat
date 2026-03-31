import 'package:raspucat/app/modules/widgets/portal_discovery_fields.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_readonly.dart';
import 'package:raspucat/utils/constants/exports.dart';

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
    'What should customers feel when they land on your site?',
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
    'How should your hero section look?',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscoverySubLabel('Hero style'),
        DiscoveryRadioGroup(options: heroVariants, selected: heroVariant, onChanged: onHeroChanged),
        const SizedBox(height: ESizes.md),
        DiscoverySubLabel('Navigation style'),
        DiscoveryRadioGroup(options: navStyles, selected: navStyle, onChanged: onNavChanged),
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
        DiscoveryHexField(
          'Primary — buttons & links',
          primaryCtrl,
          'COLOR_PRIMARY',
          onChanged: (v) => onSet('COLOR_PRIMARY', v),
        ),
        DiscoveryHexField(
          'Secondary — secondary UI',
          secondaryCtrl,
          'COLOR_SECONDARY',
          onChanged: (v) => onSet('COLOR_SECONDARY', v),
        ),
        DiscoveryHexField(
          'Accent — highlights & hover',
          accentCtrl,
          'COLOR_ACCENT',
          onChanged: (v) => onSet('COLOR_ACCENT', v),
        ),
        DiscoveryHexField(
          'Background — page surface',
          surfaceCtrl,
          'COLOR_SURFACE',
          onChanged: (v) => onSet('COLOR_SURFACE', v),
        ),
        DiscoveryHexField(
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
    'Google Font names (e.g. "Inter", "Playfair Display")',
    child: Column(
      children: [
        DiscoveryLabeledField(
          'Headline font',
          primaryCtrl,
          onChanged: (v) => onSet('FONT_PRIMARY', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Body / UI font',
          secondaryCtrl,
          onChanged: (v) => onSet('FONT_SECONDARY', v),
        ),
      ],
    ),
  );
}

class PortalDiscoveryBrandBriefSection extends StatelessWidget {
  const PortalDiscoveryBrandBriefSection({
    required this.shortNameCtrl,
    required this.threeWordsCtrl,
    required this.celebrityCtrl,
    required this.targetCustCtrl,
    required this.inspoUrlsCtrl,
    required this.onSet,
    required this.onBrandBrief,
  });
  final TextEditingController shortNameCtrl,
      threeWordsCtrl,
      celebrityCtrl,
      targetCustCtrl,
      inspoUrlsCtrl;
  final _KV onSet;
  final _KV onBrandBrief;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '5. Brand Brief',
    "Help us understand your brand's soul",
    child: Column(
      children: [
        DiscoveryLabeledField(
          'Short display name (≤12 chars, e.g. "Acme")',
          shortNameCtrl,
          maxLength: 12,
          onChanged: (v) => onSet('SHORT_NAME', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Describe your brand in 3 words',
          threeWordsCtrl,
          onChanged: (v) => onBrandBrief('three_words', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'If your brand were a celebrity, who would it be and why?',
          celebrityCtrl,
          maxLines: 2,
          onChanged: (v) => onBrandBrief('celebrity', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Who is your primary customer?',
          targetCustCtrl,
          onChanged: (v) => onBrandBrief('target_customer', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          '1–2 websites you love the look of (optional)',
          inspoUrlsCtrl,
          onChanged: (v) => onBrandBrief('inspo_urls', v),
        ),
      ],
    ),
  );
}

class PortalDiscoveryBusinessInfoSection extends StatelessWidget {
  const PortalDiscoveryBusinessInfoSection({
    required this.phoneCtrl,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.zipCtrl,
    required this.countryCtrl,
    required this.timezones,
    required this.timezone,
    required this.days,
    required this.hours,
    required this.onSet,
    required this.onTimezoneChanged,
    required this.onHoursChanged,
  });
  final TextEditingController phoneCtrl, streetCtrl, cityCtrl, stateCtrl, zipCtrl, countryCtrl;
  final List<String> timezones;
  final String? timezone;
  final List<String> days;
  final Map<String, Map<String, dynamic>> hours;
  final _KV onSet;
  final ValueChanged<String?> onTimezoneChanged;
  final VoidCallback onHoursChanged;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '6. Business Info',
    null,
    child: Column(
      children: [
        DiscoveryLabeledField('Phone number', phoneCtrl, onChanged: (v) => onSet('PHONE', v)),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField('Street address', streetCtrl, onChanged: (v) => onSet('STREET', v)),
        const SizedBox(height: ESizes.sm),
        Row(
          children: [
            Expanded(
              child: DiscoveryLabeledField('City', cityCtrl, onChanged: (v) => onSet('CITY', v)),
            ),
            const SizedBox(width: ESizes.sm),
            SizedBox(
              width: 80,
              child: DiscoveryLabeledField('State', stateCtrl, onChanged: (v) => onSet('STATE', v)),
            ),
            const SizedBox(width: ESizes.sm),
            SizedBox(
              width: 90,
              child: DiscoveryLabeledField('ZIP', zipCtrl, onChanged: (v) => onSet('ZIP', v)),
            ),
          ],
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField('Country', countryCtrl, onChanged: (v) => onSet('COUNTRY', v)),
        const SizedBox(height: ESizes.md),
        DiscoverySubLabel('Timezone'),
        const SizedBox(height: ESizes.xs),
        DiscoveryTimezoneDropdown(
          value: timezone,
          timezones: timezones,
          onChanged: onTimezoneChanged,
        ),
        const SizedBox(height: ESizes.md),
        DiscoverySubLabel('Business Hours'),
        const SizedBox(height: ESizes.xs),
        DiscoveryHoursGrid(days: days, hours: hours, onChanged: onHoursChanged),
      ],
    ),
  );
}

class PortalDiscoveryOnlinePresenceSection extends StatelessWidget {
  const PortalDiscoveryOnlinePresenceSection({required this.siteUrlCtrl, required this.onSet});
  final TextEditingController siteUrlCtrl;
  final _KV onSet;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '7. Online Presence',
    null,
    child: DiscoveryLabeledField(
      'Domain name (if you have one)',
      siteUrlCtrl,
      hint: 'e.g. myshop.com',
      onChanged: (v) => onSet('SITE_URL', v),
    ),
  );
}

class PortalDiscoverySeoSection extends StatelessWidget {
  const PortalDiscoverySeoSection({
    required this.seoTitleCtrl,
    required this.seoDescCtrl,
    required this.ogImageCtrl,
    required this.onSet,
  });
  final TextEditingController seoTitleCtrl, seoDescCtrl, ogImageCtrl;
  final _KV onSet;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '8. SEO',
    'How you appear in search results',
    child: Column(
      children: [
        DiscoveryLabeledField(
          'Search title',
          seoTitleCtrl,
          maxLength: 60,
          onChanged: (v) => onSet('SEO_TITLE', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Search description',
          seoDescCtrl,
          maxLines: 3,
          maxLength: 160,
          onChanged: (v) => onSet('SEO_DESCRIPTION', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Social share image URL (optional)',
          ogImageCtrl,
          onChanged: (v) => onSet('OG_IMAGE', v),
        ),
      ],
    ),
  );
}
