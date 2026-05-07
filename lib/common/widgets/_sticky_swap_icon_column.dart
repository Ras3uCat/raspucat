import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';

class StickySwapIconColumn extends StatelessWidget {
  const StickySwapIconColumn({super.key, required this.items, required this.activeIndex});

  final List<StickySwapItem> items;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          Container(width: 1, height: ESizes.xl, color: EColors.primary.withValues(alpha: 0.15)),
        );
      }
      children.add(
        _IconEntry(
          icon: items[i].icon,
          color: items[i].color,
          label: items[i].title,
          isActive: i == activeIndex,
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _IconEntry extends StatelessWidget {
  const _IconEntry({
    required this.icon,
    required this.color,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool isActive;

  static const _kCircleSize = 72.0;
  static const _kIconSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: _kCircleSize,
          height: _kCircleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
            boxShadow: isActive
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 2)]
                : [],
          ),
          child: Center(
            child: AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.25,
              duration: const Duration(milliseconds: 400),
              child: Icon(icon, size: _kIconSize, color: color),
            ),
          ),
        ),
        const SizedBox(height: ESizes.xs),
        AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.25,
          duration: const Duration(milliseconds: 400),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: ESizes.fontSizeLabel,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
