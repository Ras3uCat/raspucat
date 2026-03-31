import 'package:raspucat/utils/constants/exports.dart';

/// --- REUSABLE NEON BUTTON WIDGET --- ///
class NeonButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color neonColor;
  final Color? hoverColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool enableOverlay;

  const NeonButton({
    super.key,
    required this.child,
    this.onTap,
    this.neonColor = EColors.primary,
    this.hoverColor = EColors.accent,
    this.borderRadius = ESizes.borderRadiusMd,
    this.padding = const EdgeInsets.all(ESizes.md),
    this.width,
    this.height,
    this.enableOverlay = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    return Opacity(
      opacity: disabled ? 0.38 : 1.0,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onHover: disabled ? null : (value) {
            setState(() => _isHovered = value);
          },
          hoverColor: Colors.transparent,
          highlightColor: EColors.primary.withValues(alpha: 0.1),
          splashColor: EColors.primary,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: EDurations.buttonHover,
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                for (double i = 1; i < 3; i++)
                  BoxShadow(
                    color: _isHovered
                        ? widget.hoverColor!.withValues(alpha: 1 - (i * 0.3))
                        : EColors.backgroundDark.withValues(alpha: 1 - (i * 0.3)),
                    blurRadius: 3 * i,
                  ),
              ],
              color: EColors.backgroundDark.withValues(alpha: 0.8),
              border: Border.all(
                color: _isHovered
                    ? widget.hoverColor?.withValues(alpha: 0.7) ?? widget.neonColor.withValues(alpha: 0.8)
                    : widget.neonColor.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: _isHovered && widget.enableOverlay
                ? GradientOverlay(child: widget.child)
                : widget.child,
          ),
        ),
      ),
    );
  }
}
