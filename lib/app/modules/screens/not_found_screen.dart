import 'package:raspucat/utils/constants/exports.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000612),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              EText.notFoundCode,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: EColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
            ),
            SizedBox(height: ESizes.spaceBtwItems),
            Text(
              EText.notFoundMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: EColors.primary,
                  ),
            ),
            SizedBox(height: ESizes.spaceBtwSections),
            NeonButton(
              neonColor: EColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: ESizes.lg,
                vertical: ESizes.md,
              ),
              onTap: () => Get.offAllNamed(ERoutes.home),
              child: Text(
                EText.notFoundCta,
                style: TextStyle(
                  color: EColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
