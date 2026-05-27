import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/controllers/admin_outreach_controller.dart';
import 'package:raspucat/app/data/models/lead_model.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

part '_outreach_header.dart';
part '_outreach_drafts_view.dart';
part '_outreach_pipeline_view.dart';
part '_outreach_settings_panel.dart';
part '_outreach_settings_fields.dart';
part '_outreach_chip_input.dart';
part '_lead_detail_panel.dart';
part '_lead_detail_sections.dart';
part '_lead_detail_actions.dart';
part '_lead_form_dialog.dart';
part '_outreach_compose_panel.dart';

class AdminOutreachWidget extends StatelessWidget {
  const AdminOutreachWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminOutreachController>();
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.leads.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(ESizes.xl),
            child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OutreachHeader(ctrl: ctrl),
          if (ctrl.errorMessage.value != null)
            _StatusBanner(
              message: ctrl.errorMessage.value!,
              isError: true,
              onDismiss: () => ctrl.errorMessage.value = null,
            ),
          if (ctrl.successMessage.value != null)
            _StatusBanner(
              message: ctrl.successMessage.value!,
              isError: false,
              onDismiss: () => ctrl.successMessage.value = null,
            ),
          const SizedBox(height: ESizes.md),
          Expanded(child: _OutreachSubTabBody(ctrl: ctrl)),
        ],
      );
    });
  }
}

class _OutreachSubTabBody extends StatelessWidget {
  const _OutreachSubTabBody({required this.ctrl});
  final AdminOutreachController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (ctrl.activeSubTab.value) {
        case 0:
          return _OutreachPipelineView(ctrl: ctrl);
        case 1:
          return _OutreachDraftsView(ctrl: ctrl);
        case 2:
          return _OutreachSettingsPanel(ctrl: ctrl);
        default:
          return _OutreachPipelineView(ctrl: ctrl);
      }
    });
  }
}
