import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/utils/popups/loaders.dart';

class ProjectsCarousel extends StatefulWidget {
  final ECarouselController controller;

  const ProjectsCarousel({super.key, required this.controller});

  @override
  State<ProjectsCarousel> createState() => _ProjectsCarouselState();
}

class _ProjectsCarouselState extends State<ProjectsCarousel> {
  final _hoveredCardIndex = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _hoveredCardIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    final isMobile = EDeviceUtils.isMobileWidth(width);
    return Column(
      children: [
        /// --- CAROUSEL SLIDER --- ///
        Obx(() {
          final currentPage = widget.controller.currentPage.value;

          return MouseRegion(
            onEnter: (_) => widget.controller.pauseAutoPlay(),
            onExit: (_) => widget.controller.resumeAutoPlay(),
            child: CarouselSlider.builder(
              carouselController: widget.controller.carouselController,
              itemCount: widget.controller.projects.length,
              options: CarouselOptions(
                height: ESizes.carouselHeightMd,
                enlargeCenterPage: true,
                viewportFraction: isMobile ? 0.9 : 0.4,
                enableInfiniteScroll: true,
                autoPlay: true,
                autoPlayInterval: EDurations.carouselAutoPlay,
                onPageChanged: (index, reason) {
                  widget.controller.onPageChanged(index);
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final project = widget.controller.projects[index];
                final isSelected = currentPage == index;

                /// --- PROJECT CARD --- ///
                return ProjectCard(
                  project: project,
                  index: index,
                  hoveredCardIndex: _hoveredCardIndex,
                  isSelected: isSelected,
                  onTap: () {
                    ELoaders.customDialog(
                      child: ProjectScreen(project: project),
                    );
                  },
                );
              },
            ),
          );
        }),

        const SizedBox(height: ESizes.spaceBtwSections),

        /// --- NAVIGATION TRIANGLES --- ///
        Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.controller.projects.length, (index) {
              final isActive = widget.controller.currentPage.value == index;
              final project = widget.controller.projects[index];
              final isHovered = widget.controller.hoveredIndex.value == index;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => widget.controller.setHoveredIndex(index),
                onExit: (_) => widget.controller.clearHover(),
                child: GestureDetector(
                  onTap: () => widget.controller.jumpTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: ESizes.sm),
                    child: CustomPaint(
                      size: Size((isActive ? 24 : 16), (isActive ? 24 : 16)),
                      painter: TriangleNavigationPainter(
                        color: EColors.primary,
                        isHovered: isHovered,
                        isActive: isActive,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
