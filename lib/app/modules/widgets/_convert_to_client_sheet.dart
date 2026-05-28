import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raspucat/app/controllers/admin_outreach_controller.dart';
import 'package:raspucat/app/controllers/plans_controller.dart';
import 'package:raspucat/app/data/models/lead_model.dart';
import 'package:raspucat/utils/constants/exports.dart';

class ConvertToClientSheet extends StatefulWidget {
  const ConvertToClientSheet({super.key, required this.lead, required this.ctrl});
  final LeadModel lead;
  final AdminOutreachController ctrl;

  @override
  State<ConvertToClientSheet> createState() => _ConvertToClientSheetState();
}

class _ConvertToClientSheetState extends State<ConvertToClientSheet> {
  String? _selectedPlanId;
  String _billingCycle = 'monthly';
  final _setupCtrl = TextEditingController(text: '0');
  bool _loading = false;

  static const _cycles = ['monthly', 'annually', 'onetime'];

  @override
  void dispose() {
    _setupCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedPlanId == null) return;
    final setupCents = ((double.tryParse(_setupCtrl.text) ?? 0) * 100).toInt();
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-convert-lead-to-quote',
        body: {
          'adminToken': widget.ctrl.adminToken,
          'leadId': widget.lead.id,
          'planId': _selectedPlanId,
          'setupTotalCents': setupCents,
          'billingCycle': _billingCycle,
        },
      );
      await widget.ctrl.updateLead(widget.lead.id, {'status': 'closed_won'});
      if (mounted) {
        Navigator.of(context).pop();
        Get.snackbar(
          'Client created',
          'Portal ready — invite sent.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Conversion failed: $e', snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static InputDecoration _fieldDec() => InputDecoration(
    filled: true,
    fillColor: EColors.primary.withValues(alpha: 0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
      borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
      borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.6)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final plans = PlansController.instance.plans;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ESizes.lg,
        ESizes.lg,
        ESizes.lg,
        MediaQuery.of(context).viewInsets.bottom + ESizes.lg,
      ),
      decoration: BoxDecoration(
        color: EColors.backgroundDark,
        border: Border(top: BorderSide(color: EColors.primary.withValues(alpha: 0.15))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(ESizes.borderRadiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Convert to Client',
            style: TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeMd,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ESizes.md),
          const Text(
            'Plan',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _selectedPlanId,
            dropdownColor: const Color(0xFF0A0E1A),
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            hint: const Text(
              'Select plan',
              style: TextStyle(color: EColors.softGrey, fontSize: ESizes.fontSizeSm),
            ),
            decoration: _fieldDec(),
            items: plans.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (v) => setState(() => _selectedPlanId = v),
          ),
          const SizedBox(height: ESizes.sm),
          const Text(
            'Setup total (\$)',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _setupCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
            decoration: _fieldDec(),
          ),
          const SizedBox(height: ESizes.sm),
          const Text(
            'Billing cycle',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: ESizes.sm,
            children: _cycles.map((c) {
              final active = c == _billingCycle;
              return GestureDetector(
                onTap: () => setState(() => _billingCycle = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? EColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
                    border: Border.all(
                      color: active
                          ? EColors.primary.withValues(alpha: 0.5)
                          : EColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: active ? EColors.primary : EColors.textSecondary,
                      fontSize: ESizes.fontSizeLabel,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: ESizes.lg),
          NeonButton(
            onTap: (_loading || _selectedPlanId == null) ? null : _confirm,
            padding: const EdgeInsets.symmetric(vertical: ESizes.md),
            child: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
                  )
                : const Text(
                    'Convert to Client',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: ESizes.fontSizeSm,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
