import 'package:raspucat/app/data/content/legal_content.dart';
import 'package:raspucat/utils/constants/exports.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: 'TERMS & CONDITIONS',
      lastUpdated: termsLastUpdated,
      sections: termsContent,
    );
  }
}
