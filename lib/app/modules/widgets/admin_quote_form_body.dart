import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_form_widgets.dart';

/// Plan / module / management / pricing sections of the quote form.
/// Kept in a separate file to respect the 300-line limit.
class AdminQuoteFormBody extends StatelessWidget {
  const AdminQuoteFormBody({
    super.key,
    required this.ctrl,
    required this.selectedPlanId,
    required this.selectedModuleIds,
    required this.selectedMgmtId,
    required this.selectedBillingCycle,
    required this.onPlanSelected,
    required this.onModuleToggled,
    required this.onMgmtSelected,
    required this.onBillingSelected,
  });

  final AdminCatalogController ctrl;
  final String? selectedPlanId;
  final Set<String> selectedModuleIds;
  final String? selectedMgmtId;
  final String? selectedBillingCycle;
  final ValueChanged<Map<String, dynamic>> onPlanSelected;
  final ValueChanged<String> onModuleToggled;
  final ValueChanged<Map<String, dynamic>> onMgmtSelected;
  final ValueChanged<String> onBillingSelected;

  static String _fmtCents(dynamic cents) {
    final c = cents as int? ?? 0;
    if (c == 0) return '\$0';
    final s = (c / 100).round().toString();
    if (s.length <= 3) return '\$$s';
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Set<String> _lockedIds(Map? plan) {
    final locked = plan?['locked_module_ids'] as List<dynamic>? ?? [];
    return locked.map((e) => e.toString()).toSet();
  }

  int _volumeDiscountPct(Map? plan) {
    if (plan?['is_custom'] != true) return 0;
    final count = selectedModuleIds.length;
    if (count >= 9) return 15;
    if (count >= 6) return 10;
    if (count >= 3) return 5;
    return 0;
  }

  int _calcModuleAddonTotal(Map? plan) {
    final lockedIds = _lockedIds(plan);
    int total = 0;
    for (final m in ctrl.modules) {
      final mod = m as Map;
      final id = mod['id'] as String;
      if (selectedModuleIds.contains(id) && !lockedIds.contains(id)) {
        total += mod['price'] as int? ?? 0;
      }
    }
    return total;
  }

  int _calcSetupTotal(Map? plan) {
    final base = plan?['setup_price'] as int? ?? 0;
    final moduleTotal = _calcModuleAddonTotal(plan);
    final discountPct = _volumeDiscountPct(plan);
    final discountAmt = (moduleTotal * discountPct / 100).round();
    return base + moduleTotal - discountAmt;
  }

  @override
  Widget build(BuildContext context) {
    final plan = ctrl.plans.firstWhereOrNull(
      (p) => (p as Map)['id'] == selectedPlanId,
    ) as Map?;
    final lockedIds = _lockedIds(plan);

    final selectedMgmt = ctrl.managementOptions.firstWhereOrNull(
      (o) => (o as Map)['id'] == selectedMgmtId,
    ) as Map?;
    final isHandover = (selectedMgmt?['name'] as String? ?? '').toLowerCase().contains('handover');

    final moduleAddonTotal = _calcModuleAddonTotal(plan);
    final discountPct = _volumeDiscountPct(plan);
    final discountAmt = (moduleAddonTotal * discountPct / 100).round();
    final setupTotal = _calcSetupTotal(plan);
    final deposit = (setupTotal / 2).floor();
    final balance = setupTotal - deposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Plan ──────────────────────────────────────────────────────
        const AdminFormSectionLabel('Plan'),
        const SizedBox(height: 8),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ctrl.plans.map((p) {
            final pm = p as Map;
            final id = pm['id'] as String;
            return AdminFormSelectChip(
              label: pm['name'] as String? ?? id,
              selected: id == selectedPlanId,
              onTap: () => onPlanSelected(Map<String, dynamic>.from(pm)),
            );
          }).toList(),
        )),
        const SizedBox(height: ESizes.md),

        // ── Modules ───────────────────────────────────────────────────
        const AdminFormSectionLabel('Modules'),
        const SizedBox(height: 8),
        Obx(() {
          if (ctrl.modules.isEmpty) {
            return Text(
              'No modules available.',
              style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
            );
          }
          return Column(
            children: ctrl.modules.map((m) {
              final mod = m as Map;
              final id = mod['id'] as String;
              final locked = lockedIds.contains(id);
              final checked = locked || selectedModuleIds.contains(id);
              final price = mod['price'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: locked ? null : (_) => onModuleToggled(id),
                      activeColor: EColors.primary,
                      checkColor: EColors.textWhite,
                      side: BorderSide(color: EColors.primary.withValues(alpha: 0.5)),
                    ),
                    Expanded(
                      child: Text(
                        mod['name'] as String? ?? id,
                        style: TextStyle(
                          color: locked ? EColors.textSecondary : EColors.textWhite,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ),
                    if (price > 0)
                      Text(
                        '+${_fmtCents(price)}',
                        style: TextStyle(
                          color: EColors.textSecondary,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
        const SizedBox(height: ESizes.md),

        // ── Management ────────────────────────────────────────────────
        const AdminFormSectionLabel('Management'),
        const SizedBox(height: 8),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ctrl.managementOptions.map((o) {
            final om = o as Map;
            final id = om['id'] as String;
            return AdminFormSelectChip(
              label: om['name'] as String? ?? id,
              selected: id == selectedMgmtId,
              onTap: () => onMgmtSelected(Map<String, dynamic>.from(om)),
            );
          }).toList(),
        )),
        const SizedBox(height: ESizes.md),

        // ── Billing Cycle ─────────────────────────────────────────────
        if (selectedMgmtId != null && !isHandover) ...[
          const AdminFormSectionLabel('Billing Cycle'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminFormSelectChip(
                label: 'Monthly',
                selected: selectedBillingCycle == 'monthly',
                onTap: () => onBillingSelected('monthly'),
              ),
              AdminFormSelectChip(
                label: 'Annual',
                selected: selectedBillingCycle == 'annual',
                onTap: () => onBillingSelected('annual'),
              ),
            ],
          ),
          const SizedBox(height: ESizes.md),
        ],

        // ── Price Summary ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: EColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: EColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              if (discountPct > 0) ...[
                AdminFormPriceRow('Modules subtotal', _fmtCents(moduleAddonTotal)),
                const SizedBox(height: 4),
                AdminFormPriceRow('Volume discount ($discountPct%)', '-${_fmtCents(discountAmt)}'),
                const SizedBox(height: 4),
              ],
              AdminFormPriceRow('Setup Total', _fmtCents(setupTotal)),
              const SizedBox(height: 4),
              AdminFormPriceRow('Deposit (50%)', _fmtCents(deposit)),
              const SizedBox(height: 4),
              AdminFormPriceRow('Balance', _fmtCents(balance)),
            ],
          ),
        ),
      ],
    );
  }
}
