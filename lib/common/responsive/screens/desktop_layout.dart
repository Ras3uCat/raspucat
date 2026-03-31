import 'package:raspucat/app/modules/screens/projects_screen.dart';
import 'package:raspucat/utils/constants/exports.dart';

// Section order: Home(0) About(1) Projects(2) [Plans(3)] HowItWorks(3/4) Contact(4/5)
// Plans is conditionally included based on EEnv.showPlans (?preview=plans URL param).
List<Widget> get screens => [
  HomeScreen(),
  const AboutScreen(),
  ProjectsScreen(),
  if (EEnv.showPlans) PlansScreen(),
  const HowItWorksSection(),
  const ContactScreen(),
];

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key, this.body});

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    /// --- CONTROLLERS --- ///
    final scrollController = EScrollController.instance;

    /// --- METHOD 1 --- ///
    //     return Scaffold(
    //       backgroundColor: EColors.backgroundDark,
    //       body: Stack(
    //         children: [
    //           SingleChildScrollView(
    //             controller: scrollController.scrollController,
    //             child: Column(children: [HomeScreen(), ProjectsScreen()]),
    //           ),
    //           BackgroundTriangles(),
    //         ],
    //       ),
    //     );
    //   }
    // }

    /// --- METHOD 2 --- ///
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController.scrollController,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * screens.length + ESizes.footerHeight,
              child: Stack(
                children: [
                  BackgroundTriangles(),
                  Column(children: [...screens, const SiteFooter()]),
                ],
              ),
            ),
          ),
          const ENavBar(),
          const ScrollProgressBar(),
        ],
      ),
    );
  }
}
