// ignore: avoid_web_libraries_in_flutter
import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';
import 'package:raspucat/app/data/services/stripe_payment_service.dart';

class PaymentStep extends StatefulWidget {
  const PaymentStep({super.key, required this.state});

  final ConfiguratorState state;

  @override
  State<PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<PaymentStep> {
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      StripePaymentService.registerViewFactory();
      WidgetsBinding.instance.addPostFrameCallback((_) => _mountStripe());
    }
  }

  void _mountStripe() {
    final secret = widget.state.clientSecret.value;
    const publishableKey = EEnv.stripePublishableKey;
    if (secret.isEmpty || publishableKey.isEmpty) return;
    if (mounted) setState(() => _mounted = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StripePaymentService.mountPaymentElement(publishableKey, secret);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text(
          'Payment is only available on web.',
          style: TextStyle(color: EColors.textSecondary),
        ),
      );
    }

    return Obx(() {
      final error = widget.state.errorMessage.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.md, ESizes.lg, ESizes.sm),
            child: Text(
              'Enter your payment details',
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSizeSm,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(ESizes.lg, 0, ESizes.lg, ESizes.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                  border: Border.all(color: const Color(0xFFFF4D4D).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF4D4D), size: 16),
                    const SizedBox(width: ESizes.sm),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: Color(0xFFFF4D4D),
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(ESizes.lg, 0, ESizes.lg, ESizes.sm),
                  child: const HtmlElementView(viewType: 'stripe-payment-element'),
                ),
                if (!_mounted)
                  const Center(
                    child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
