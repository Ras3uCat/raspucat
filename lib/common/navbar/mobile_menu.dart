import 'dart:ui';
import 'package:raspucat/common/painters/hamburger_triangle_painter.dart';
import 'package:raspucat/utils/constants/exports.dart';

class NavItemData {
  const NavItemData({
    required this.label,
    required this.onTap,
    required this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final IconData icon;
}

// ─── Button ───────────────────────────────────────────────────────────────────

class MobileMenuButton extends StatefulWidget {
  const MobileMenuButton({super.key, required this.items});
  final List<NavItemData> items;

  @override
  State<MobileMenuButton> createState() => _MobileMenuButtonState();
}

class _MobileMenuButtonState extends State<MobileMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;
  bool _isOpen = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _controller.forward() : _controller.reverse();
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: EColors.primary.withValues(alpha: 0.55),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => CustomPaint(
                  size: const Size(22, 22),
                  painter: HamburgerTrianglePainter(
                    t: _anim.value,
                    color: EColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, child) => ClipRect(
            child: Align(
              heightFactor: _anim.value,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
          child: _MobileDropdown(
            items: widget.items,
            anim: _anim,
            onItemTap: _close,
          ),
        ),
      ],
    );
  }
}

// ─── Dropdown ─────────────────────────────────────────────────────────────────

class _MobileDropdown extends StatelessWidget {
  const _MobileDropdown({
    required this.items,
    required this.anim,
    required this.onItemTap,
  });

  final List<NavItemData> items;
  final Animation<double> anim;
  final VoidCallback onItemTap;

  static Widget _bracket({bool flipX = false, bool flipY = false}) {
    return SizedBox(
      width: 9,
      height: 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: flipY ? BorderSide.none : BorderSide(color: EColors.primary.withValues(alpha: 0.55), width: 1.5),
            bottom: flipY ? BorderSide(color: EColors.primary.withValues(alpha: 0.55), width: 1.5) : BorderSide.none,
            left: flipX ? BorderSide.none : BorderSide(color: EColors.primary.withValues(alpha: 0.55), width: 1.5),
            right: flipX ? BorderSide(color: EColors.primary.withValues(alpha: 0.55), width: 1.5) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ESizes.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: SizedBox(
            width: 248,
            child: Stack(
              children: [
                // Panel shell
                Container(
                  decoration: BoxDecoration(
                    color: EColors.backgroundDark.withValues(alpha: 0.88),
                    border: Border.all(color: EColors.primary.withValues(alpha: 0.14)),
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing top accent
                      Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(ESizes.borderRadiusMd),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              EColors.primary.withValues(alpha: 0.6),
                              EColors.primary,
                              EColors.primary.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Scanline overlay
                      CustomPaint(
                        painter: _ScanlinePainter(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // HUD header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  ESizes.lg, 10, ESizes.lg, 8),
                              child: Row(
                                children: [
                                  Text(
                                    '// NAV',
                                    style: TextStyle(
                                      color: EColors.primary.withValues(alpha: 0.5),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: EColors.primary.withValues(alpha: 0.55),
                                      boxShadow: [
                                        BoxShadow(
                                          color: EColors.primary.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 0.5,
                              color: EColors.primary.withValues(alpha: 0.1),
                            ),
                            // Nav items
                            ...List.generate(items.length, (i) {
                              final start = (i / items.length) * 0.25;
                              final end = (start + 0.75).clamp(0.0, 1.0);
                              final itemAnim = CurvedAnimation(
                                parent: anim,
                                curve: Interval(start, end, curve: Curves.easeOutCubic),
                              );
                              return _NavItem(
                                item: items[i],
                                index: i,
                                anim: itemAnim,
                                onTap: onItemTap,
                                showDivider: i < items.length - 1,
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Corner brackets
                Positioned(top: 6, left: 6, child: _bracket()),
                Positioned(top: 6, right: 6, child: _bracket(flipX: true)),
                Positioned(bottom: 6, left: 6, child: _bracket(flipY: true)),
                Positioned(bottom: 6, right: 6, child: _bracket(flipX: true, flipY: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.index,
    required this.anim,
    required this.onTap,
    required this.showDivider,
  });
  final NavItemData item;
  final int index;
  final Animation<double> anim;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final num = '0${widget.index + 1}';
    return AnimatedBuilder(
      animation: widget.anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - widget.anim.value)),
        child: Opacity(opacity: widget.anim.value, child: child),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            widget.onTap();
            widget.item.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: 16),
            decoration: BoxDecoration(
              color: _hovered ? EColors.primary.withValues(alpha: 0.07) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: _hovered ? EColors.primary : Colors.transparent,
                  width: 2,
                ),
                bottom: BorderSide(
                  color: widget.showDivider
                      ? EColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  num,
                  style: TextStyle(
                    color: EColors.primary.withValues(alpha: _hovered ? 0.9 : 0.25),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(width: ESizes.sm),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hovered ? 1.0 : 0.35,
                  child: Icon(widget.item.icon, color: EColors.primary, size: ESizes.iconSm),
                ),
                const SizedBox(width: ESizes.md),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _hovered ? EColors.textWhite : EColors.cyanTintedWhite,
                      fontSize: ESizes.fontSizeMd,
                      letterSpacing: 2.0,
                      fontWeight: _hovered ? FontWeight.w700 : FontWeight.w400,
                    ),
                    child: Text(widget.item.label),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hovered ? 1.0 : 0.0,
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: EColors.primary,
                    size: ESizes.iconSm - 4,
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

// ─── Scanline painter ─────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.022)
      ..strokeWidth = 1;
    for (double y = 2; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
