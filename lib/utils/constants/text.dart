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

  /// --- ABOUT SECTION TEXT --- ///
  ///
  static const String aboutSubLabel = 'Signal acquired. Systems online.';
  static const String aboutBio =
      'Flutter developer. Full-stack builder. We handle the full run from first brief to launch day: '
      'interfaces, payment backends, live databases, and everything in between. '
      'Past builds include booking platforms, iOS and Android apps, and interactive web frontends. '
      'One point of contact. No overhead.';

  /// --- SKILLS SECTION TEXT --- ///
  ///
  static const String skillsSubLabel = 'The stack behind the work.';

  /// --- CONTACT SECTION TEXT --- ///
  ///
  static const String contactSubLabel = 'Ready when you are.';
  static const String contactCopy =
      'Have a project in mind? Drop a message and let\'s see if we\'re a good fit. '
      'Most inquiries get a reply within one business day.';

  /// --- PROJECTS SCREEN TEXT --- ///
  ///
  ///
  static const String projectsHeading = 'Projects';
  static const String projectsSubheading = 'Explore our latest projects';
  static const String code = 'Code';
  static const String live = 'Live';

  /// --- HOW IT WORKS SECTION TEXT --- ///
  ///
  static const String howItWorksHeading = 'THE SEQUENCE';
  static const String howItWorksSubLabel = 'From first signal to fully operational.';
  static const String howItWorksPortalBadge = 'Portal opens on deposit';

  /// --- PLANS SCREEN TEXT --- ///
  ///
  static const String plansBaseInclusions =
      'Every plan includes a full website (home, services, about & FAQ), '
      'contact form, mobile-responsive design, and SEO-ready setup. '
      'All starting from \$1,200.';
  static const String planHandoverNote = 'or \$400 one-time handover';

  /// --- PORTAL LOGIN TEXT --- ///
  ///
  // Must be kept in sync with the Supabase magic link TTL setting.
  static const String magicLinkExpiry = 'The link expires in 1 hour';
}
