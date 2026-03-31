import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';

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
  late final TextEditingController _promoCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.clientName);
    _emailCtrl = TextEditingController(text: widget.state.clientEmail);
    _bizCtrl = TextEditingController(text: widget.state.businessName);
    _promoCtrl = TextEditingController(text: widget.state.appliedPromoCode.value);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bizCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.state.clientName = _nameCtrl.text.trim();
    widget.state.clientEmail = _emailCtrl.text.trim();
    widget.state.businessName = _bizCtrl.text.trim();
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
      padding: const EdgeInsets.fromLTRB(
        ESizes.lg,
        ESizes.md,
        ESizes.lg,
        ESizes.lg,
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary — reactive to state changes
            Obx(() {
              final state = widget.state;
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
                if (mgmt == null) return _fmt(balanceCents);
                final balance = _fmt(balanceCents);
                final fee = isHandover
                    ? '${_fmt(mgmt.onetimePrice)} handover'
                    : isAnnual
                        ? '${_fmt(discountMgmt(mgmt.annualPrice))} 1st year'
                        : '${_fmt(discountMgmt(mgmt.monthlyPrice))} 1st month';
                return '${_fmt(dueOnLaunchCents)} ($balance + $fee)';
              }
              return Container(
              padding: const EdgeInsets.all(ESizes.md),
              decoration: BoxDecoration(
                color: EColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                border: Border.all(
                  color: EColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      color: EColors.textWhite,
                      fontSize: ESizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ESizes.sm),
                  _SummaryRow('Plan', state.plan.name),
                  _SummaryRow(
                    'Modules',
                    '${state.selectedAddonCount + state.plan.lockedModuleIds.length} selected',
                  ),
                  if (mgmt != null)
                    _SummaryRow(
                      'Management',
                      isHandover
                          ? '${mgmt.name} — ${mgmt.displayOnetime} (on delivery)'
                          : isAnnual
                              ? '${mgmt.name} — ${_fmt(discountMgmt(mgmt.annualPrice))}/yr'
                              : '${mgmt.name} — ${_fmt(discountMgmt(mgmt.monthlyPrice))}/mo',
                    ),
                  const Divider(color: Color(0x1AFFFFFF), height: ESizes.md),
                  _SummaryRow(
                    'Setup total',
                    _fmt(state.computedSetup.value),
                    valueColor: promoDiscount > 0 ? EColors.textSecondary : EColors.textWhite,
                  ),
                  if (promoDiscount > 0) ...[
                    _SummaryRow(
                      'Promo ($appliedPromo)',
                      '-${_fmt(promoDiscount)}',
                      valueColor: const Color(0xFF4CAF50),
                    ),
                    _SummaryRow(
                      'Discounted total',
                      _fmt(effectiveSetup),
                      valueColor: EColors.textWhite,
                    ),
                  ],
                  _SummaryRow(
                    'Due today (50% deposit)',
                    _fmt(depositCents),
                    valueColor: EColors.gold,
                  ),
                  if (dueOnLaunchCents > 0)
                    _SummaryRow('Due on launch', dueOnLaunchLabel()),
                ],
              ),
            );
            }),
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
            _DetailsField(
              controller: _nameCtrl,
              label: 'Your name',
              hint: 'Jane Smith',
              onChanged: (_) => _save(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: ESizes.sm + 4),
            _DetailsField(
              controller: _emailCtrl,
              label: 'Email address',
              hint: 'jane@example.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _save(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(v.trim());
                return ok ? null : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: ESizes.sm + 4),
            _DetailsField(
              controller: _bizCtrl,
              label: 'Business name (optional)',
              hint: 'Acme Co.',
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
            Obx(() {
              final applied = widget.state.appliedPromoCode.value;
              final loading = widget.state.promoIsLoading.value;
              final error = widget.state.promoError.value;
              final discount = widget.state.promoDiscountCents.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _promoCtrl,
                          enabled: applied.isEmpty,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(
                            color: applied.isNotEmpty ? EColors.primary : EColors.textWhite,
                            fontSize: ESizes.fontSizeSm,
                            letterSpacing: 1,
                          ),
                          decoration: InputDecoration(
                            hintText: 'LAUNCH10',
                            hintStyle: TextStyle(
                              color: EColors.textSecondary.withValues(alpha: 0.4),
                              fontSize: ESizes.fontSizeSm,
                            ),
                            filled: true,
                            fillColor: EColors.primary.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: ESizes.md,
                              vertical: ESizes.sm + 4,
                            ),
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
                              borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.7), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: ESizes.sm),
                      if (applied.isEmpty)
                        NeonButton(
                          onTap: loading ? null : () => widget.state.applyPromoCode(_promoCtrl.text),
                          neonColor: EColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: ESizes.md,
                            vertical: ESizes.sm + 4,
                          ),
                          child: loading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: EColors.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Apply',
                                  style: TextStyle(
                                    color: EColors.textWhite,
                                    fontSize: ESizes.fontSizeLabel,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            _promoCtrl.clear();
                            widget.state.clearPromoCode();
                          },
                          child: const Text(
                            'Remove',
                            style: TextStyle(color: Color(0xFFFF4D4D), fontSize: ESizes.fontSizeLabel),
                          ),
                        ),
                    ],
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        error,
                        style: const TextStyle(color: Color(0xFFFF4D4D), fontSize: ESizes.fontSizeLabel),
                      ),
                    ),
                  if (applied.isNotEmpty && discount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$applied applied — ${_fmt(discount)} off',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: ESizes.fontSizeLabel,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: EColors.textSecondary,
              fontSize: ESizes.fontSizeLabel,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? EColors.textSecondary,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsField extends StatelessWidget {
  const _DetailsField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: EColors.textSecondary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            color: EColors.textWhite,
            fontSize: ESizes.fontSizeSm,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.4),
              fontSize: ESizes.fontSizeSm,
            ),
            filled: true,
            fillColor: EColors.primary.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ESizes.md,
              vertical: ESizes.sm + 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              borderSide: BorderSide(
                color: EColors.primary.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              borderSide: BorderSide(
                color: EColors.primary.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              borderSide: BorderSide(
                color: EColors.primary.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              borderSide: const BorderSide(color: Color(0xFFFF4D4D)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFFF4D4D),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFF4D4D)),
          ),
        ),
      ],
    );
  }
}
