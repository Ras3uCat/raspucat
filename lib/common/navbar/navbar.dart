import 'package:raspucat/utils/constants/exports.dart';

class ENavBar extends StatelessWidget {
  const ENavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollCtrl = EScrollController.instance;

    final items = [
      NavItemData(
        label: 'Projects',
        onTap: () => scrollCtrl.scrollToKey(EScrollController.projectsKey),
        icon: Icons.grid_view_rounded,
      ),
      NavItemData(
        label: 'Demo',
        onTap: () => scrollCtrl.scrollToKey(EScrollController.demoKey),
        icon: Icons.play_circle_outline_rounded,
      ),
      NavItemData(
        label: 'Plans',
        onTap: () => scrollCtrl.scrollToKey(EScrollController.plansKey),
        icon: Icons.tune_rounded,
      ),
      NavItemData(
        label: 'Contact',
        onTap: () => scrollCtrl.scrollToKey(EScrollController.contactKey),
        icon: Icons.send_rounded,
      ),
    ];

    return Positioned(top: 16, right: 20, child: MobileMenuButton(items: items));
  }
}
