import 'package:raspucat/app/controllers/portal_controller.dart';
import 'package:raspucat/app/data/models/portal_quote_model.dart';
import 'package:raspucat/app/modules/widgets/_portal_dashboard_plan_card.dart';
import 'package:raspucat/app/modules/widgets/_portal_dashboard_quick_links.dart';
import 'package:raspucat/app/modules/widgets/portal_cancel_button.dart';
import 'package:raspucat/app/modules/widgets/portal_discovery_form.dart';
import 'package:raspucat/app/modules/widgets/portal_manage_billing_button.dart';
import 'package:raspucat/app/modules/widgets/portal_stage_pill.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PortalDashboard extends StatelessWidget {
  const PortalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PortalController>();
    return Obx(() {
      final quote = ctrl.activeQuote;
      if (quote == null) return const SizedBox.shrink();

      // Show discovery form full-width until client submits it
      if (quote.portalStage == 'awaiting_discovery') {
        return PortalDiscoveryForm(quote: quote);
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(ESizes.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(businessName: quote.businessName, ctrl: ctrl),
              const SizedBox(height: ESizes.xl),
              PortalStagePill(quote: quote, large: true),
              const SizedBox(height: ESizes.xl),
              _StatsRow(quote: quote),
              if (quote.subscriptionStartedAt != null || quote.status == 'deposit_paid') ...[
                const SizedBox(height: ESizes.md),
                PortalManageBillingButton(ctrl: ctrl),
                const SizedBox(height: ESizes.sm),
                PortalCancelButton(ctrl: ctrl, quote: quote),
              ],
              const SizedBox(height: ESizes.xl),
              _SectionLabel('Quick Access'),
              const SizedBox(height: ESizes.md),
              PortalDashboardQuickLinksGrid(ctrl: ctrl),
              const SizedBox(height: ESizes.xl),
              _SectionLabel('Plan Summary'),
              const SizedBox(height: ESizes.md),
              PortalDashboardPlanCard(quote: quote),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.businessName, required this.ctrl});
  final String businessName;
  final PortalController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.5),
            fontSize: ESizes.fontSizeSm,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        NeonText(
          text: businessName,
          neonColor: EColors.primary,
          isHeadline: false,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.quote});
  final PortalQuote quote;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Project Total',
            value: quote.formattedSetupTotal,
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: ESizes.md),
        Expanded(
          child: _StatCard(label: 'Plan', value: quote.planLabel, icon: Icons.layers_outlined),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESizes.lg),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EColors.primary.withValues(alpha: 0.6), size: 18),
          const SizedBox(height: ESizes.sm),
          Text(
            value,
            style: const TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeMd,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.45),
              fontSize: ESizes.fontSizeLabel,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: EColors.textSecondary.withValues(alpha: 0.4),
        fontSize: ESizes.fontSizeLabel,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}
