import 'package:raspucat/utils/constants/exports.dart';

class ENavBar extends StatelessWidget {
  const ENavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final scrollCtrl = EScrollController.instance;

    // Section order depends on EEnv.showPlans:
    //   with plans:    Home(0) About(1) Projects(2) Plans(3) HowItWorks(4) Contact(5)
    //   without plans: Home(0) About(1) Projects(2) HowItWorks(3) Contact(4)
    final contactIndex = EEnv.showPlans ? 5 : 4;
    final items = [
      NavItemData(
        label: 'Projects',
        onTap: () => scrollCtrl.scrollTo(screenH * 2),
        icon: Icons.grid_view_rounded,
      ),
      if (EEnv.showPlans)
        NavItemData(
          label: 'Plans',
          onTap: () => scrollCtrl.scrollTo(screenH * 3),
          icon: Icons.tune_rounded,
        ),
      NavItemData(
        label: 'Contact',
        onTap: () => scrollCtrl.scrollTo(screenH * contactIndex),
        icon: Icons.send_rounded,
      ),
    ];

    return Positioned(top: 16, right: 20, child: MobileMenuButton(items: items));
  }
}
