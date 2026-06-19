import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/utils/constants/exports.dart';

class UnsubscribeScreen extends StatefulWidget {
  const UnsubscribeScreen({super.key});

  @override
  State<UnsubscribeScreen> createState() => _UnsubscribeScreenState();
}

class _UnsubscribeScreenState extends State<UnsubscribeScreen> {
  _Status _status = _Status.loading;

  @override
  void initState() {
    super.initState();
    _process();
  }

  Future<void> _process() async {
    final leadId = Get.parameters['id'];
    if (leadId == null || leadId.isEmpty) {
      setState(() => _status = _Status.invalid);
      return;
    }
    try {
      await Supabase.instance.client.functions.invoke(
        'public-unsubscribe',
        method: HttpMethod.get,
        queryParameters: {'id': leadId},
      );
      setState(() => _status = _Status.success);
    } catch (_) {
      setState(() => _status = _Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(ESizes.xl),
          padding: const EdgeInsets.all(ESizes.xl),
          decoration: BoxDecoration(
            color: EColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
          ),
          child: switch (_status) {
            _Status.loading => const Center(
              child: CircularProgressIndicator(color: EColors.primary),
            ),
            _Status.success => _Message(
              title: "You're unsubscribed",
              body:
                  "You've been removed from our outreach list and won't receive any more emails from us.\n\nMade a mistake? Reply to any of our emails and we'll add you back.",
            ),
            _Status.invalid => const _Message(
              title: 'Invalid link',
              body: 'This unsubscribe link is invalid or has already been used.',
            ),
            _Status.error => const _Message(
              title: 'Something went wrong',
              body:
                  'We could not process your request. Reply to any email from us and we will remove you manually.',
            ),
          },
        ),
      ),
    );
  }
}

enum _Status { loading, success, invalid, error }

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLg,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ESizes.md),
        Text(
          body,
          style: TextStyle(
            color: EColors.textWhite.withValues(alpha: 0.6),
            fontSize: ESizes.fontSizeSm,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
