import 'package:raspucat/utils/constants/exports.dart';

class StickySwapProgressBar extends StatelessWidget {
  const StickySwapProgressBar({super.key, required this.progress});

  final double progress;

  static const _kBarHeight = 2.0;
  static const _kBarWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kBarWidth,
      height: _kBarHeight,
      child: Stack(
        children: [
          Container(
            width: _kBarWidth,
            height: _kBarHeight,
            color: EColors.primary.withValues(alpha: 0.15),
          ),
          Transform.scale(
            scaleX: progress,
            alignment: Alignment.centerLeft,
            child: Container(width: _kBarWidth, height: _kBarHeight, color: EColors.primary),
          ),
        ],
      ),
    );
  }
}
