import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/plans_controller.dart';
import 'package:raspucat/app/controllers/contact_controller.dart';
import 'package:raspucat/app/modules/screens/landing_controller.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LandingController());
    Get.put(TriangleController());
    // Get.put(EHoverController());
    Get.put(GradientController());
    Get.put(EScrollController());
    Get.put(SectionAnimationController());
    Get.put(ECarouselController(projects: EData.projects));
    Get.put(PlansController());
    Get.put(ContactController());
  }
}
