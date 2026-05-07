import 'package:raspucat/utils/constants/exports.dart';

// Apple-style horizontal scroll panels driven by vertical page scroll.
// Each panel occupies a full-viewport width; the track translates left as the
// user scrolls down through the section's sticky height.
class HorizontalScrollPanels extends StatefulWidget {
  const HorizontalScrollPanels({super.key, required this.panels, this.title});

  final List<Widget> panels;
  final String? title;

  @override
  State<HorizontalScrollPanels> createState() => _HorizontalScrollPanelsState();
}

class _HorizontalScrollPanelsState extends State<HorizontalScrollPanels> {
  double _progress = 0.0;
  double _scrolledIn = 0.0;
  double _sectionAbsoluteY = -1;
  final _key = GlobalKey();
  late final ScrollController _sc;

  @override
  void initState() {
    super.initState();
    _sc = EScrollController.instance.scrollController;
    _sc.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        _sectionAbsoluteY = box.localToGlobal(Offset.zero).dy + _sc.offset;
      }
    });
  }

  void _onScroll() {
    if (_sectionAbsoluteY < 0) return;
    final viewportH = MediaQuery.sizeOf(context).height;
    final runway = (widget.panels.length - 1) * viewportH;
    if (runway <= 0) return;
    final scrolledIn = (_sc.offset - _sectionAbsoluteY).clamp(0.0, runway);
    final raw = scrolledIn / runway;
    setState(() {
      _progress = raw;
      _scrolledIn = scrolledIn;
    });
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < ESizes.mobile) {
      return _MobilePanelStack(panels: widget.panels, viewportH: size.height);
    }
    final viewportH = size.height;
    final viewportW = size.width;
    final totalHeight = viewportH + (widget.panels.length - 1) * viewportH;
    final horizontalOffset = _progress * (widget.panels.length - 1) * viewportW;

    return SizedBox(
      key: _key,
      height: totalHeight,
      child: Stack(
        children: [
          Positioned(
            top: _scrolledIn,
            left: 0,
            right: 0,
            child: SizedBox(
              height: viewportH,
              child: ClipRect(
                child: _PanelTrack(
                  panels: widget.panels,
                  horizontalOffset: horizontalOffset,
                  viewportWidth: viewportW,
                  title: widget.title,
                  progress: _progress,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTrack extends StatelessWidget {
  const _PanelTrack({
    required this.panels,
    required this.horizontalOffset,
    required this.viewportWidth,
    required this.progress,
    this.title,
  });

  final List<Widget> panels;
  final double horizontalOffset;
  final double viewportWidth;
  final double progress;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OverflowBox(
          maxWidth: viewportWidth * panels.length,
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(-horizontalOffset, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: panels.map((p) => SizedBox(width: viewportWidth, child: p)).toList(),
            ),
          ),
        ),
        if (title != null)
          Positioned(
            top: ESizes.xl,
            left: ESizes.xl,
            child: Text(
              title!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EColors.primary.withValues(alpha: 0.6),
                letterSpacing: 3.0,
              ),
            ),
          ),
        Positioned(
          bottom: ESizes.lg,
          left: 0,
          right: 0,
          child: _DotIndicator(count: panels.length, progress: progress),
        ),
      ],
    );
  }
}

class _MobilePanelStack extends StatelessWidget {
  const _MobilePanelStack({required this.panels, required this.viewportH});
  final List<Widget> panels;
  final double viewportH;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: panels.map((p) => SizedBox(height: viewportH, child: p)).toList(),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.progress});

  final int count;
  final double progress;

  static const _kDotSize = 6.0;
  static const _kDotSpacing = ESizes.xs;

  @override
  Widget build(BuildContext context) {
    final activeIndex = (progress * (count - 1)).round().clamp(0, count - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: _kDotSpacing / 2),
          width: isActive ? _kDotSize * 2 : _kDotSize,
          height: _kDotSize,
          decoration: BoxDecoration(
            color: isActive ? EColors.primary : EColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(_kDotSize),
          ),
        );
      }),
    );
  }
}
