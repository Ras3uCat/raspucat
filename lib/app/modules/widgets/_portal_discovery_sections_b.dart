import 'package:raspucat/app/modules/widgets/portal_discovery_fields.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_readonly.dart';
import 'package:raspucat/utils/constants/exports.dart';

typedef _KV = void Function(String key, String value);

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
