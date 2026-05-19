import 'package:get/get.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_catalog_controller.dart';
import 'package:raspucat/app/modules/widgets/admin_quote_form_body.dart';
import 'package:raspucat/app/modules/widgets/admin_form_widgets.dart';

/// Scrollable field section for [AdminQuoteFormModal].
/// Extracted to keep the parent file under the 300-line limit.
class AdminQuoteFormFields extends StatelessWidget {
  const AdminQuoteFormFields({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.businessCtrl,
    required this.handoffFeeCtrl,
    required this.catalogCtrl,
    required this.selectedPlanId,
    required this.selectedModuleIds,
    required this.selectedMgmtId,
    required this.selectedBillingCycle,
    required this.isComped,
    required this.isEdit,
    required this.submitting,
    required this.error,
    required this.onPlanSelected,
    required this.onModuleToggled,
    required this.onMgmtSelected,
    required this.onBillingSelected,
    required this.onSubmit,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController businessCtrl;
  final TextEditingController handoffFeeCtrl;
  final AdminCatalogController catalogCtrl;
  final String? selectedPlanId;
  final Set<String> selectedModuleIds;
  final String? selectedMgmtId;
  final String? selectedBillingCycle;
  final RxBool isComped;
  final bool isEdit;
  final bool submitting;
  final String? error;
  final ValueChanged<Map<String, dynamic>> onPlanSelected;
  final ValueChanged<String> onModuleToggled;
  final ValueChanged<Map<String, dynamic>> onMgmtSelected;
  final ValueChanged<String> onBillingSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminFormSectionLabel('Client Details'),
          const SizedBox(height: 8),
          AdminFormTextField(controller: nameCtrl, hint: 'Full Name'),
          const SizedBox(height: 8),
          AdminFormTextField(
            controller: emailCtrl,
            hint: 'Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          AdminFormTextField(controller: businessCtrl, hint: 'Business Name (optional)'),
          const SizedBox(height: 8),
          AdminFormTextField(
            controller: handoffFeeCtrl,
            hint: 'Handoff fee \$ (0 = included)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: ESizes.md),
          AdminQuoteFormBody(
            ctrl: catalogCtrl,
            selectedPlanId: selectedPlanId,
            selectedModuleIds: selectedModuleIds,
            selectedMgmtId: selectedMgmtId,
            selectedBillingCycle: selectedBillingCycle,
            isComped: isComped,
            onPlanSelected: onPlanSelected,
            onModuleToggled: onModuleToggled,
            onMgmtSelected: onMgmtSelected,
            onBillingSelected: onBillingSelected,
          ),
          const SizedBox(height: ESizes.md),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error!,
                style: const TextStyle(color: Color(0xFFFF4D4D), fontSize: ESizes.fontSizeLabel),
              ),
            ),
          NeonButton(
            width: double.infinity,
            onTap: submitting ? null : onSubmit,
            neonColor: EColors.primary,
            padding: const EdgeInsets.symmetric(vertical: ESizes.md),
            child: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
                  )
                : Text(
                    isEdit ? 'Save Changes' : 'Create Quote',
                    style: const TextStyle(
                      color: EColors.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: ESizes.fontSizeMd,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
