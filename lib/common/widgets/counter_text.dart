import 'package:flutter/scheduler.dart';
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
  late Animation<int> _count;
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

  double _visibleFraction = 0.0;

  @override
  void didUpdateWidget(CounterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value > 0) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _count = IntTween(
            begin: 0,
            end: widget.value,
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
        });
        if (_visibleFraction >= 0.5) {
          _started = true;
          _ctrl
            ..reset()
            ..forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _visibleFraction = info.visibleFraction;
    
    if (info.visibleFraction == 0 && _started) {
      if (!mounted) return;
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.attached) {
        final position = renderBox.localToGlobal(Offset.zero);
        if (position.dy > 0) {
          // Widget exited from the bottom
          _started = false;
          _ctrl.reset();
        }
      }
    } else if (!_started && widget.value > 0 && info.visibleFraction >= 0.5) {
      _started = true;
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? Key('counter_${widget.suffix}'),
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
