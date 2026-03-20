import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalStagePill extends StatelessWidget {
  const PortalStagePill({super.key, required this.quote, this.large = false});

  final PortalQuote quote;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? ESizes.md : ESizes.sm,
        vertical: large ? ESizes.xs + 2 : ESizes.xs,
      ),
      decoration: BoxDecoration(
        color: quote.stageColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: quote.stageColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: quote.stageColor),
          const SizedBox(width: ESizes.xs),
          Text(
            quote.stageLabel.toUpperCase(),
            style: TextStyle(
              color: quote.stageColor,
              fontSize: large ? ESizes.fontSizeSm : ESizes.fontSizeLabel,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
    );
  }
}
