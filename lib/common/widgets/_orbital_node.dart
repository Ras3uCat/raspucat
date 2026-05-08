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

class _OrbitalNodeState extends State<OrbitalNode> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visualOpacity = widget.visualOpacity;
    final isExpanded = widget.isExpanded;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                  boxShadow: isExpanded
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
                      : null,
                ),
                child: Icon(
                  widget.item.icon,
                  size: ESizes.iconSm,
                  color: isExpanded ? Colors.black : Colors.white,
                ),
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
