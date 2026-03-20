import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/utils/constants/exports.dart';

Future<void> main() async {
  usePathUrlStrategy();

  /// --- Waits for Flutter to initialize --- ///
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const Ras3uCatApp());
}

class Ras3uCatApp extends StatelessWidget {
  const Ras3uCatApp({super.key});

  static String get _initialRoute {
    if (!kIsWeb) return ERoutes.home;
    final path = Uri.base.path;
    return (path.isEmpty || path == '/') ? ERoutes.home : path;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: EBrand.appName,

      themeMode: ThemeMode.dark,
      theme: EAppTheme.lightTheme,
      darkTheme: EAppTheme.darkTheme,
      initialBinding: GeneralBindings(),
      getPages: AppRoutes.pages,
      initialRoute: _initialRoute,
      unknownRoute: GetPage(
        name: ERoutes.notFound,
        page: () => const NotFoundScreen(),
      ),
    );
  }
}
