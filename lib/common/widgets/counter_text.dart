import 'package:raspucat/utils/constants/exports.dart';

// Animates an integer from 0 → [value] over 1.6s cubic easeOut when the
// widget enters the viewport at ≥50% visibility.
// Requires visibility_detector (already in pubspec).
class CounterText extends StatefulWidget {
  const CounterText({super.key, required this.value, required this.suffix, this.style});

  final int value;

  /// Appended after the number, e.g. "%" or "+".
  final String suffix;
  final TextStyle? style;

  @override
  State<CounterText> createState() => _CounterTextState();
}

class _CounterTextState extends State<CounterText> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _count;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _count = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_started && info.visibleFraction >= 0.5) {
      _started = true;
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('counter_${widget.value}_${widget.suffix}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedBuilder(
        animation: _count,
        builder: (_, __) => Text(
          '${_count.value}${widget.suffix}',
          style:
              widget.style ??
              Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: EColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
        ),
      ),
    );
  }
}
