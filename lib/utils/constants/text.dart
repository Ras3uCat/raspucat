import 'package:raspucat/utils/constants/brand.dart';

class EText {
  EText._();

  /// --- TO USE VARIABLES IN STRINGS --- ///
  /// --- '\$${EPricingCalculator.calculateTax(subTotal, 'US')}'--- ///
  /// --- '${EText.baseStorageErrorLoadingImage} $e' --- ///

  /// ------------------------------------------------------------------ ///

  /// --- APP TEXT --- ///
  ///
  ///
  static const String name = EBrand.appName;

  /// --- HERO SCREEN TEXT --- ///
  ///
  ///
  static const String heroHeading = EBrand.stylizedAppName;
  static const String heroSubtext = EBrand.voiceTagline;

  /// --- 404 SCREEN TEXT --- ///
  ///
  ///
  static const String notFoundCode = '404';
  static const String notFoundMessage = 'Lost in space.';
  static const String notFoundCta = 'RETURN HOME';

  /// --- PROJECTS SCREEN TEXT --- ///
  ///
  ///
  static const String projectsHeading = 'Projects';
  static const String projectsSubheading = 'Explore our latest projects';
  static const String code = 'Code';
  static const String live = 'Live';

  /// --- PORTAL LOGIN TEXT --- ///
  ///
  // Must be kept in sync with the Supabase magic link TTL setting.
  static const String magicLinkExpiry = 'The link expires in 1 hour';
}
