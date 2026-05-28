import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';
import 'package:raspucat/app/modules/widgets/_details_step_fields.dart';

class DetailsStep extends StatefulWidget {
  const DetailsStep({super.key, required this.state, required this.formKey});

  final ConfiguratorState state;
  final GlobalKey<FormState> formKey;

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _bizCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _bizTypeCtrl;
  late final TextEditingController _promoCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.clientName);
    _emailCtrl = TextEditingController(text: widget.state.clientEmail);
    _bizCtrl = TextEditingController(text: widget.state.businessName);
    _websiteCtrl = TextEditingController(text: widget.state.businessWebsite);
    _bizTypeCtrl = TextEditingController(text: widget.state.businessType);
    _promoCtrl = TextEditingController(text: widget.state.appliedPromoCode.value);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bizCtrl.dispose();
    _websiteCtrl.dispose();
    _bizTypeCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.state.clientName = _nameCtrl.text.trim();
    widget.state.clientEmail = _emailCtrl.text.trim().toLowerCase();
    widget.state.businessName = _bizCtrl.text.trim();
    widget.state.businessWebsite = _websiteCtrl.text.trim();
    widget.state.businessType = _bizTypeCtrl.text.trim();
  }

  static String _fmt(int cents) {
    final s = (cents / 100).round().toString();
    if (s.length <= 3) return '\$$s';
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(ESizes.lg, ESizes.md, ESizes.lg, ESizes.lg),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderSummary(state: widget.state, fmt: _fmt),
            const SizedBox(height: ESizes.md),
            Text(
              'Your contact details',
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSizeSm,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: ESizes.md),
            DetailsStepField(
              controller: _nameCtrl,
              label: 'Your name',
              hint: 'Jane Smith',
              onChanged: (_) => _save(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: ESizes.sm + 4),
            DetailsStepField(
              controller: _emailCtrl,
              label: 'Email address',
              hint: 'jane@example.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _save(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                return ok ? null : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: ESizes.sm + 4),
            DetailsStepField(
              controller: _bizCtrl,
              label: 'Business name (optional)',
              hint: 'Acme Co.',
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: ESizes.sm + 4),
            DetailsStepField(
              controller: _websiteCtrl,
              label: 'Your current website (optional)',
              hint: 'https://yoursite.com',
              keyboardType: TextInputType.url,
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: ESizes.sm + 4),
            DetailsStepField(
              controller: _bizTypeCtrl,
              label: 'What kind of business? (optional)',
              hint: 'e.g. HVAC Contractor, Hair Salon',
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: ESizes.md),
            Text(
              'Promo code',
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSizeLabel,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            DetailsPromoSection(state: widget.state, promoCtrl: _promoCtrl),
            const SizedBox(height: ESizes.md),
            Text(
              'Your details are used to set up your project quote and send a payment confirmation.',
              style: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.6),
                fontSize: ESizes.fontSizeLabel,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order summary — reactive box at top of the form
// ---------------------------------------------------------------------------

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.state, required this.fmt});

  final ConfiguratorState state;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mgmt = state.selectedManagement.value;
      final isHandover = mgmt != null && mgmt.onetimePrice > 0;
      final isAnnual = state.isAnnual.value;
      final promoDiscount = state.promoDiscountCents.value;
      final appliedPromo = state.appliedPromoCode.value;
      final subPct = state.subDiscountPct.value;
      final subFixed = state.subDiscountFixed.value;
      final effectiveSetup = state.computedSetup.value - promoDiscount;
      final depositCents = (effectiveSetup / 2).floor().toInt();
      final balanceCents = effectiveSetup - depositCents;

      int discountMgmt(int full) {
        if (subPct != null) return (full * (1 - subPct / 100)).round();
        if (subFixed != null) return (full - subFixed).clamp(0, full);
        return full;
      }

      int dueOnLaunchCents = balanceCents;
      if (mgmt != null) {
        dueOnLaunchCents += isHandover
            ? mgmt.onetimePrice
            : discountMgmt(isAnnual ? mgmt.annualPrice : mgmt.monthlyPrice);
      }

      String dueOnLaunchLabel() {
        if (mgmt == null) return fmt(balanceCents);
        final balance = fmt(balanceCents);
        final fee = isHandover
            ? '${fmt(mgmt.onetimePrice)} handover'
            : isAnnual
            ? '${fmt(discountMgmt(mgmt.annualPrice))} 1st year'
            : '${fmt(discountMgmt(mgmt.monthlyPrice))} 1st month';
        return '${fmt(dueOnLaunchCents)} ($balance + $fee)';
      }

      return Container(
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                color: EColors.textWhite,
                fontSize: ESizes.fontSizeSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ESizes.sm),
            DetailsSummaryRow('Plan', state.plan.name),
            DetailsSummaryRow(
              'Modules',
              '${state.selectedAddonCount + state.plan.lockedModuleIds.length} selected',
            ),
            if (mgmt != null)
              DetailsSummaryRow(
                'Management',
                isHandover
                    ? '${mgmt.name} — ${mgmt.displayOnetime} (on delivery)'
                    : isAnnual
                    ? '${mgmt.name} — ${fmt(discountMgmt(mgmt.annualPrice))}/yr'
                    : '${mgmt.name} — ${fmt(discountMgmt(mgmt.monthlyPrice))}/mo',
              ),
            const Divider(color: Color(0x1AFFFFFF), height: ESizes.md),
            DetailsSummaryRow(
              'Setup total',
              fmt(state.computedSetup.value),
              valueColor: promoDiscount > 0 ? EColors.textSecondary : EColors.textWhite,
            ),
            if (promoDiscount > 0) ...[
              DetailsSummaryRow(
                'Promo ($appliedPromo)',
                '-${fmt(promoDiscount)}',
                valueColor: const Color(0xFF4CAF50),
              ),
              DetailsSummaryRow(
                'Discounted total',
                fmt(effectiveSetup),
                valueColor: EColors.textWhite,
              ),
            ],
            DetailsSummaryRow(
              'Due today (50% deposit)',
              fmt(depositCents),
              valueColor: EColors.gold,
            ),
            if (dueOnLaunchCents > 0) DetailsSummaryRow('Due on launch', dueOnLaunchLabel()),
          ],
        ),
      );
    });
  }
}
