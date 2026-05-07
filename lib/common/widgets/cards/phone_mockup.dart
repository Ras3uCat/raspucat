import 'package:raspucat/utils/constants/exports.dart';

const kPhoneWidth = 220.0;

class PhoneMockup extends StatelessWidget {
  const PhoneMockup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EColors.backgroundDark,
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.sm),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Center(
            child: Container(
              width: 28,
              height: 8,
              decoration: BoxDecoration(
                color: EColors.backgroundDark,
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(color: EColors.primary.withValues(alpha: 0.15), width: 1),
              ),
            ),
          ),
          const SizedBox(height: ESizes.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
              child: child,
            ),
          ),
          const SizedBox(height: ESizes.xs),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
