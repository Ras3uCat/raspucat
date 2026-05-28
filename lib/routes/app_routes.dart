import 'package:raspucat/app/modules/screens/bingequest_legal_screen.dart';
import 'package:raspucat/app/modules/screens/app_project_landing_screen.dart';
import 'package:raspucat/app/modules/screens/terms_screen.dart';
import 'package:raspucat/app/modules/screens/privacy_screen.dart';
import 'package:raspucat/app/modules/screens/admin_screen.dart';
import 'package:raspucat/app/modules/screens/portal_screen.dart';
import 'package:raspucat/app/modules/screens/portal_login_screen.dart';
import 'package:raspucat/app/modules/screens/book_screen.dart';
import 'package:raspucat/app/modules/screens/manage_booking_screen.dart';
import 'package:raspucat/app/modules/widgets/portal_auth_middleware.dart';
import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/controllers/manage_booking_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';

class AppRoutes {
  static final pages = [
    GetPage(name: ERoutes.home, page: () => EResponsiveScreen()),
    GetPage(name: ERoutes.bingeQuestLegal, page: () => const BingeQuestLegalScreen()),
    GetPage(name: ERoutes.terms, page: () => const TermsScreen()),
    GetPage(name: ERoutes.privacy, page: () => const PrivacyScreen()),
    GetPage(name: ERoutes.admin, page: () => const AdminScreen()),
    GetPage(
      name: ERoutes.portal,
      page: () => const PortalScreen(),
      binding: BindingsBuilder(() {
        Get.delete<PortalController>(force: true);
        Get.put(PortalController());
      }),
      middlewares: [PortalAuthMiddleware()],
    ),
    GetPage(name: ERoutes.portalLogin, page: () => const PortalLoginScreen()),
    GetPage(name: ERoutes.book, page: () => const BookScreen()),
    GetPage(
      name: ERoutes.manageBooking,
      page: () => const ManageBookingScreen(),
      binding: BindingsBuilder(() {
        Get.put(ManageBookingController());
      }),
    ),
    GetPage(name: ERoutes.appProjectLanding, page: () => const AppProjectLandingScreen()),
  ];
}

// TO USE:
//    onTap: () {
//               Get.toNamed(ERoutes.home);
//             },
