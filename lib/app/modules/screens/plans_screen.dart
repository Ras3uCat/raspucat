import 'package:raspucat/app/controllers/plans_controller.dart';
import 'package:raspucat/app/modules/widgets/plan_card.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isMobile = EDeviceUtils.isMobileWidth(width);
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
          const SizedBox(height: ESizes.md),
          AnimatedOnView(
            id: 'plans_base_blurb',
            controller: animController,
            startOffset: const Offset(0, 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.symmetric(
                horizontal: ESizes.lg,
                vertical: ESizes.sm + 2,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                color: EColors.primary.withValues(alpha: 0.05),
                border: Border.all(
                  color: EColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'Every plan includes a full website (home, services, about & FAQ), '
                'contact form, mobile-responsive design, and SEO-ready setup — '
                'all starting from \$1,200.',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSizeLabel,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
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

    return Obx(() {
      final plans = PlansController.instance.plans;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(plans.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md),
            child: AnimatedOnView(
              id: 'plan_card_$i',
              controller: animController,
              startOffset: offsets[i < offsets.length ? i : 0],
              child: PlanCard(plan: plans[i], hoveredId: _hoveredId),
            ),
          );
        }),
      );
    });
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

    return Obx(() {
      final plans = PlansController.instance.plans;
      return Column(
        children: List.generate(plans.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ESizes.lg),
            child: AnimatedOnView(
              id: 'plan_card_mobile_$i',
              controller: animController,
              startOffset: Offset(0, 50.0 + (i * 20)),
              child: PlanCard(plan: plans[i], hoveredId: _hoveredId),
            ),
          );
        }),
      );
    });
  }
}
