import 'package:raspucat/utils/constants/exports.dart';

// Word-by-word reveal: each word slides up from clip + fades in with stagger.
// Fires once when [trigger] flips to true.
class TextReveal extends StatefulWidget {
  const TextReveal({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.left,
    this.trigger = true,
    this.wordDelayMs = 200,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  /// Set to true to begin the reveal animation.
  final bool trigger;

  /// Milliseconds between each word appearing.
  final int wordDelayMs;

  @override
  State<TextReveal> createState() => _TextRevealState();
}

class _TextRevealState extends State<TextReveal> {
  static const _kDuration = Duration(milliseconds: 1100);
  static const _kCurve = Cubic(0.16, 1.0, 0.3, 1.0);
  static const _kSlide = Offset(0, 0.25);

  late List<bool> _wordVisible;

  @override
  void initState() {
    super.initState();
    final words = widget.text.split(' ');
    _wordVisible = List.filled(words.length, false);
    if (widget.trigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startReveal());
    }
  }

  @override
  void didUpdateWidget(TextReveal old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) _startReveal();
  }

  void _startReveal() {
    final words = widget.text.split(' ');
    for (var i = 0; i < words.length; i++) {
      Future.delayed(Duration(milliseconds: widget.wordDelayMs * i), () {
        if (mounted) setState(() => _wordVisible[i] = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.text.split(' ');
    return Wrap(
      alignment: _wrapAlignment(widget.textAlign),
      children: List.generate(words.length, (i) {
        return AnimatedSlide(
          offset: _wordVisible[i] ? Offset.zero : _kSlide,
          duration: _kDuration,
          curve: _kCurve,
          child: AnimatedOpacity(
            opacity: _wordVisible[i] ? 1.0 : 0.0,
            duration: _kDuration,
            curve: _kCurve,
            child: Padding(
              padding: EdgeInsets.only(
                right: i < words.length - 1
                    ? (widget.style.fontSize ?? ESizes.fontSizeMd) * 0.3
                    : 0,
              ),
              child: Text(words[i], style: widget.style),
            ),
          ),
        );
      }),
    );
  }

  WrapAlignment _wrapAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.end:
      case TextAlign.right:
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }
}
