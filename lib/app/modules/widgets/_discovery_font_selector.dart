import 'package:raspucat/utils/constants/exports.dart';
import 'portal_discovery_fields.dart';

class DiscoveryFontSelector extends StatefulWidget {
  const DiscoveryFontSelector({
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<DiscoveryFontSelector> createState() => _DiscoveryFontSelectorState();
}

class _DiscoveryFontSelectorState extends State<DiscoveryFontSelector> {
  static final _allFonts = GoogleFonts.asMap().keys.toList()..sort();

  OverlayEntry? _overlay;
  final _layerLink = LayerLink();
  List<String> _filtered = [];

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _onChanged(String q) {
    widget.onChanged(q);
    final lower = q.toLowerCase();
    _filtered = q.isEmpty
        ? []
        : _allFonts.where((f) => f.toLowerCase().contains(lower)).take(8).toList();
    if (_filtered.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _pick(String font) {
    widget.controller.text = font;
    widget.onChanged(font);
    _removeOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (_) => _FontDropdown(link: _layerLink, fonts: _filtered, onPick: _pick),
    );
    overlay.insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: DiscoveryLabeledField(
        widget.label,
        widget.controller,
        hint: 'e.g. Inter, Playfair Display',
        onChanged: _onChanged,
      ),
    );
  }
}

class _FontDropdown extends StatelessWidget {
  const _FontDropdown({required this.link, required this.fonts, required this.onPick});

  final LayerLink link;
  final List<String> fonts;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 300,
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
              itemCount: fonts.length,
              itemBuilder: (_, i) => InkWell(
                onTap: () => onPick(fonts[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 10),
                  child: Text(
                    fonts[i],
                    style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
