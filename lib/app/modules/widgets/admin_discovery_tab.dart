import 'dart:async';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_fields.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_readonly.dart';
import 'package:raspucat/utils/constants/exports.dart';

class AdminDiscoveryTab extends StatefulWidget {
  const AdminDiscoveryTab({
    super.key,
    required this.ctrl,
    required this.quoteId,
    required this.discoveryData,
    this.submittedAt,
  });
  final AdminController ctrl;
  final String quoteId;
  final Map<String, dynamic> discoveryData;
  final String? submittedAt;

  @override
  State<AdminDiscoveryTab> createState() => _State();
}

class _State extends State<AdminDiscoveryTab> {
  late final Map<String, dynamic> _data;
  Timer? _debounce;
  String _saveStatus = '';

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.discoveryData);
  }

  void _scheduleSave() {
    setState(() => _saveStatus = 'Saving…');
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final err = await widget.ctrl.saveDiscoveryData(widget.quoteId, _data);
      if (!mounted) return;
      setState(() => _saveStatus = err == null ? 'Saved ✓' : 'Error: $err');
      if (err == null) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveStatus = '');
        });
      }
    });
  }

  void _set(String k, dynamic v) {
    _data[k] = v;
    _scheduleSave();
  }

  void _setBrandBrief(String k, String v) {
    final bb = Map<String, dynamic>.from((_data['brand_brief'] as Map<String, dynamic>?) ?? {});
    bb[k] = v;
    _data['brand_brief'] = bb;
    _scheduleSave();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _s(String k) => (_data[k] as String?) ?? '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: ESizes.lg),
          _summaryCard(),
          const SizedBox(height: ESizes.lg),
          _editSection(),
        ],
      ),
    );
  }

  Widget _header() {
    final submitted = widget.submittedAt != null;
    final isError = _saveStatus.startsWith('Error');
    return Row(
      children: [
        Icon(
          submitted ? Icons.check_circle_outline : Icons.hourglass_empty,
          color: submitted ? EColors.primary : EColors.gold,
          size: 18,
        ),
        const SizedBox(width: ESizes.sm),
        Text(
          submitted ? 'Discovery Submitted' : 'Awaiting Discovery',
          style: TextStyle(
            color: submitted ? EColors.primary : EColors.gold,
            fontSize: ESizes.fontSizeSm,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.submittedAt != null) ...[
          const SizedBox(width: ESizes.sm),
          Text(
            _fmtDate(widget.submittedAt!),
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.45),
              fontSize: ESizes.fontSizeLabel,
            ),
          ),
        ],
        const Spacer(),
        if (_saveStatus.isNotEmpty)
          Text(
            _saveStatus,
            style: TextStyle(
              color: isError ? EColors.error : EColors.primary,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _summaryCard() => DiscoverySummaryCard(data: _data);

  Widget _editSection() {
    return DiscoveryFormSection(
      'Admin Overrides',
      'Edit any field — saves automatically after 0.8s',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Personality', 'PERSONALITY'),
          _field('Hero variant', 'HERO_VARIANT'),
          _field('Nav style', 'NAV_STYLE'),
          _field('Short name', 'SHORT_NAME'),
          _field('Primary color', 'COLOR_PRIMARY'),
          _field('Secondary color', 'COLOR_SECONDARY'),
          _field('Accent color', 'COLOR_ACCENT'),
          _field('Surface color', 'COLOR_SURFACE'),
          _field('On-surface color', 'COLOR_ON_SURFACE'),
          _field('Font primary', 'FONT_PRIMARY'),
          _field('Font secondary', 'FONT_SECONDARY'),
          _field('Phone', 'PHONE'),
          _field('Street', 'STREET'),
          _field('City', 'CITY'),
          _field('State', 'STATE'),
          _field('ZIP', 'ZIP'),
          _field('Country', 'COUNTRY'),
          _field('Timezone', 'TIMEZONE'),
          _field('Site URL', 'SITE_URL'),
          _field('SEO title', 'SEO_TITLE'),
          _field('SEO description', 'SEO_DESCRIPTION', maxLines: 3),
          _field('OG image URL', 'OG_IMAGE'),
          const SizedBox(height: ESizes.md),
          DiscoverySubLabel('Brand Brief'),
          const SizedBox(height: ESizes.xs),
          _brandBriefField('3 words', 'three_words'),
          _brandBriefField('Celebrity', 'celebrity'),
          _brandBriefField('Target customer', 'target_customer'),
          _brandBriefField('Inspo URLs', 'inspo_urls'),
        ],
      ),
    );
  }

  Widget _field(String label, String key, {int maxLines = 1}) {
    final ctrl = TextEditingController(text: _s(key));
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: DiscoveryLabeledField(label, ctrl, maxLines: maxLines, onChanged: (v) => _set(key, v)),
    );
  }

  Widget _brandBriefField(String label, String key) {
    final bb = (_data['brand_brief'] as Map<String, dynamic>?) ?? {};
    final ctrl = TextEditingController(text: (bb[key] as String?) ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: DiscoveryLabeledField(label, ctrl, onChanged: (v) => _setBrandBrief(key, v)),
    );
  }

  static String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
