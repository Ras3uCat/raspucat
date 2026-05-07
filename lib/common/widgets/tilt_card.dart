import 'package:raspucat/utils/constants/exports.dart';

// 3D perspective tilt on hover. Max tilt: ±[maxTiltDeg]° on each axis.
// During hover: immediate Transform (no animation). Exit: 300ms easeOutCubic.
// On touch/non-pointer devices the child is rendered flat.
class TiltCard extends StatefulWidget {
  const TiltCard({super.key, required this.child, this.maxTiltDeg = 8.0});

  final Widget child;
  final double maxTiltDeg;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rx = 0;
  double _ry = 0;
  bool _hovered = false;

  void _onHover(PointerEvent event, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const degToRad = 3.14159265358979 / 180;
    final maxRad = widget.maxTiltDeg * degToRad;
    setState(() {
      _ry = ((event.localPosition.dx - cx) / cx) * maxRad;
      _rx = -((event.localPosition.dy - cy) / cy) * maxRad;
    });
  }

  void _onExit() => setState(() {
    _rx = 0;
    _ry = 0;
    _hovered = false;
  });

  Matrix4 get _transform => Matrix4.identity()
    ..setEntry(3, 2, 0.001)
    ..rotateX(_rx)
    ..rotateY(_ry);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onHover: (e) => _onHover(e, size),
          onExit: (_) => _onExit(),
          child: _hovered
              ? Transform(transform: _transform, alignment: Alignment.center, child: widget.child)
              : TweenAnimationBuilder<Matrix4>(
                  tween: Matrix4Tween(begin: _transform, end: Matrix4.identity()),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (_, matrix, child) =>
                      Transform(transform: matrix, alignment: Alignment.center, child: child),
                  child: widget.child,
                ),
        );
      },
    );
  }
}
