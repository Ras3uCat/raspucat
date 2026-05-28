import 'dart:async';
import 'package:raspucat/app/modules/widgets/_discovery_address_autocomplete.dart';
import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/app/modules/widgets/_portal_discovery_form_logic.dart';
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
  late final Map<String, Map<String, dynamic>> _hours = {};
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

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.quote.discoveryData);
    _submitted = widget.quote.discoverySubmitted;
    if (_data.isEmpty && widget.quote.discoveryPrefill.isNotEmpty) {
      DiscoveryFormLogic.applyPrefill(_data, widget.quote.discoveryPrefill);
    }
    DiscoveryFormLogic.populateControllers(
      data: _data,
      hours: _hours,
      shortName: _shortName,
      colorPri: _colorPri,
      colorSec: _colorSec,
      colorAcc: _colorAcc,
      colorSurf: _colorSurf,
      colorOn: _colorOn,
      fontPri: _fontPri,
      fontSec: _fontSec,
      threeWords: _threeWords,
      celebrity: _celebrity,
      inspoUrls: _inspoUrls,
      targetCust: _targetCust,
      phone: _phone,
      street: _street,
      city: _city,
      stateCtrl: _stateCtrl,
      zip: _zip,
      country: _country,
      siteUrl: _siteUrl,
      seoTitle: _seoTitle,
      seoDesc: _seoDesc,
      fromEmail: _fromEmail,
      instagram: _instagram,
      facebook: _facebook,
      tiktok: _tiktok,
      youtube: _youtube,
    );
  }

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
    final changes = DiscoveryFormLogic.computeChanges(_data, widget.quote);
    final ok = await _ctrl.submitDiscovery(_data, discoveryChanges: changes);
    if (mounted)
      setState(() {
        _submitting = false;
        _submitted = ok;
      });
  }

  bool get _canSubmit => (_data['PERSONALITY'] as String?)?.isNotEmpty == true;

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
              prefillLogoUrl: widget.quote.discoveryPrefill['logo_url'] as String?,
              onLogoUpload: (b, m, f) => _uploadAsset('logo', b, m, f),
              onLogoUrlChanged: (url) => _set('LOGO_URL', url),
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
