import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/common/widgets/_sticky_swap_icon_column.dart';
import 'package:raspucat/common/widgets/_sticky_swap_progress_bar.dart';

class StickySwapItem {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  const StickySwapItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });
}

class StickySwapSection extends StatefulWidget {
  const StickySwapSection({super.key, required this.items});
  final List<StickySwapItem> items;

  @override
  State<StickySwapSection> createState() => _StickySwapSectionState();
}

class _StickySwapSectionState extends State<StickySwapSection> {
  double _scrollProgress = 0.0;
  double _scrolledIn = 0.0;
  double _sectionAbsoluteY = -1;
  final _key = GlobalKey();
  late final ScrollController _sc;

  int get _activeIndex =>
      (_scrollProgress * widget.items.length).floor().clamp(0, widget.items.length - 1);

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
    final runway = viewportH * (widget.items.length - 1);
    if (runway <= 0) return;
    final scrolledIn = (_sc.offset - _sectionAbsoluteY).clamp(0.0, runway);
    final raw = scrolledIn / runway;
    setState(() {
      _scrollProgress = raw;
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
      return _MobileSwapList(items: widget.items);
    }
    final viewportH = size.height;
    final totalHeight = viewportH * widget.items.length;

    return SizedBox(
      key: _key,
      height: totalHeight,
      child: Stack(
        children: [
          _StickyContent(
            items: widget.items,
            progress: _scrollProgress,
            activeIndex: _activeIndex,
            stickyOffset: _scrolledIn,
          ),
        ],
      ),
    );
  }
}

class _StickyContent extends StatelessWidget {
  const _StickyContent({
    required this.items,
    required this.progress,
    required this.activeIndex,
    required this.stickyOffset,
  });

  final List<StickySwapItem> items;
  final double progress;
  final int activeIndex;
  final double stickyOffset;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final item = items[activeIndex];

    return Positioned(
      top: stickyOffset,
      left: 0,
      right: 0,
      child: SizedBox(
        height: size.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(ESizes.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '// WHAT WE BUILD',
                      style: TextStyle(
                        color: EColors.gold.withValues(alpha: 0.7),
                        fontSize: ESizes.fontSizeLabel,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: ESizes.md),
                    SizedBox(
                      height: ESizes.section4Xl,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Align(
                          key: ValueKey<int>(activeIndex),
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge?.copyWith(color: EColors.textPrimary),
                              ),
                              const SizedBox(height: ESizes.lg),
                              Text(
                                item.body,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: EColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: ESizes.xl),
                    StickySwapProgressBar(progress: progress),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: EColors.circuitSlate,
                  border: Border(
                    left: BorderSide(color: EColors.primary.withValues(alpha: 0.08), width: 1),
                  ),
                ),
                child: Center(
                  child: StickySwapIconColumn(items: items, activeIndex: activeIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSwapList extends StatelessWidget {
  const _MobileSwapList({required this.items});
  final List<StickySwapItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// WHAT WE BUILD',
            style: TextStyle(
              color: EColors.gold.withValues(alpha: 0.7),
              fontSize: ESizes.fontSizeLabel,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: ESizes.xl),
          ...items.map((item) => _MobileSwapCard(item: item)),
        ],
      ),
    );
  }
}

class _MobileSwapCard extends StatelessWidget {
  const _MobileSwapCard({required this.item});
  final StickySwapItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.xl),
      child: Container(
        padding: const EdgeInsets.all(ESizes.lg),
        decoration: BoxDecoration(
          color: EColors.circuitSlate,
          border: Border.all(color: item.color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(ESizes.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.color, size: ESizes.iconMd),
            const SizedBox(width: ESizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: EColors.textPrimary),
                  ),
                  const SizedBox(height: ESizes.sm),
                  Text(
                    item.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: EColors.textSecondary, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
