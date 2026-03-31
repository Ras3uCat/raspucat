import 'dart:ui';
import 'package:flutter/material.dart';

/// Morphs 3 hamburger lines into an upward-pointing triangle.
///
/// [t] = 0.0 → hamburger (3 horizontal lines)
/// [t] = 1.0 → triangle (3 sides, filled + glowing)
///
/// Line → side mapping:
///   Line 1 (top)    → left side  (apex → bottom-left)
///   Line 2 (middle) → right side (apex → bottom-right)
///   Line 3 (bottom) → base       (bottom-left → bottom-right)
class HamburgerTrianglePainter extends CustomPainter {
  final double t;
  final Color color;

  const HamburgerTrianglePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // --- Hamburger anchor points (normalised, t=0) ---
    final hx1 = size.width * 0.15;
    final hx2 = size.width * 0.85;
    final hy1 = size.height * 0.25; // top line
    final hy2 = size.height * 0.50; // middle line
    final hy3 = size.height * 0.75; // bottom line

    // --- Triangle vertices (t=1) — upward-pointing ---
    final tTopX = cx;
    final tTopY = cy - r;
    final tBLX = cx - r;
    final tBLY = cy + r * 0.6;
    final tBRX = cx + r;
    final tBRY = cy + r * 0.6;

    // --- Lerped endpoints ---
    final l1p1 = Offset(
      lerpDouble(hx1, tTopX, t)!,
      lerpDouble(hy1, tTopY, t)!,
    );
    final l1p2 = Offset(
      lerpDouble(hx2, tBLX, t)!,
      lerpDouble(hy1, tBLY, t)!,
    );

    final l2p1 = Offset(
      lerpDouble(hx1, tTopX, t)!,
      lerpDouble(hy2, tTopY, t)!,
    );
    final l2p2 = Offset(
      lerpDouble(hx2, tBRX, t)!,
      lerpDouble(hy2, tBRY, t)!,
    );

    final l3p1 = Offset(
      lerpDouble(hx1, tBLX, t)!,
      lerpDouble(hy3, tBLY, t)!,
    );
    final l3p2 = Offset(
      lerpDouble(hx2, tBRX, t)!,
      lerpDouble(hy3, tBRY, t)!,
    );

    final sw = lerpDouble(2.0, 1.5, t)!;

    // --- Fill fades in at t > 0.7 ---
    if (t > 0.7) {
      final fillT = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
      final triPath = Path()
        ..moveTo(l1p1.dx, l1p1.dy)
        ..lineTo(l3p1.dx, l3p1.dy)
        ..lineTo(l3p2.dx, l3p2.dy)
        ..close();

      if (t > 0.85) {
        final glowT = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
        canvas.drawPath(
          triPath,
          Paint()
            ..color = color.withValues(alpha:glowT * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      canvas.drawPath(
        triPath,
        Paint()
          ..color = color.withValues(alpha:fillT * 0.5)
          ..style = PaintingStyle.fill,
      );
    }

    // --- Stroke glow fades in at t > 0.7 ---
    if (t > 0.7) {
      final glowT = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
      final glow = Paint()
        ..color = color.withValues(alpha:glowT * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(l1p1, l1p2, glow);
      canvas.drawLine(l2p1, l2p2, glow);
      canvas.drawLine(l3p1, l3p2, glow);
    }

    // --- Lines ---
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(l1p1, l1p2, stroke);
    canvas.drawLine(l2p1, l2p2, stroke);
    canvas.drawLine(l3p1, l3p2, stroke);
  }

  @override
  bool shouldRepaint(HamburgerTrianglePainter old) =>
      old.t != t || old.color != color;
}
