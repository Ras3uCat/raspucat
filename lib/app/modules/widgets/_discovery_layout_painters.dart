import 'package:raspucat/utils/constants/exports.dart';

// CustomPainter implementations for DiscoveryLayoutPicker thumbnails.

// ─── Shared helpers ───────────────────────────────────────────────────────────

Paint _fill(double alpha) => Paint()
  ..color = EColors.primary.withValues(alpha: alpha)
  ..style = PaintingStyle.fill;

Paint _stroke(double alpha, {double width = 1.0}) => Paint()
  ..color = EColors.primary.withValues(alpha: alpha)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round;

void _textLines(
  Canvas c,
  Size s, {
  required double x,
  required double y,
  required double w,
  int count = 3,
  double gap = 5,
  double alpha = 0.35,
}) {
  final p = _fill(alpha);
  for (int i = 0; i < count; i++) {
    final lineW = i == count - 1 ? w * 0.6 : w;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y + i * gap, lineW, 1.5), const Radius.circular(1)),
      p,
    );
  }
}

void _hatch(Canvas c, Size s, double alphaMultiplier) {
  final p = _stroke(0.18 * alphaMultiplier, width: 0.8);
  for (double i = -s.height; i < s.width; i += 10) {
    c.drawLine(Offset(i, 0), Offset(i + s.height, s.height), p);
  }
}

// ─── Hero painters ────────────────────────────────────────────────────────────

class FullbleedPainter extends CustomPainter {
  const FullbleedPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _fill(0.18 * a));
    _hatch(c, s, a);
    c.drawRect(Rect.fromLTWH(0, 0, s.width, 10), _fill(0.45 * a));
    _textLines(
      c,
      s,
      x: s.width * 0.2,
      y: s.height * 0.55,
      w: s.width * 0.6,
      count: 2,
      alpha: 0.7 * a,
    );
  }

  @override
  bool shouldRepaint(FullbleedPainter o) => o.active != active;
}

class SplitPainter extends CustomPainter {
  const SplitPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    final mid = s.width * 0.5;
    c.drawRect(Rect.fromLTWH(0, 0, mid - 2, s.height), _fill(0.18 * a));
    final hatch = _stroke(0.2 * a, width: 0.8);
    for (double i = -s.height; i < mid; i += 8) {
      c.drawLine(Offset(i, 0), Offset(i + s.height, s.height), hatch);
    }
    _textLines(
      c,
      s,
      x: mid + 6,
      y: s.height * 0.25,
      w: s.width * 0.36,
      count: 3,
      gap: 6,
      alpha: 0.6 * a,
    );
    c.drawRect(Rect.fromLTWH(0, 0, s.width, 7), _fill(0.35 * a));
  }

  @override
  bool shouldRepaint(SplitPainter o) => o.active != active;
}

class CenteredPainter extends CustomPainter {
  const CenteredPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _fill(0.04 * a));
    c.drawRect(Rect.fromLTWH(0, 0, s.width, 8), _fill(0.3 * a));
    final bw = s.width * 0.55;
    final bx = (s.width - bw) / 2;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bx, s.height * 0.3, bw, 10), const Radius.circular(2)),
      _fill(0.55 * a),
    );
    _textLines(
      c,
      s,
      x: s.width * 0.25,
      y: s.height * 0.55,
      w: s.width * 0.5,
      count: 2,
      gap: 6,
      alpha: 0.4 * a,
    );
  }

  @override
  bool shouldRepaint(CenteredPainter o) => o.active != active;
}

class VideoBgPainter extends CustomPainter {
  const VideoBgPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _fill(0.12 * a));
    _hatch(c, s, a);
    final cx = s.width / 2, cy = s.height * 0.42;
    c.drawCircle(Offset(cx, cy), 9, _stroke(0.8 * a, width: 1.5));
    final path = Path()
      ..moveTo(cx - 3, cy - 4.5)
      ..lineTo(cx + 5, cy)
      ..lineTo(cx - 3, cy + 4.5)
      ..close();
    c.drawPath(path, _fill(0.7 * a));
    _textLines(
      c,
      s,
      x: s.width * 0.28,
      y: s.height * 0.7,
      w: s.width * 0.44,
      count: 1,
      alpha: 0.6 * a,
    );
  }

  @override
  bool shouldRepaint(VideoBgPainter o) => o.active != active;
}

// ─── Nav style painters ───────────────────────────────────────────────────────

class StickyNavPainter extends CustomPainter {
  const StickyNavPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _fill(0.3 * a));
    c.drawCircle(Offset(14, s.height / 2), 4, _fill(0.9 * a));
    for (int i = 0; i < 3; i++) {
      c.drawCircle(Offset(s.width - 10 - i * 14.0, s.height / 2), 2.5, _fill(0.7 * a));
    }
  }

  @override
  bool shouldRepaint(StickyNavPainter o) => o.active != active;
}

class OverlayNavPainter extends CustomPainter {
  const OverlayNavPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _fill(0.12 * a));
    _hatch(c, s, a);
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _stroke(0.5 * a, width: 1.0));
    c.drawCircle(Offset(14, s.height / 2), 4, _fill(0.85 * a));
    for (int i = 0; i < 3; i++) {
      c.drawCircle(Offset(s.width - 10 - i * 14.0, s.height / 2), 2.5, _fill(0.65 * a));
    }
  }

  @override
  bool shouldRepaint(OverlayNavPainter o) => o.active != active;
}

class MinimalNavPainter extends CustomPainter {
  const MinimalNavPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _fill(0.04 * a));
    c.drawLine(
      Offset(0, s.height - 1),
      Offset(s.width, s.height - 1),
      _stroke(0.5 * a, width: 1.0),
    );
    c.drawCircle(Offset(s.width / 2, s.height / 2), 4, _fill(0.8 * a));
  }

  @override
  bool shouldRepaint(MinimalNavPainter o) => o.active != active;
}

class HamburgerNavPainter extends CustomPainter {
  const HamburgerNavPainter(this.active);
  final bool active;

  @override
  void paint(Canvas c, Size s) {
    final a = active ? 1.0 : 0.25;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), _fill(0.3 * a));
    c.drawCircle(Offset(14, s.height / 2), 4, _fill(0.9 * a));
    final p = _stroke(0.9 * a, width: 2.0);
    final rx = s.width - 18.0;
    final cy = s.height / 2;
    for (final dy in [-5.0, 0.0, 5.0]) {
      c.drawLine(Offset(rx - 8, cy + dy), Offset(rx, cy + dy), p);
    }
  }

  @override
  bool shouldRepaint(HamburgerNavPainter o) => o.active != active;
}
