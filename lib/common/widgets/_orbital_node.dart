import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';
import 'package:raspucat/common/widgets/_orbital_node_card.dart';

class OrbitalNode extends StatefulWidget {
  const OrbitalNode({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onTap,
    this.visualOpacity = 1.0,
  });

  final StickySwapItem item;
  final bool isExpanded;
  final VoidCallback onTap;
  final double visualOpacity;

  @override
  State<OrbitalNode> createState() => _OrbitalNodeState();
}

class _OrbitalNodeState extends State<OrbitalNode> with TickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(OrbitalNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (_hovered || widget.isExpanded) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _setHovered(bool value) {
    setState(() => _hovered = value);
    _syncPulse();
  }

  bool get _isIdle => !_hovered && !widget.isExpanded;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visualOpacity = widget.visualOpacity;
    final isExpanded = widget.isExpanded;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: _hovered ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  final pulseScale = _isIdle ? (1.0 + 0.10 * _pulseAnim.value) : 1.0;
                  final glowShadows = isExpanded
                      ? [
                          BoxShadow(
                            color: EColors.primary.withValues(alpha: 0.6 * visualOpacity),
                            blurRadius: ESizes.blurRadiusMd / 4,
                            spreadRadius: 2,
                          ),
                        ]
                      : _hovered
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2 * visualOpacity),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: 0.22 * _pulseAnim.value * visualOpacity,
                            ),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ];

                  return Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isExpanded
                            ? Colors.white.withValues(alpha: visualOpacity)
                            : Colors.transparent,
                        border: Border.all(
                          color: isExpanded
                              ? Colors.white.withValues(alpha: visualOpacity)
                              : _hovered
                              ? Colors.white.withValues(alpha: 0.9 * visualOpacity)
                              : Colors.white.withValues(alpha: 0.4 * visualOpacity),
                          width: 1.5,
                        ),
                        boxShadow: glowShadows,
                      ),
                      child: Icon(
                        widget.item.icon,
                        size: ESizes.iconSm,
                        color: isExpanded ? Colors.black : Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: ESizes.xs),
              Text(
                widget.item.title.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7 * visualOpacity),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: ESizes.xs),
                  child: OrbitalNodeCard(item: widget.item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
