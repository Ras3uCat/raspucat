import 'package:raspucat/utils/constants/exports.dart';

/// A looping shimmer skeleton — use as a loading placeholder.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, this.borderRadius = ESizes.borderRadiusLg});
  final double borderRadius;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final t = _anim.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.5 + t * 3, 0),
                end: Alignment(-0.5 + t * 3, 0),
                colors: [
                  EColors.primary.withValues(alpha: 0.04),
                  EColors.primary.withValues(alpha: 0.12),
                  EColors.primary.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
