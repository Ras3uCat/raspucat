import 'package:flutter/scheduler.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/sticky_swap_section.dart';
import 'package:raspucat/common/widgets/_orbital_center_orb.dart';
import 'package:raspucat/common/widgets/_orbital_node.dart';
import 'package:raspucat/common/widgets/_orbital_mobile_card.dart';

class OrbitalTimeline extends StatefulWidget {
  const OrbitalTimeline({
    super.key,
    required this.items,
    this.sectionLabel = '// WHAT WE BUILD',
    this.desktopHeading = 'ORBITAL SERVICE MAP',
    this.mobileHeading = 'SERVICE MAP',
  });

  final List<StickySwapItem> items;
  final String sectionLabel;
  final String desktopHeading;
  final String mobileHeading;

  @override
  State<OrbitalTimeline> createState() => _OrbitalTimelineState();
}

const double _kOrbitRadius = 200.0;

class _OrbitalTimelineState extends State<OrbitalTimeline> with SingleTickerProviderStateMixin {
  double _rotationAngle = 0;
  int? _expandedId;
  bool _autoRotate = true;
  late final Ticker _ticker;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_autoRotate) {
      _lastElapsed = elapsed;
      return;
    }
    final dtMs = _lastElapsed == null ? 0 : (elapsed - _lastElapsed!).inMilliseconds;
    _lastElapsed = elapsed;
    if (dtMs > 0) {
      setState(() {
        _rotationAngle = (_rotationAngle + dtMs * 0.006) % 360;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Offset _positionFor(int index, int total, double rotAngle) {
    final angle = ((index / total) * 360 + rotAngle) % 360;
    final rad = angle * pi / 180;
    return Offset(_kOrbitRadius * cos(rad), _kOrbitRadius * sin(rad));
  }

  double _opacityFor(int index, int total, double rotAngle) {
    final rad = (((index / total) * 360 + rotAngle) % 360) * pi / 180;
    return (0.4 + 0.6 * ((1 + sin(rad)) / 2)).clamp(0.4, 1.0);
  }

  int _zIndexFor(int index, int total, double rotAngle) {
    final rad = (((index / total) * 360 + rotAngle) % 360) * pi / 180;
    return (100 + 50 * cos(rad)).round();
  }

  void _onNodeTap(int id) {
    setState(() {
      if (_expandedId == id) {
        _expandedId = null;
        _autoRotate = true;
      } else {
        _expandedId = id;
        _autoRotate = false;
      }
    });
  }

  void _onBackgroundTap() {
    if (_expandedId != null) {
      setState(() {
        _expandedId = null;
        _autoRotate = true;
      });
    }
  }

  Widget _buildDesktop(BuildContext context, double screenHeight) {
    final total = widget.items.length;
    final textTheme = Theme.of(context).textTheme;

    final nodes = List.generate(total, (i) {
      final offset = _positionFor(i, total, _rotationAngle);
      final opacity = _opacityFor(i, total, _rotationAngle);
      final zIndex = _zIndexFor(i, total, _rotationAngle);
      return _PositionedNode(
        key: ValueKey(i),
        zIndex: zIndex,
        child: Transform.translate(
          offset: offset - const Offset(0, 12),
          child: OrbitalNode(
            item: widget.items[i],
            isExpanded: _expandedId == i,
            onTap: () => _onNodeTap(i),
            visualOpacity: opacity,
          ),
        ),
      );
    });

    nodes.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return SizedBox(
      height: screenHeight * 0.9,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.sectionLabel,
            style: textTheme.labelSmall?.copyWith(
              color: EColors.primary.withValues(alpha: 0.7),
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: ESizes.lg),
          Text(
            widget.desktopHeading,
            style: textTheme.headlineMedium?.copyWith(color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: ESizes.xl),
          GestureDetector(
            onTap: _onBackgroundTap,
            behavior: HitTestBehavior.deferToChild,
            child: SizedBox(
              width: (_kOrbitRadius + 80) * 2,
              height: (_kOrbitRadius + 80) * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: _kOrbitRadius * 2,
                    height: _kOrbitRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                    ),
                  ),
                  const OrbitalCenterOrb(),
                  ...nodes.map((n) => n.child),
                ],
              ),
            ),
          ),
          const SizedBox(height: ESizes.lg),
          AnimatedOpacity(
            opacity: _expandedId == null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: Column(
              children: [
                Text(
                  '// TAP TO EXPLORE',
                  style: textTheme.labelSmall?.copyWith(
                    color: EColors.primary.withValues(alpha: 0.5),
                    letterSpacing: 3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sectionLabel,
            style: textTheme.labelSmall?.copyWith(
              color: EColors.primary.withValues(alpha: 0.7),
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: ESizes.md),
          Text(
            widget.mobileHeading,
            style: textTheme.headlineMedium?.copyWith(color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: ESizes.xl),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: ESizes.md),
              child: OrbitalMobileCard(item: item),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    if (width > ESizes.mobile) {
      return _buildDesktop(context, height);
    }
    return _buildMobile(context);
  }
}

class _PositionedNode {
  const _PositionedNode({required this.key, required this.zIndex, required this.child});

  final Key key;
  final int zIndex;
  final Widget child;
}
