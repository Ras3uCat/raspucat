import 'package:flutter/scheduler.dart';
import 'package:raspucat/utils/constants/exports.dart';

// Infinite-scroll horizontal strip.
// Items repeat 40× so the loop seam is never visible.
// Ticker advances 0.5px per frame (~30px/s at 60fps).
class MarqueeSection extends StatefulWidget {
  const MarqueeSection({super.key});

  @override
  State<MarqueeSection> createState() => _MarqueeSectionState();
}

class _MarqueeSectionState extends State<MarqueeSection> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final ScrollController _scrollCtrl = ScrollController();
  double _pos = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration _) {
    _pos += 0.5;
    if (_scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent > 0) {
      final half = _scrollCtrl.position.maxScrollExtent / 2;
      if (_pos >= half) _pos = 0;
      _scrollCtrl.jumpTo(_pos);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ESizes.sectionSm,
      decoration: BoxDecoration(
        color: EColors.circuitSlate,
        border: Border.symmetric(
          horizontal: BorderSide(color: EColors.primary.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(children: [for (var i = 0; i < 40; i++) const _MarqueeItem()]),
      ),
    );
  }
}

class _MarqueeItem extends StatelessWidget {
  const _MarqueeItem();

  static const _kItems = ['Flutter', 'Supabase', 'Stripe', 'GetX', 'Dart'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._kItems.expand(
          (label) => [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EColors.primary.withValues(alpha: 0.5),
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
              child: Text(
                '// M3OW',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: EColors.gold.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
