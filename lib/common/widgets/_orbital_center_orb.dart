import 'package:raspucat/utils/constants/exports.dart';

class OrbitalCenterOrb extends StatefulWidget {
  const OrbitalCenterOrb({super.key});

  @override
  State<OrbitalCenterOrb> createState() => OrbitalCenterOrbState();
}

class OrbitalCenterOrbState extends State<OrbitalCenterOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(
              begin: 1.0,
              end: 1.15,
            ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
            ),
          ),
          ScaleTransition(
            scale: Tween<double>(
              begin: 1.0,
              end: 1.2,
            ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
              ),
            ),
          ),
          SvgPicture.asset(
            EImages.logoBlackSVG,
            width: 72,
            height: 72,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}
