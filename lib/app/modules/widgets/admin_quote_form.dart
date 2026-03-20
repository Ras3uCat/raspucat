import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_form_body.dart';
import 'package:raspucat/app/modules/widgets/admin_form_widgets.dart';

/// Create / Edit Quote modal.
/// Static `show()` handles responsive presentation (dialog vs bottom sheet).
class AdminQuoteFormModal extends StatefulWidget {
  const AdminQuoteFormModal({
    super.key,
    required this.ctrl,
    required this.catalogCtrl,
    this.existingQuote,
  });

  final AdminController ctrl;
  final AdminCatalogController catalogCtrl;
  final Map<String, dynamic>? existingQuote;

  static void show(
    BuildContext context,
    AdminController ctrl, {
    Map<String, dynamic>? existingQuote,
  }) {
    final catalogCtrl = Get.find<AdminCatalogController>();
    final isWide = MediaQuery.of(context).size.width >= 600;
    final content = AdminQuoteFormModal(
      ctrl: ctrl,
      catalogCtrl: catalogCtrl,
      existingQuote: existingQuote,
    );
    if (isWide) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: content,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: content,
        ),
      );
    }
  }

  @override
  State<AdminQuoteFormModal> createState() => _AdminQuoteFormModalState();
}

class _AdminQuoteFormModalState extends State<AdminQuoteFormModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _businessCtrl;

  String? _selectedPlanId;
  Set<String> _selectedModuleIds = {};
  String? _selectedMgmtId;
  String? _selectedBillingCycle;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.existingQuote != null;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuote;
    _nameCtrl = TextEditingController(text: q?['client_name'] as String? ?? '');
    _emailCtrl = TextEditingController(text: q?['client_email'] as String? ?? '');
    _businessCtrl = TextEditingController(text: q?['business_name'] as String? ?? '');
    if (q != null) {
      _selectedPlanId = q['plan_id'] as String?;
      final rawIds = q['module_ids'] as List<dynamic>? ?? [];
      _selectedModuleIds = rawIds.map((e) => e.toString()).toSet();
      _selectedMgmtId = q['management_option_id'] as String?;
      _selectedBillingCycle = q['billing_cycle'] as String?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

  int _calcSetupTotal() {
    final plan = widget.catalogCtrl.plans.firstWhereOrNull(
      (p) => (p as Map)['id'] == _selectedPlanId,
    ) as Map?;
    final base = plan?['setup_price'] as int? ?? 0;
    final lockedRaw = plan?['locked_module_ids'] as List<dynamic>? ?? [];
    final lockedIds = lockedRaw.map((e) => e.toString()).toSet();
    int moduleTotal = 0;
    for (final m in widget.catalogCtrl.modules) {
      final mod = m as Map;
      final id = mod['id'] as String;
      if (_selectedModuleIds.contains(id) && !lockedIds.contains(id)) {
        moduleTotal += mod['price'] as int? ?? 0;
      }
    }
    int discountPct = 0;
    if (plan?['is_custom'] == true) {
      final count = _selectedModuleIds.length;
      if (count >= 9) discountPct = 15;
      else if (count >= 6) discountPct = 10;
      else if (count >= 3) discountPct = 5;
    }
    final discountAmt = (moduleTotal * discountPct / 100).round();
    return base + moduleTotal - discountAmt;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || _selectedPlanId == null) {
      setState(() => _error = 'Name, email, and plan are required.');
      return;
    }
    final setupTotal = _calcSetupTotal();
    if (setupTotal <= 0) {
      setState(() => _error = 'Setup total must be greater than zero.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    final data = <String, dynamic>{
      'clientName': name,
      'clientEmail': email,
      'businessName': _businessCtrl.text.trim(),
      'planId': _selectedPlanId,
      'moduleIds': _selectedModuleIds.toList(),
      'managementOptionId': _selectedMgmtId,
      'billingCycle': _selectedBillingCycle,
      'setupTotalCents': setupTotal,
    };
    bool success;
    if (_isEdit) {
      success = await widget.catalogCtrl.updateQuote(
        widget.existingQuote!['id'] as String, data,
      );
    } else {
      success = await widget.catalogCtrl.createQuote(data);
    }
    if (!mounted) return;
    if (success) {
      await widget.ctrl.fetchQuotes();
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _error = _isEdit ? 'Failed to update quote.' : 'Failed to create quote.';
      });
    }
  }

  void _onPlanSelected(Map<String, dynamic> plan) {
    final lockedRaw = plan['locked_module_ids'] as List<dynamic>? ?? [];
    setState(() {
      _selectedPlanId = plan['id'] as String;
      _selectedModuleIds = lockedRaw.map((e) => e.toString()).toSet();
    });
  }

  void _onModuleToggled(String moduleId) {
    setState(() {
      if (_selectedModuleIds.contains(moduleId)) {
        _selectedModuleIds = {..._selectedModuleIds}..remove(moduleId);
      } else {
        _selectedModuleIds = {..._selectedModuleIds, moduleId};
      }
    });
  }

  void _onMgmtSelected(Map<String, dynamic> option) {
    final isHandover = (option['name'] as String? ?? '').toLowerCase().contains('handover');
    setState(() {
      _selectedMgmtId = option['id'] as String;
      _selectedBillingCycle = isHandover ? 'onetime' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
      decoration: BoxDecoration(
        color: EColors.backgroundDark,
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminFormHeader(
            title: _isEdit ? 'Edit Quote' : 'New Quote',
            onClose: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminFormSectionLabel('Client Details'),
                  const SizedBox(height: 8),
                  AdminFormTextField(controller: _nameCtrl, hint: 'Full Name'),
                  const SizedBox(height: 8),
                  AdminFormTextField(
                    controller: _emailCtrl,
                    hint: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  AdminFormTextField(controller: _businessCtrl, hint: 'Business Name (optional)'),
                  const SizedBox(height: ESizes.md),
                  AdminQuoteFormBody(
                    ctrl: widget.catalogCtrl,
                    selectedPlanId: _selectedPlanId,
                    selectedModuleIds: _selectedModuleIds,
                    selectedMgmtId: _selectedMgmtId,
                    selectedBillingCycle: _selectedBillingCycle,
                    onPlanSelected: _onPlanSelected,
                    onModuleToggled: _onModuleToggled,
                    onMgmtSelected: _onMgmtSelected,
                    onBillingSelected: (c) => setState(() => _selectedBillingCycle = c),
                  ),
                  const SizedBox(height: ESizes.md),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFFF4D4D),
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    ),
                  NeonButton(
                    width: double.infinity,
                    onTap: _submitting ? null : _submit,
                    neonColor: EColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: ESizes.md),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: EColors.primary,
                              strokeWidth: 1.5,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Save Changes' : 'Create Quote',
                            style: const TextStyle(
                              color: EColors.textWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: ESizes.fontSizeMd,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
