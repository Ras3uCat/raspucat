import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:raspucat/utils/constants/exports.dart';

void main() {
  usePathUrlStrategy();

  /// --- Waits for Flutter to initialize --- ///
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const Ras3uCatApp());
}

class Ras3uCatApp extends StatelessWidget {
  const Ras3uCatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Ras3uCat",

      themeMode: ThemeMode.dark,
      theme: EAppTheme.lightTheme,
      darkTheme: EAppTheme.darkTheme,
      initialBinding: GeneralBindings(),
      getPages: AppRoutes.pages,
      initialRoute: ERoutes.home,
      unknownRoute: GetPage(
        name: ERoutes.notFound,
        page: () => const Scaffold(body: Center(child: Text('Not Found'))),
      ),
    );
  }
}
