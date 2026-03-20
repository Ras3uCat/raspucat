import 'package:raspucat/utils/constants/exports.dart';

class ModuleToggleTile extends StatefulWidget {
  const ModuleToggleTile({
    super.key,
    required this.module,
    required this.isSelected,
    required this.isLocked,
    required this.isParentSelected,
    required this.onToggle,
  });

  final ModuleModel module;
  final bool isSelected;
  final bool isLocked;
  // When upgradeOf != null, tile is disabled unless parent is selected
  final bool isParentSelected;
  final ValueChanged<bool> onToggle;

  @override
  State<ModuleToggleTile> createState() => _ModuleToggleTileState();
}

class _ModuleToggleTileState extends State<ModuleToggleTile> {
  bool _hovered = false;

  bool get _isEffectivelyDisabled {
    if (widget.isLocked) return true;
    if (widget.module.upgradeOf != null && !widget.isParentSelected) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Locked tiles: border stays bright (not wrapped in opacity).
    // Content is dimmed separately so the tile still pops visually.
    final borderColor = widget.isLocked
        ? EColors.primary.withValues(alpha: 0.7)
        : widget.isSelected
            ? EColors.primary.withValues(alpha: 0.5)
            : EColors.primary.withValues(alpha: 0.12);
    final borderWidth = widget.isLocked ? 1.4 : 1.0;
    final bgColor = (widget.isLocked || widget.isSelected)
        ? EColors.primary.withValues(alpha: 0.06)
        : Colors.transparent;

    // Locked tiles reveal their content on hover; other disabled tiles stay dim.
    final opacity = _isEffectivelyDisabled
        ? (widget.isLocked && _hovered ? 0.85 : 0.45)
        : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: ESizes.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(color: borderColor, width: borderWidth),
          color: bgColor,
        ),
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ESizes.md,
              vertical: ESizes.sm + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TileInfo(
                    module: widget.module,
                    isLocked: widget.isLocked,
                  ),
                ),
                const SizedBox(width: ESizes.sm),
                _TileControl(
                  module: widget.module,
                  isSelected: widget.isSelected,
                  isLocked: widget.isLocked,
                  isEffectivelyDisabled: _isEffectivelyDisabled,
                  onToggle: widget.onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileInfo extends StatelessWidget {
  const _TileInfo({required this.module, required this.isLocked});
  final ModuleModel module;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              module.name,
              style: TextStyle(
                color: EColors.textWhite,
                fontSize: ESizes.fontSizeMd,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (module.upgradeOf != null) ...[
              const SizedBox(width: ESizes.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: EColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                  border: Border.all(
                    color: EColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'Upgrade from ${module.upgradeOf}',
                  style: TextStyle(
                    color: EColors.accent,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          module.description,
          style: TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSizeLabel,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              module.displayPrice,
              style: TextStyle(
                color: EColors.gold.withValues(alpha: isLocked ? 0.6 : 1.0),
                fontSize: ESizes.fontSizeLabel,
                fontWeight: FontWeight.w600,
                decoration: isLocked ? TextDecoration.lineThrough : null,
                decorationColor: EColors.gold.withValues(alpha: 0.6),
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 6),
              Text(
                'Included',
                style: TextStyle(
                  color: EColors.primary,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ] else if (module.priceNote != null) ...[
              const SizedBox(width: 4),
              Text(
                module.priceNote!,
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TileControl extends StatelessWidget {
  const _TileControl({
    required this.module,
    required this.isSelected,
    required this.isLocked,
    required this.isEffectivelyDisabled,
    required this.onToggle,
  });

  final ModuleModel module;
  final bool isSelected;
  final bool isLocked;
  final bool isEffectivelyDisabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(
          Icons.lock_outline,
          size: ESizes.iconSm,
          color: EColors.textSecondary,
        ),
      );
    }

    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: isSelected,
        onChanged: isEffectivelyDisabled ? null : onToggle,
        activeColor: EColors.primary,
        inactiveThumbColor: EColors.textSecondary,
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => EColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
