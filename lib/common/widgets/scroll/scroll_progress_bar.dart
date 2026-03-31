import 'package:raspucat/utils/constants/exports.dart';

class ScrollProgressBar extends StatelessWidget {
  const ScrollProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = EScrollController.instance.scrollController;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ListenableBuilder(
        listenable: sc,
        builder: (context, _) {
          double t = 0.0;
          if (sc.hasClients && sc.positions.length == 1) {
            final pos = sc.position;
            if (pos.haveDimensions && pos.maxScrollExtent > 0) {
              t = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
            }
          }
          return FractionallySizedBox(
            widthFactor: t,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EColors.primary, EColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EColors.primary.withValues(alpha: 0.55),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
