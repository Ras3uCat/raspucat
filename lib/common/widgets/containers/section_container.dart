import 'package:raspucat/utils/constants/exports.dart';

class SectionContainer extends StatelessWidget {
  final Widget child;
  final double? paddingVertical;
  final double? paddingHorizontal;
  final double minHeightFactor;

  const SectionContainer({
    super.key,
    required this.child,
    this.paddingVertical,
    this.paddingHorizontal,
    this.minHeightFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final double paddingVertical = this.paddingVertical ?? ESizes.sectionMd;
    final double paddingHorizontal = this.paddingHorizontal ?? ESizes.sectionSm;
    return Container(
      padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: paddingHorizontal),
      width: width,
      constraints: BoxConstraints(minHeight: height * minHeightFactor),
      child: child,
    );
  }
}
