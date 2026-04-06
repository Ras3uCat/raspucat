import 'dart:async';
import 'package:raspucat/app/modules/widgets/_discovery_address_autocomplete.dart';
import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/app/modules/widgets/_portal_discovery_sections.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_readonly.dart';
import 'package:raspucat/utils/constants/exports.dart';
import '_discovery_form_constants.dart';

class PortalDiscoveryForm extends StatefulWidget {
  const PortalDiscoveryForm({super.key, required this.quote});
  final PortalQuote quote;
  @override
  State<PortalDiscoveryForm> createState() => _State();
}

class _State extends State<PortalDiscoveryForm> {
  final _ctrl = Get.find<PortalController>();
  late final Map<String, dynamic> _data;
  Timer? _debounce;
  bool _submitting = false;
  bool _submitted = false;

  final _shortName = TextEditingController();
  final _colorPri = TextEditingController();
  final _colorSec = TextEditingController();
  final _colorAcc = TextEditingController();
  final _colorSurf = TextEditingController();
  final _colorOn = TextEditingController();
  final _fontPri = TextEditingController();
  final _fontSec = TextEditingController();
  final _threeWords = TextEditingController();
  final _celebrity = TextEditingController();
  final _inspoUrls = TextEditingController();
  final _targetCust = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController();
  final _siteUrl = TextEditingController();
  final _seoTitle = TextEditingController();
  final _seoDesc = TextEditingController();
  final _fromEmail = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();
  final _tiktok = TextEditingController();
  final _youtube = TextEditingController();
  late final Map<String, Map<String, dynamic>> _hours;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.quote.discoveryData);
    _submitted = widget.quote.discoverySubmitted;
    _initControllers();
  }

  void _initControllers() {
    String s(String k) => (_data[k] as String?) ?? '';
    _shortName.text = s('SHORT_NAME');
    _colorPri.text = s('COLOR_PRIMARY');
    _colorSec.text = s('COLOR_SECONDARY');
    _colorAcc.text = s('COLOR_ACCENT');
    _colorSurf.text = s('COLOR_SURFACE');
    _colorOn.text = s('COLOR_ON_SURFACE');
    _fontPri.text = s('FONT_PRIMARY');
    _fontSec.text = s('FONT_SECONDARY');
    final bb = (_data['brand_brief'] as Map<String, dynamic>?) ?? {};
    _threeWords.text = (bb['three_words'] as String?) ?? '';
    _celebrity.text = (bb['celebrity'] as String?) ?? '';
    _inspoUrls.text = (bb['inspo_urls'] as String?) ?? '';
    _targetCust.text = (bb['target_customer'] as String?) ?? '';
    _phone.text = s('PHONE');
    _street.text = s('STREET');
    _city.text = s('CITY');
    _stateCtrl.text = s('STATE');
    _zip.text = s('ZIP');
    _country.text = s('COUNTRY');
    _siteUrl.text = s('SITE_URL');
    _seoTitle.text = s('SEO_TITLE');
    _seoDesc.text = s('SEO_DESCRIPTION');
    _fromEmail.text = s('FROM_EMAIL');
    _instagram.text = s('INSTAGRAM_URL');
    _facebook.text = s('FACEBOOK_URL');
    _tiktok.text = s('TIKTOK_URL');
    _youtube.text = s('YOUTUBE_URL');
    final sh = (_data['HOURS_JSON'] as Map<String, dynamic>?) ?? {};
    _hours = {
      for (final d in discoveryDays)
        d: {
          'open': (sh[d.toLowerCase()]?['open'] as String?) ?? '9:00 AM',
          'close': (sh[d.toLowerCase()]?['close'] as String?) ?? '5:00 PM',
          'closed': (sh[d.toLowerCase()]?['closed'] as bool?) ?? false,
        },
    };
  }

  void _draft() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _ctrl.saveDiscoveryDraft(_data));
  }

  void _set(String k, dynamic v) {
    _data[k] = v;
    _draft();
  }

  void _setBrandBrief(String k, String v) {
    final bb = Map<String, dynamic>.from((_data['brand_brief'] as Map<String, dynamic>?) ?? {});
    bb[k] = v;
    _data['brand_brief'] = bb;
    _draft();
  }

  Future<String?> _uploadAsset(
    String field,
    String base64,
    String mimeType,
    String fileName,
  ) async {
    try {
      final url = await _ctrl.uploadDiscoveryAsset(
        widget.quote.id,
        field,
        base64,
        mimeType,
        fileName,
      );
      _set(field == 'logo' ? 'LOGO_URL' : 'OG_IMAGE', url);
      return url;
    } catch (e) {
      // Return the error as a special sentinel so DiscoveryUploadField can show it.
      return 'ERR:$e';
    }
  }

  void _onAddressSelected(NominatimResult r) {
    _street.text = r.street;
    _city.text = r.city;
    _stateCtrl.text = r.state;
    _zip.text = r.zip;
    _country.text = r.country;
    _set('STREET', r.street);
    _set('CITY', r.city);
    _set('STATE', r.state);
    _set('ZIP', r.zip);
    _set('COUNTRY', r.country);
    if (r.timezone != null) _set('TIMEZONE', r.timezone!);
  }

  void _updateHours() {
    _data['HOURS_JSON'] = {
      for (final d in discoveryDays)
        d.toLowerCase(): {
          'open': _hours[d]!['open'],
          'close': _hours[d]!['close'],
          'closed': _hours[d]!['closed'],
        },
    };
    _draft();
  }

  Future<void> _submit() async {
    if (_submitting || !_canSubmit) return;
    setState(() => _submitting = true);
    final ok = await _ctrl.submitDiscovery(_data);
    if (mounted)
      setState(() {
        _submitting = false;
        _submitted = ok;
      });
  }

  bool get _canSubmit => (_data['PERSONALITY'] as String?)?.isNotEmpty == true;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _shortName,
      _colorPri,
      _colorSec,
      _colorAcc,
      _colorSurf,
      _colorOn,
      _fontPri,
      _fontSec,
      _threeWords,
      _celebrity,
      _inspoUrls,
      _targetCust,
      _phone,
      _street,
      _city,
      _stateCtrl,
      _zip,
      _country,
      _siteUrl,
      _seoTitle,
      _seoDesc,
      _fromEmail,
      _instagram,
      _facebook,
      _tiktok,
      _youtube,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return DiscoveryReadOnlyView(data: _data);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DiscoveryIntro(businessName: widget.quote.businessName),
            const SizedBox(height: ESizes.xl),
            PortalDiscoveryPersonalitySection(
              personalities: discoveryPersonalities,
              selected: _data['PERSONALITY'] as String?,
              onChanged: (v) => setState(() => _set('PERSONALITY', v)),
            ),
            PortalDiscoveryLayoutSection(
              heroVariants: discoveryHeroVariants,
              navStyles: discoveryNavStyles,
              heroVariant: _data['HERO_VARIANT'] as String?,
              navStyle: _data['NAV_STYLE'] as String?,
              onHeroChanged: (v) => setState(() => _set('HERO_VARIANT', v)),
              onNavChanged: (v) => setState(() => _set('NAV_STYLE', v)),
            ),
            PortalDiscoveryColorsSection(
              primaryCtrl: _colorPri,
              secondaryCtrl: _colorSec,
              accentCtrl: _colorAcc,
              surfaceCtrl: _colorSurf,
              onSurfaceCtrl: _colorOn,
              onSet: _set,
            ),
            PortalDiscoveryFontsSection(
              primaryCtrl: _fontPri,
              secondaryCtrl: _fontSec,
              onSet: _set,
            ),
            PortalDiscoveryBrandBriefSection(
              shortNameCtrl: _shortName,
              logoUrl: _data['LOGO_URL'] as String?,
              onLogoUpload: (b, m, f) => _uploadAsset('logo', b, m, f),
              threeWordsCtrl: _threeWords,
              celebrityCtrl: _celebrity,
              targetCustCtrl: _targetCust,
              inspoUrlsCtrl: _inspoUrls,
              onSet: _set,
              onBrandBrief: _setBrandBrief,
            ),
            PortalDiscoveryBusinessInfoSection(
              phoneCtrl: _phone,
              streetCtrl: _street,
              cityCtrl: _city,
              stateCtrl: _stateCtrl,
              zipCtrl: _zip,
              countryCtrl: _country,
              days: discoveryDays,
              hours: _hours,
              onSet: _set,
              onAddressSelected: _onAddressSelected,
              onHoursChanged: () => setState(_updateHours),
            ),
            PortalDiscoveryOnlinePresenceSection(siteUrlCtrl: _siteUrl, onSet: _set),
            PortalDiscoverySeoSection(
              seoTitleCtrl: _seoTitle,
              seoDescCtrl: _seoDesc,
              ogImageUrl: _data['OG_IMAGE'] as String?,
              onOgImageUpload: (b, m, f) => _uploadAsset('og_image', b, m, f),
              onSet: _set,
            ),
            PortalDiscoverySocialSection(
              fromEmailCtrl: _fromEmail,
              instagramCtrl: _instagram,
              facebookCtrl: _facebook,
              tiktokCtrl: _tiktok,
              youtubeCtrl: _youtube,
              onSet: _set,
            ),
            const SizedBox(height: ESizes.xl),
            DiscoverySubmitButton(canSubmit: _canSubmit, submitting: _submitting, onTap: _submit),
            const SizedBox(height: ESizes.xl),
          ],
        ),
      ),
    );
  }
}
