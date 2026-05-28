import 'package:raspucat/app/modules/widgets/portal_discovery_fields.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_readonly.dart';
import 'package:raspucat/utils/constants/exports.dart';
import '_discovery_address_autocomplete.dart';
import '_discovery_upload_field.dart';

// Logo field with prefill preview and URL override input.
// Used by PortalDiscoveryBrandBriefSection in _portal_discovery_sections.dart.
class DiscoveryLogoField extends StatefulWidget {
  const DiscoveryLogoField({
    super.key,
    required this.logoUrl,
    required this.prefillLogoUrl,
    required this.onLogoUpload,
    this.onLogoUrlChanged,
  });
  final String? logoUrl;
  final String? prefillLogoUrl;
  final Future<String?> Function(String, String, String) onLogoUpload;
  final ValueChanged<String>? onLogoUrlChanged;

  @override
  State<DiscoveryLogoField> createState() => _DiscoveryLogoFieldState();
}

class _DiscoveryLogoFieldState extends State<DiscoveryLogoField> {
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.logoUrl ?? widget.prefillLogoUrl ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  static const _hintStyle = TextStyle(
    color: Color(0x99A0A0B0),
    fontSize: ESizes.fontSizeLabel,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    final detected = (widget.prefillLogoUrl ?? '').isNotEmpty && _urlCtrl.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detected)
          ClipRRect(
            borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
            child: Image.network(
              _urlCtrl.text,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: ESizes.xs),
        Text(
          detected
              ? 'This logo was detected from your website. Confirm it or paste a replacement URL.'
              : 'No logo detected — paste your logo URL below, or upload a file.',
          style: _hintStyle,
        ),
        const SizedBox(height: ESizes.xs),
        DiscoveryLabeledField(
          'Logo URL',
          _urlCtrl,
          hint: 'https://yoursite.com/logo.png',
          onChanged: (v) => widget.onLogoUrlChanged?.call(v),
        ),
        const SizedBox(height: ESizes.xs),
        DiscoveryUploadField(
          label: 'Or upload a file',
          hint: 'PNG, JPG or SVG — used for your favicon and app icon',
          currentUrl: null,
          accept: 'image/png,image/jpeg,image/svg+xml,image/webp',
          onUpload: widget.onLogoUpload,
        ),
      ],
    );
  }
}

typedef _KV = void Function(String key, String value);

class PortalDiscoveryBusinessInfoSection extends StatelessWidget {
  const PortalDiscoveryBusinessInfoSection({
    required this.phoneCtrl,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.zipCtrl,
    required this.countryCtrl,
    required this.days,
    required this.hours,
    required this.onSet,
    required this.onAddressSelected,
    required this.onHoursChanged,
  });
  final TextEditingController phoneCtrl, streetCtrl, cityCtrl, stateCtrl, zipCtrl, countryCtrl;
  final List<String> days;
  final Map<String, Map<String, dynamic>> hours;
  final _KV onSet;
  final ValueChanged<NominatimResult> onAddressSelected;
  final VoidCallback onHoursChanged;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '6. Business Info',
    null,
    child: Column(
      children: [
        DiscoveryLabeledField(
          'Phone number',
          phoneCtrl,
          hint: 'e.g. (512) 555-0100',
          onChanged: (v) => onSet('PHONE', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryAddressAutocomplete(controller: streetCtrl, onAddressSelected: onAddressSelected),
        const SizedBox(height: ESizes.sm),
        Row(
          children: [
            Expanded(
              child: DiscoveryLabeledField(
                'City',
                cityCtrl,
                hint: 'e.g. Austin',
                onChanged: (v) => onSet('CITY', v),
              ),
            ),
            const SizedBox(width: ESizes.sm),
            SizedBox(
              width: 80,
              child: DiscoveryLabeledField(
                'State',
                stateCtrl,
                hint: 'e.g. TX',
                onChanged: (v) => onSet('STATE', v),
              ),
            ),
            const SizedBox(width: ESizes.sm),
            SizedBox(
              width: 90,
              child: DiscoveryLabeledField(
                'ZIP',
                zipCtrl,
                hint: 'e.g. 78701',
                onChanged: (v) => onSet('ZIP', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Country',
          countryCtrl,
          hint: 'e.g. United States',
          onChanged: (v) => onSet('COUNTRY', v),
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

class PortalDiscoverySocialSection extends StatelessWidget {
  const PortalDiscoverySocialSection({
    required this.fromEmailCtrl,
    required this.instagramCtrl,
    required this.facebookCtrl,
    required this.tiktokCtrl,
    required this.youtubeCtrl,
    required this.onSet,
  });
  final TextEditingController fromEmailCtrl, instagramCtrl, facebookCtrl, tiktokCtrl, youtubeCtrl;
  final _KV onSet;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '9. Social & Contact',
    'Optional — helps us wire up links and contact forms on your site.',
    child: Column(
      children: [
        DiscoveryLabeledField(
          'Business reply-to email',
          fromEmailCtrl,
          hint: 'hello@yourbusiness.com',
          onChanged: (v) => onSet('FROM_EMAIL', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Instagram',
          instagramCtrl,
          hint: 'https://instagram.com/yourbusiness',
          onChanged: (v) => onSet('INSTAGRAM_URL', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Facebook',
          facebookCtrl,
          hint: 'https://facebook.com/yourbusiness',
          onChanged: (v) => onSet('FACEBOOK_URL', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'TikTok',
          tiktokCtrl,
          hint: 'https://tiktok.com/@yourbusiness',
          onChanged: (v) => onSet('TIKTOK_URL', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'YouTube',
          youtubeCtrl,
          hint: 'https://youtube.com/@yourbusiness',
          onChanged: (v) => onSet('YOUTUBE_URL', v),
        ),
      ],
    ),
  );
}

class PortalDiscoverySeoSection extends StatelessWidget {
  const PortalDiscoverySeoSection({
    required this.seoTitleCtrl,
    required this.seoDescCtrl,
    required this.ogImageUrl,
    required this.onOgImageUpload,
    required this.onSet,
  });
  final TextEditingController seoTitleCtrl, seoDescCtrl;
  final String? ogImageUrl;
  final Future<String?> Function(String, String, String) onOgImageUpload;
  final _KV onSet;

  @override
  Widget build(BuildContext context) => DiscoveryFormSection(
    '8. SEO & Search',
    'How your site appears in Google and when shared on social media',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscoveryLabeledField(
          'Search title',
          seoTitleCtrl,
          hint: 'e.g. Austin\'s Best Barber Shop | Clean Cuts',
          maxLength: 60,
          onChanged: (v) => onSet('SEO_TITLE', v),
        ),
        const SizedBox(height: ESizes.sm),
        DiscoveryLabeledField(
          'Search description',
          seoDescCtrl,
          hint: 'A short sentence about your business that appears under your link in Google.',
          maxLines: 3,
          maxLength: 160,
          onChanged: (v) => onSet('SEO_DESCRIPTION', v),
        ),
        const SizedBox(height: ESizes.md),
        DiscoveryUploadField(
          label: 'Social share image (optional)',
          hint:
              'The image that shows up when someone shares your link on Facebook, iMessage, or Instagram. Ideal size: 1200 × 630 px.',
          currentUrl: ogImageUrl,
          accept: 'image/png,image/jpeg,image/webp',
          onUpload: onOgImageUpload,
        ),
      ],
    ),
  );
}
