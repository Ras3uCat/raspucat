import 'dart:async';
import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/app/modules/widgets/_portal_discovery_sections.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_readonly.dart';
import 'package:raspucat/utils/constants/exports.dart';

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
  final _ogImage = TextEditingController();
  late final Map<String, Map<String, dynamic>> _hours;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _personalities = [
    ('luxury', 'Luxury & refined'),
    ('bold', 'Bold & confident'),
    ('warm', 'Warm & welcoming'),
    ('minimal', 'Clean & minimal'),
    ('corporate', 'Professional'),
    ('edgy', 'Edgy & urban'),
    ('playful', 'Playful & entertaining'),
    ('artisan', 'Artisan & handcrafted'),
    ('wellness', 'Wellness & holistic'),
    ('tech', 'Tech & modern'),
    ('retro', 'Retro & nostalgic'),
    ('nature', 'Nature & eco'),
    ('creative', 'Creative & expressive'),
    ('nightlife', 'Nightlife & dining'),
  ];
  static const _heroVariants = [
    ('fullbleed', 'Full bleed image'),
    ('split', 'Image + text side by side'),
    ('centered', 'Centered'),
    ('video_bg', 'Video background'),
  ];
  static const _navStyles = [
    ('sticky', 'Sticky top bar'),
    ('overlay', 'Transparent overlay'),
    ('minimal', 'Minimal'),
    ('hamburger', 'Hamburger menu'),
  ];
  static const _timezones = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Phoenix',
    'America/Anchorage',
    'Pacific/Honolulu',
    'UTC',
  ];

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
    _ogImage.text = s('OG_IMAGE');
    final sh = (_data['HOURS_JSON'] as Map<String, dynamic>?) ?? {};
    _hours = {
      for (final d in _days)
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

  void _updateHours() {
    _data['HOURS_JSON'] = {
      for (final d in _days)
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
      _ogImage,
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
              personalities: _personalities,
              selected: _data['PERSONALITY'] as String?,
              onChanged: (v) => setState(() => _set('PERSONALITY', v)),
            ),
            PortalDiscoveryLayoutSection(
              heroVariants: _heroVariants,
              navStyles: _navStyles,
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
              timezones: _timezones,
              timezone: _data['TIMEZONE'] as String?,
              days: _days,
              hours: _hours,
              onSet: _set,
              onTimezoneChanged: (v) => setState(() => _set('TIMEZONE', v)),
              onHoursChanged: () => setState(_updateHours),
            ),
            PortalDiscoveryOnlinePresenceSection(siteUrlCtrl: _siteUrl, onSet: _set),
            PortalDiscoverySeoSection(
              seoTitleCtrl: _seoTitle,
              seoDescCtrl: _seoDesc,
              ogImageCtrl: _ogImage,
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
