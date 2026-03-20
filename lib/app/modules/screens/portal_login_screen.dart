import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortalLoginScreen extends StatefulWidget {
  const PortalLoginScreen({super.key});

  @override
  State<PortalLoginScreen> createState() => _PortalLoginScreenState();
}

class _PortalLoginScreenState extends State<PortalLoginScreen> {
  final _emailCtrl = TextEditingController();
  late final PortalController _ctrl;

  bool get _isExpired =>
      Uri.base.queryParameters['expired'] == 'true';

  /// True when the URL carries magic-link callback params but no session was
  /// established — indicates the link was opened in a different browser
  /// than where it was requested (PKCE verifier mismatch).
  bool get _isWrongBrowser {
    if (Supabase.instance.client.auth.currentSession != null) return false;
    final fragment = Uri.base.fragment;
    final params = Uri.base.queryParameters;
    return fragment.contains('access_token') ||
        fragment.contains('error') ||
        params.containsKey('code') ||
        params.containsKey('error_code');
  }

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(PortalController());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(color: EColors.primary.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _GlowOrb(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.08),
              size: 400,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const M3OWBrandMark(size: 28),
                  const SizedBox(height: ESizes.xl),
                  Obx(() => _ctrl.loginSent.value
                      ? _ConfirmationCard(email: _emailCtrl.text)
                      : _LoginCard(
                          ctrl: _ctrl,
                          emailCtrl: _emailCtrl,
                          isExpired: _isExpired,
                          isWrongBrowser: _isWrongBrowser,
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login card
// ---------------------------------------------------------------------------

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.ctrl,
    required this.emailCtrl,
    required this.isExpired,
    required this.isWrongBrowser,
  });

  final PortalController ctrl;
  final TextEditingController emailCtrl;
  final bool isExpired;
  final bool isWrongBrowser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(ESizes.xl),
      decoration: BoxDecoration(
        color: EColors.backgroundDark,
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: EColors.primary.withValues(alpha: 0.08),
            blurRadius: 60,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NeonText(
            text: 'Client Portal',
            neonColor: EColors.primary,
            isHeadline: false,
            style: const TextStyle(
              fontSize: ESizes.fontSizeLg,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: ESizes.xs),
          if (isWrongBrowser) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.sm, vertical: ESizes.xs),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'For security, access links must be opened in the same browser where they were requested. Enter your email to get a new link.',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: ESizes.fontSizeSm,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: ESizes.md),
          ] else if (isExpired) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: ESizes.sm, vertical: ESizes.xs),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB703).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(
                    color: const Color(0xFFFFB703).withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Your session has expired. Enter your email to get a new link.',
                style: TextStyle(
                  color: Color(0xFFFFB703),
                  fontSize: ESizes.fontSizeSm,
                ),
              ),
            ),
            const SizedBox(height: ESizes.md),
          ] else ...[
            Text(
              'Enter your email to receive a secure access link.',
              style: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.6),
                fontSize: ESizes.fontSizeSm,
              ),
            ),
            const SizedBox(height: ESizes.lg),
          ],
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            onSubmitted: (_) => ctrl.sendMagicLink(emailCtrl.text),
            style: const TextStyle(color: EColors.textWhite),
            decoration: InputDecoration(
              hintText: 'your@email.com',
              hintStyle: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.4),
                fontSize: ESizes.fontSizeSm,
              ),
              filled: true,
              fillColor: EColors.primary.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                borderSide:
                    BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                borderSide:
                    BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                borderSide: BorderSide(
                    color: EColors.primary.withValues(alpha: 0.7), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: ESizes.sm),
          Obx(() {
            if (ctrl.loginError.value != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: ESizes.sm),
                child: Text(
                  ctrl.loginError.value!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: ESizes.fontSizeSm),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() => NeonButton(
                onTap: ctrl.loginLoading.value
                    ? null
                    : () => ctrl.sendMagicLink(emailCtrl.text),
                neonColor: EColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: ESizes.sm + 4),
                child: ctrl.loginLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: EColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Transmit Access Request',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EColors.textWhite,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirmation card
// ---------------------------------------------------------------------------

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(ESizes.xl),
      decoration: BoxDecoration(
        color: EColors.backgroundDark,
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
        border: Border.all(color: const Color(0xFF06D6A0).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06D6A0).withValues(alpha: 0.08),
            blurRadius: 60,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              color: Color(0xFF06D6A0), size: 40),
          const SizedBox(height: ESizes.md),
          const Text(
            'Signal transmitted.',
            style: TextStyle(
              color: Color(0xFF06D6A0),
              fontSize: ESizes.fontSizeLg,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: ESizes.sm),
          Text(
            'Check $email for your access link.\n${EText.magicLinkExpiry}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.6),
              fontSize: ESizes.fontSizeSm,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient glow orb
// ---------------------------------------------------------------------------

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, this.size = 500});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
