import 'package:raspucat/utils/constants/exports.dart';
import '_discovery_summary_card.dart';
export '_discovery_summary_card.dart';

// Layout helpers and read-only confirmation view for the discovery form.

// ─── Layout helpers ───────────────────────────────────────────────────────────

class DiscoveryIntro extends StatelessWidget {
  const DiscoveryIntro({required this.businessName});
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeonText(
          text: 'Discovery Form',
          neonColor: EColors.gold,
          isHeadline: false,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: ESizes.sm),
        Text(
          'Complete this form to kick off your project, $businessName. '
          'It takes about 5 minutes and sets the foundation for everything we build.',
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.6),
            fontSize: ESizes.fontSizeSm,
            height: 1.6,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        Text(
          '* Personality is required. All other fields are optional but encouraged.',
          style: TextStyle(
            color: EColors.gold.withValues(alpha: 0.7),
            fontSize: ESizes.fontSizeLabel,
          ),
        ),
      ],
    );
  }
}

class DiscoveryFormSection extends StatelessWidget {
  const DiscoveryFormSection(this.title, this.subtitle, {required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: EColors.primary.withValues(alpha: 0.7),
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.45),
                fontSize: ESizes.fontSizeSm,
              ),
            ),
          ],
          const SizedBox(height: ESizes.md),
          child,
        ],
      ),
    );
  }
}

class DiscoverySubLabel extends StatelessWidget {
  const DiscoverySubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: EColors.textSecondary.withValues(alpha: 0.55),
      fontSize: ESizes.fontSizeLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

class DiscoverySubmitButton extends StatelessWidget {
  const DiscoverySubmitButton({
    required this.canSubmit,
    required this.submitting,
    required this.onTap,
  });
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeonButton(
          onTap: canSubmit && !submitting ? onTap : null,
          padding: const EdgeInsets.symmetric(vertical: ESizes.md),
          child: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  'Submit Discovery Form',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: canSubmit
                        ? EColors.textWhite
                        : EColors.textSecondary.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                    fontSize: ESizes.fontSizeMd,
                  ),
                ),
        ),
        if (!canSubmit) ...[
          const SizedBox(height: ESizes.sm),
          Text(
            'Select a personality (Section 1) to enable submit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EColors.gold.withValues(alpha: 0.6),
              fontSize: ESizes.fontSizeLabel,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Read-only confirmation view ──────────────────────────────────────────────

class DiscoveryReadOnlyView extends StatelessWidget {
  const DiscoveryReadOnlyView({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: EColors.primary, size: 22),
                const SizedBox(width: ESizes.sm),
                NeonText(
                  text: 'Discovery Form Submitted',
                  neonColor: EColors.primary,
                  isHeadline: false,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: ESizes.sm),
            Text(
              "We've received your answers and will be in touch to schedule a discovery session.",
              style: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.55),
                fontSize: ESizes.fontSizeSm,
                height: 1.6,
              ),
            ),
            const SizedBox(height: ESizes.xl),
            DiscoverySummaryCard(data: data),
            const SizedBox(height: ESizes.xl),
            Container(
              padding: const EdgeInsets.all(ESizes.md),
              decoration: BoxDecoration(
                color: EColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
              ),
              child: Text(
                "Need to make changes? Contact us and we'll update your form.",
                style: TextStyle(
                  color: EColors.textSecondary.withValues(alpha: 0.45),
                  fontSize: ESizes.fontSizeSm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
