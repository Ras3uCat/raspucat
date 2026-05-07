import 'package:raspucat/utils/constants/exports.dart';

// Gently drifts child toward the cursor when hovered within [triggerRadius].
// Enter: 60ms linear. Exit: 300ms easeOutCubic. Max drift: [maxDisplace]px.
class MagneticWidget extends StatefulWidget {
  const MagneticWidget({
    super.key,
    required this.child,
    this.triggerRadius = 80.0,
    this.maxDisplace = 12.0,
  });

  final Widget child;
  final double triggerRadius;
  final double maxDisplace;

  @override
  State<MagneticWidget> createState() => _MagneticWidgetState();
}

class _MagneticWidgetState extends State<MagneticWidget> {
  final _key = GlobalKey();
  Offset _target = Offset.zero;
  bool _hovered = false;

  Size get _size {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    return box?.size ?? Size.zero;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      key: _key,
      onHover: (event) {
        final size = _size;
        final center = Offset(size.width / 2, size.height / 2);
        final delta = event.localPosition - center;
        if (delta.distance < widget.triggerRadius) {
          setState(() {
            _target = Offset(
              (delta.dx / widget.triggerRadius) * widget.maxDisplace,
              (delta.dy / widget.triggerRadius) * widget.maxDisplace,
            );
            _hovered = true;
          });
        }
      },
      onExit: (_) => setState(() {
        _target = Offset.zero;
        _hovered = false;
      }),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: _target),
        duration: _hovered ? const Duration(milliseconds: 60) : const Duration(milliseconds: 300),
        curve: _hovered ? Curves.linear : Curves.easeOutCubic,
        builder: (_, offset, child) => Transform.translate(offset: offset, child: child),
        child: widget.child,
      ),
    );
  }
}
