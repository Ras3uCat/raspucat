import 'package:raspucat/app/data/content/legal_content.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: 'PRIVACY POLICY',
      lastUpdated: privacyLastUpdated,
      sections: privacyContent,
    );
  }
}
