import 'dart:ui';
import 'package:raspucat/utils/constants/exports.dart';

class EDialog extends StatefulWidget {
  const EDialog({super.key, this.child = const SizedBox()});
  final Widget child;

  @override
  State<EDialog> createState() => _EDialogState();
}

class _EDialogState extends State<EDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scale = Tween<double>(
      begin: 0.93,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double width = EDeviceUtils.getScreenWidth();
    final double height = EDeviceUtils.getScreenHeight();
    final bool isMobile = EDeviceUtils.isMobileWidth(width);
    final bool isTablet = width < ESizes.tablet && width >= ESizes.mobile;

    final margin = isMobile
        ? EdgeInsets.symmetric(horizontal: width * 0.1, vertical: height * 0.1)
        : isTablet
        ? EdgeInsets.symmetric(horizontal: width * 0.2, vertical: height * 0.1)
        : EdgeInsets.symmetric(horizontal: width * 0.3, vertical: height * 0.1);

    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
            border: Border.all(color: EColors.primary.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: EColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
            child: Stack(
              children: [
                // Blur layer — BackdropFilter inside Stack has a defined
                // compositing scope and won't conflict with ScaleTransition above.
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: EColors.backgroundDark.withValues(alpha: 0.78)),
                  ),
                ),
                // Content
                AlertDialog(
                  contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md),
                  insetPadding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  content: SingleChildScrollView(
                    child: SizedBox(width: width, child: widget.child),
                  ),
                ),
                // Close button — needs its own Material since it's outside AlertDialog's scope
                Positioned(
                  top: ESizes.md,
                  right: ESizes.md,
                  child: Material(
                    color: Colors.transparent,
                    child: NeonButton(
                      onTap: _close,
                      padding: const EdgeInsets.all(ESizes.sm),
                      enableOverlay: false,
                      child: Icon(Icons.close, color: EColors.primary, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
