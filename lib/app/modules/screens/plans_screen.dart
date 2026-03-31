import 'package:raspucat/app/controllers/plans_controller.dart';
import 'package:raspucat/app/modules/widgets/plan_card.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final animController = SectionAnimationController.instance;

    final bool isDesktop = width >= ESizes.tablet;

    final double hPad = isDesktop ? ESizes.sectionSm : 0;
    return SectionContainer(
      paddingVertical: isDesktop ? null : ESizes.md,
      paddingHorizontal: hPad,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: isDesktop
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: ESizes.sectionSm),
            child: Column(
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
                      EText.plansBaseInclusions,
                      style: TextStyle(
                        color: EColors.textSecondary,
                        fontSize: ESizes.fontSizeLabel,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESizes.spaceBtwSections),
          isDesktop ? const _DesktopCards() : const _CardCarousel(),
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

class _CardCarousel extends StatefulWidget {
  const _CardCarousel();

  @override
  State<_CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<_CardCarousel> {
  final _hoveredId = ValueNotifier<String?>(null);
  final _carouselController = CarouselSliderController();
  int _currentPage = 1;
  int? _hoveredDot;
  Worker? _plansWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carouselController.jumpToPage(1);
    });
    // onPageChanged fires with 0 during carousel init, overriding _currentPage.
    // Reset to 1 (Premium) after plans first load.
    _plansWorker = once(
      PlansController.instance.plans,
      (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = 1);
      }),
    );
  }

  @override
  void dispose() {
    _plansWorker?.dispose();
    _hoveredId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isMobile = EDeviceUtils.isMobileWidth(width);
    // Compute fraction so each carousel slot ≈ card width (300) + 2×ESizes.md padding.
    // This prevents dead air at any viewport width.
    final double viewportFraction = isMobile
        ? 0.75
        : ((300 + ESizes.md * 2) / width).clamp(0.3, 0.88);

    return Obx(() {
      final plans = PlansController.instance.plans;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarouselSlider.builder(
            key: ValueKey(plans.isNotEmpty),
            carouselController: _carouselController,
            itemCount: plans.length,
            options: CarouselOptions(
              height: 590,
              initialPage: 1,
              enlargeCenterPage: true,
              enlargeFactor: 0.15,
              viewportFraction: viewportFraction,
              enableInfiniteScroll: false,
              autoPlay: false,
              onPageChanged: (i, _) => setState(() => _currentPage = i),
            ),
            itemBuilder: (_, i, __) => PlanCard(
              plan: plans[i],
              hoveredId: _hoveredId,
            ),
          ),
          const SizedBox(height: ESizes.spaceBtwSections),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(plans.length, (i) {
              final isActive = i == _currentPage;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredDot = i),
                onExit: (_) => setState(() => _hoveredDot = null),
                child: GestureDetector(
                  onTap: () => _carouselController.animateToPage(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: ESizes.sm),
                    child: CustomPaint(
                      size: Size(isActive ? 24 : 16, isActive ? 24 : 16),
                      painter: TriangleNavigationPainter(
                        color: EColors.primary,
                        isHovered: _hoveredDot == i,
                        isActive: isActive,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    });
  }
}
