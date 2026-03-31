import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalCancelButton extends StatelessWidget {
  const PortalCancelButton({super.key, required this.ctrl, required this.quote});
  final PortalController ctrl;
  final PortalQuote quote;

  @override
  Widget build(BuildContext context) {
    // If already cancelled (subscription.deleted fired), show nothing
    if (quote.status == 'cancelled') return const SizedBox.shrink();

    // If cancel is scheduled, show confirmation banner instead of button
    if (quote.subscriptionCancelAt != null) {
      return _CancellationScheduledBanner(date: quote.subscriptionCancelAt!);
    }

    // Only show cancel button if subscription is active
    if (quote.subscriptionStartedAt == null) return const SizedBox.shrink();

    return Obx(() {
      final error = ctrl.cancelError.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: ctrl.isCancelLoading.value
                ? null
                : () => _showCancelDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: ctrl.isCancelLoading.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6B6B),
                        strokeWidth: 1.5,
                      ),
                    )
                  : Text(
                      'Cancel Subscription',
                      style: TextStyle(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.7),
                        fontSize: ESizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: ESizes.fontSizeLabel,
                ),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final emailCtrl = TextEditingController(text: quote.clientEmail);
    final isEmailValid = ValueNotifier<bool>(true);

    final confirmed = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CancelDialog(
        quote: quote,
        emailCtrl: emailCtrl,
        isEmailValid: isEmailValid,
      ),
    );

    emailCtrl.dispose();
    if (confirmed == null) return;

    await ctrl.cancelSubscription(confirmed);
  }
}

// ---------------------------------------------------------------------------
// Cancel dialog
// ---------------------------------------------------------------------------

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({
    required this.quote,
    required this.emailCtrl,
    required this.isEmailValid,
  });
  final PortalQuote quote;
  final TextEditingController emailCtrl;
  final ValueNotifier<bool> isEmailValid;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  late bool _valid;

  @override
  void initState() {
    super.initState();
    _valid = _emailPattern.hasMatch(widget.emailCtrl.text);
  }

  void _onEmailChanged(String v) {
    final ok = _emailPattern.hasMatch(v.trim());
    if (ok != _valid) setState(() => _valid = ok);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        side: BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
      ),
      title: const Text(
        'Cancel Subscription',
        style: TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeMd),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your service will end at the close of your current billing period. '
              'We\'ll send your files and deliverables to the address below.',
              style: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.75),
                fontSize: ESizes.fontSizeSm,
                height: 1.6,
              ),
            ),
            const SizedBox(height: ESizes.md),
            Text(
              'Where should we send your files and deliverables?',
              style: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.5),
                fontSize: ESizes.fontSizeLabel,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.emailCtrl,
              onChanged: _onEmailChanged,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
              decoration: InputDecoration(
                hintText: 'your@email.com',
                hintStyle: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.35)),
                filled: true,
                fillColor: EColors.primary.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ESizes.md, vertical: ESizes.sm + 4,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Keep Subscription',
              style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.6))),
        ),
        TextButton(
          onPressed: _valid
              ? () => Navigator.pop(context, widget.emailCtrl.text.trim())
              : null,
          child: Text(
            'Confirm Cancellation',
            style: TextStyle(
              color: _valid
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFFFF6B6B).withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scheduled banner
// ---------------------------------------------------------------------------

class _CancellationScheduledBanner extends StatelessWidget {
  const _CancellationScheduledBanner({required this.date});
  final DateTime date;

  String _fmt(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm + 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined,
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.7), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cancellation confirmed — service ends ${_fmt(date)}',
              style: TextStyle(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                fontSize: ESizes.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
