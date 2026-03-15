import 'package:raspucat/app/modules/widgets/plan_card.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isMobile = width < ESizes.mobile;
    final animController = SectionAnimationController.instance;

    return SectionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOnView(
            id: 'plans_heading',
            controller: animController,
            startOffset: const Offset(0, 25),
            child: FittedBox(
              child: NeonText(
                text: 'PLANS',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
          const SizedBox(height: ESizes.sm),
          AnimatedOnView(
            id: 'plans_subtitle',
            controller: animController,
            startOffset: const Offset(0, 40),
            child: Text(
              'CHOOSE YOUR LAUNCHPAD',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: EColors.textSecondary,
                letterSpacing: 3.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: ESizes.spaceBtwSections),
          isMobile ? const _MobileCards() : const _DesktopCards(),
        ],
      ),
    );
  }
}

class _DesktopCards extends StatefulWidget {
  const _DesktopCards();

  @override
  State<_DesktopCards> createState() => _DesktopCardsState();
}

class _DesktopCardsState extends State<_DesktopCards> {
  final _hoveredId = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _hoveredId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animController = SectionAnimationController.instance;
    const offsets = [Offset(-40, 60), Offset(0, 80), Offset(40, 60)];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(planData.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.md),
          child: AnimatedOnView(
            id: 'plan_card_$i',
            controller: animController,
            startOffset: offsets[i],
            child: PlanCard(plan: planData[i], hoveredId: _hoveredId),
          ),
        );
      }),
    );
  }
}

class _MobileCards extends StatefulWidget {
  const _MobileCards();

  @override
  State<_MobileCards> createState() => _MobileCardsState();
}

class _MobileCardsState extends State<_MobileCards> {
  final _hoveredId = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _hoveredId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animController = SectionAnimationController.instance;

    return Column(
      children: List.generate(planData.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: ESizes.lg),
          child: AnimatedOnView(
            id: 'plan_card_mobile_$i',
            controller: animController,
            startOffset: Offset(0, 50.0 + (i * 20)),
            child: PlanCard(plan: planData[i], hoveredId: _hoveredId),
          ),
        );
      }),
    );
  }
}
