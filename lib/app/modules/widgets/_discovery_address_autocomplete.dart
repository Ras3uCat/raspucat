import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:raspucat/utils/constants/exports.dart';

class NominatimResult {
  const NominatimResult({
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    this.timezone,
    required this.displayName,
  });

  final String street;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String? timezone;
  final String displayName;
}

class DiscoveryAddressAutocomplete extends StatefulWidget {
  const DiscoveryAddressAutocomplete({
    required this.controller,
    required this.onAddressSelected,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<NominatimResult> onAddressSelected;

  @override
  State<DiscoveryAddressAutocomplete> createState() => _State();
}

class _State extends State<DiscoveryAddressAutocomplete> {
  static const _stateTimezones = {
    'Alabama': 'America/Chicago',
    'Alaska': 'America/Anchorage',
    'Arizona': 'America/Phoenix',
    'Arkansas': 'America/Chicago',
    'California': 'America/Los_Angeles',
    'Colorado': 'America/Denver',
    'Connecticut': 'America/New_York',
    'Delaware': 'America/New_York',
    'Florida': 'America/New_York',
    'Georgia': 'America/New_York',
    'Hawaii': 'Pacific/Honolulu',
    'Idaho': 'America/Denver',
    'Illinois': 'America/Chicago',
    'Indiana': 'America/Indiana/Indianapolis',
    'Iowa': 'America/Chicago',
    'Kansas': 'America/Chicago',
    'Kentucky': 'America/New_York',
    'Louisiana': 'America/Chicago',
    'Maine': 'America/New_York',
    'Maryland': 'America/New_York',
    'Massachusetts': 'America/New_York',
    'Michigan': 'America/Detroit',
    'Minnesota': 'America/Chicago',
    'Mississippi': 'America/Chicago',
    'Missouri': 'America/Chicago',
    'Montana': 'America/Denver',
    'Nebraska': 'America/Chicago',
    'Nevada': 'America/Los_Angeles',
    'New Hampshire': 'America/New_York',
    'New Jersey': 'America/New_York',
    'New Mexico': 'America/Denver',
    'New York': 'America/New_York',
    'North Carolina': 'America/New_York',
    'North Dakota': 'America/Chicago',
    'Ohio': 'America/New_York',
    'Oklahoma': 'America/Chicago',
    'Oregon': 'America/Los_Angeles',
    'Pennsylvania': 'America/New_York',
    'Rhode Island': 'America/New_York',
    'South Carolina': 'America/New_York',
    'South Dakota': 'America/Chicago',
    'Tennessee': 'America/Chicago',
    'Texas': 'America/Chicago',
    'Utah': 'America/Denver',
    'Vermont': 'America/New_York',
    'Virginia': 'America/New_York',
    'Washington': 'America/Los_Angeles',
    'West Virginia': 'America/New_York',
    'Wisconsin': 'America/Chicago',
    'Wyoming': 'America/Denver',
  };

  Timer? _debounce;
  OverlayEntry? _overlay;
  final _layerLink = LayerLink();
  List<NominatimResult> _suggestions = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.length < 4) {
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=jsonv2&addressdetails=1&limit=5&countrycodes=us&q=${Uri.encodeComponent(q)}',
      );
      final resp = await http.get(uri, headers: {'User-Agent': 'Raspucat/1.0'});
      if (!mounted) return;
      final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      _suggestions = list.map(_parse).whereType<NominatimResult>().toList();
    } catch (_) {
      _suggestions = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (_suggestions.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  NominatimResult? _parse(Map<String, dynamic> raw) {
    final addr = raw['address'] as Map<String, dynamic>?;
    if (addr == null) return null;
    final houseNumber = addr['house_number'] as String? ?? '';
    final road = addr['road'] as String? ?? '';
    final street = [houseNumber, road].where((s) => s.isNotEmpty).join(' ');
    final city =
        (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['hamlet'] ?? '') as String;
    final state = (addr['state'] ?? '') as String;
    final zip = (addr['postcode'] ?? '') as String;
    final country = (addr['country'] ?? '') as String;
    if (street.isEmpty && city.isEmpty) return null;
    return NominatimResult(
      street: street,
      city: city,
      state: state,
      zip: zip,
      country: country,
      timezone: _stateTimezones[state],
      displayName: raw['display_name'] as String? ?? '$street, $city',
    );
  }

  void _pick(NominatimResult r) {
    widget.controller.text = r.street;
    _removeOverlay();
    widget.onAddressSelected(r);
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (_) =>
          _SuggestionsDropdown(link: _layerLink, suggestions: _suggestions, onPick: _pick),
    );
    Overlay.of(context).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Street address',
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.5),
            fontSize: ESizes.fontSizeLabel,
          ),
        ),
        const SizedBox(height: 4),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: widget.controller,
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: InputDecoration(
              hintText: 'e.g. 123 Main St',
              hintStyle: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.25),
                fontSize: ESizes.fontSizeSm,
              ),
              suffixIcon: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: EColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: EColors.primary.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ESizes.md,
                vertical: ESizes.sm,
              ),
            ),
            onChanged: _onChanged,
          ),
        ),
      ],
    );
  }
}

class _SuggestionsDropdown extends StatelessWidget {
  const _SuggestionsDropdown({required this.link, required this.suggestions, required this.onPick});

  final LayerLink link;
  final List<NominatimResult> suggestions;
  final ValueChanged<NominatimResult> onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 400,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: const Offset(0, 56),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (_, i) {
                final s = suggestions[i];
                return InkWell(
                  onTap: () => onPick(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 10),
                    child: Text(
                      s.displayName,
                      style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
