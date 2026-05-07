import 'package:raspucat/utils/constants/exports.dart';

// Translates text horizontally as the page scrolls.
// Maps total scroll progress to a horizontal offset of [-maxDrift, 0].
class ScrollXText extends StatefulWidget {
  const ScrollXText({super.key, required this.text, this.style, this.maxDrift = 60.0});

  final String text;
  final TextStyle? style;

  /// Maximum horizontal translation in logical pixels (drifts left).
  final double maxDrift;

  @override
  State<ScrollXText> createState() => _ScrollXTextState();
}

class _ScrollXTextState extends State<ScrollXText> {
  late final ScrollController _sc;

  @override
  void initState() {
    super.initState();
    _sc = EScrollController.instance.scrollController;
    _sc.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _sc.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = _sc.hasClients ? -(_sc.offset * 0.04).clamp(0.0, widget.maxDrift) : 0.0;

    return Transform.translate(
      offset: Offset(offset, 0),
      child: Text(
        widget.text,
        style:
            widget.style ??
            Theme.of(context).textTheme.labelSmall?.copyWith(
              color: EColors.primary.withValues(alpha: 0.4),
              letterSpacing: 4.0,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
