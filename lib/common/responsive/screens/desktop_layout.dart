import 'package:raspucat/app/modules/screens/demo_section.dart';
import 'package:raspucat/app/modules/screens/landing_controller.dart';
import 'package:raspucat/app/modules/screens/projects_screen.dart';
import 'package:raspucat/common/widgets/cursor_overlay.dart';
import 'package:raspucat/common/widgets/marquee_section.dart';
import 'package:raspucat/utils/constants/exports.dart';

// Section order: Home(0) Marquee About(1) Projects(2) Plans(3) WhatWeBuild
//   HowItWorksPanels Stats Contact Footer
List<Widget> get _staticScreens => [
  HomeScreen(),
  const AboutScreen(),
  ProjectsScreen(),
  const DemoSection(),
  const PlansScreen(),
];

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key, this.body});

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final scrollController = EScrollController.instance;
    final viewportH = MediaQuery.sizeOf(context).height;

    return CursorOverlay(
      child: Scaffold(
        backgroundColor: EColors.backgroundDark,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: scrollController.scrollController,
              // Stack sizes to the Column's natural height — no fixed SizedBox needed.
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Home hero
                      ..._staticScreens.take(1),

                      // Priority 5: Marquee between hero and projects.
                      const MarqueeSection(),

                      // Remaining static screens (About, Projects, Plans?)
                      ..._staticScreens.skip(1),

                      // Priority 10: stats strip.
                      Obx(() {
                        final c = Get.find<LandingController>();
                        return StatsStrip(
                          projectsDeployed: c.projectsDeployed.value,
                          activeClients: c.activeClients.value,
                          uptimePct: c.uptimePct.value,
                        );
                      }),

                      // Priority 6: What We Build — orbital overview.
                      const WhatWeBuildOrbitalSection(),

                      // Priority 7: HowItWorksPanels (6 panels).
                      const HowItWorksPanels(),

                      const ContactScreen(),
                      const SiteFooter(),
                    ],
                  ),

                  // Priority 8: parallax on BackgroundTriangles — rendered on top so
                  // GestureDetectors are reachable. HitTestBehavior.translucent on each
                  // TriangleWidget passes scroll events through to the content below.
                  // Constrained to viewportH and fades out after ~2 viewports.
                  Obx(() {
                    final offset = scrollController.scrollOffset.value;
                    final fadeStart = viewportH * 1.8;
                    final opacity = (1.0 - (offset - fadeStart) / (viewportH * 0.5)).clamp(
                      0.0,
                      1.0,
                    );
                    return IgnorePointer(
                      ignoring: opacity == 0.0,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, offset * 0.3),
                          child: SizedBox(height: viewportH, child: BackgroundTriangles()),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const ENavBar(),
            const ScrollProgressBar(),
          ],
        ),
      ),
    );
  }
}
