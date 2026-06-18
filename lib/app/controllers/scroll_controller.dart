import 'package:raspucat/utils/constants/exports.dart';

class EScrollController extends GetxController {
  static EScrollController get instance => Get.find();
  final scrollController = ScrollController();

  static final projectsKey = GlobalKey(debugLabel: 'projects');
  static final demoKey = GlobalKey(debugLabel: 'demo');
  static final plansKey = GlobalKey(debugLabel: 'plans');
  static final contactKey = GlobalKey(debugLabel: 'contact');

  final scrollOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
  }

  void scrollTo(double offset) {
    scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll); // Remove listener
    scrollController.dispose();
    super.onClose();
  }
}
