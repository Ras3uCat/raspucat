import 'package:flutter/scheduler.dart' show Ticker;
import 'package:raspucat/utils/constants/exports.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show document;

// Global signal — interactive widgets (buttons, links) flip this on enter/exit.
// The cursor painter reads it to toggle between idle and hover ring sizes.
class CursorState {
  CursorState._();
  static final isInteractive = ValueNotifier<bool>(false);
  static final position = ValueNotifier<Offset>(Offset.zero);
}

// Web-only branded cursor: small dot at exact position + lagging ring.
// Ring expands from 7px → 23px on interactive elements with difference blend.
// On non-web platforms the child is returned unchanged.
class CursorOverlay extends StatefulWidget {
  const CursorOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<CursorOverlay> with SingleTickerProviderStateMixin {
  static const _kLerpFactor = 0.15;
  static const _kMinDelta = 0.1;

  final _cursorPos = ValueNotifier<Offset>(Offset.zero);
  final _ringPos = ValueNotifier<Offset>(Offset.zero);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final next = Offset.lerp(_ringPos.value, _cursorPos.value, _kLerpFactor)!;
      if ((next - _ringPos.value).distance > _kMinDelta) {
        _ringPos.value = next;
      }
    });
    _ticker.start();
    if (kIsWeb) {
      html.document.body?.style.cursor = 'none';
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      html.document.body?.style.cursor = 'auto';
    }
    _ticker.dispose();
    _cursorPos.dispose();
    _ringPos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onHover: (event) {
        _cursorPos.value = event.position;
        CursorState.position.value = event.position;
      },
      child: Stack(
        children: [
          widget.child,
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _CursorPainter(
                  cursorPos: _cursorPos,
                  ringPos: _ringPos,
                  isInteractive: CursorState.isInteractive,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  _CursorPainter({required this.cursorPos, required this.ringPos, required this.isInteractive})
    : super(repaint: Listenable.merge([cursorPos, ringPos, isInteractive]));

  final ValueNotifier<Offset> cursorPos;
  final ValueNotifier<Offset> ringPos;
  final ValueNotifier<bool> isInteractive;

  static const _kDotRadius = 2.0;
  static const _kRingRadiusIdle = 7.0;
  static const _kRingRadiusHover = 23.0;

  @override
  void paint(Canvas canvas, Size size) {
    final hovering = isInteractive.value;
    final ringRadius = hovering ? _kRingRadiusHover : _kRingRadiusIdle;

    if (hovering) {
      canvas.drawCircle(
        ringPos.value,
        ringRadius,
        Paint()
          ..color = EColors.primary
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.difference,
      );
    } else {
      canvas.drawCircle(
        ringPos.value,
        ringRadius,
        Paint()
          ..color = EColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..blendMode = BlendMode.difference,
      );
    }

    canvas.drawCircle(
      cursorPos.value,
      _kDotRadius,
      Paint()
        ..color = EColors.textWhite
        ..blendMode = BlendMode.difference,
    );
  }

  @override
  bool shouldRepaint(_CursorPainter old) => true;
}
