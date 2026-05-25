import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/controllers/admin_availability_controller.dart';
import 'package:raspucat/app/data/models/booking_model.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';
import 'package:raspucat/common/widgets/buttons/neon_button.dart';

part '_admin_availability_schedule.dart';
part '_admin_availability_blocks.dart';

class AdminAvailabilityWidget extends StatelessWidget {
  const AdminAvailabilityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminAvailabilityController>();
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.rules.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(ESizes.xl),
            child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(ESizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('// WEEKLY SCHEDULE'),
            const SizedBox(height: ESizes.md),
            _AdminScheduleEditor(ctrl: ctrl),
            const SizedBox(height: ESizes.spaceBtwSections),
            _sectionHeader('// BLOCKED TIMES'),
            const SizedBox(height: ESizes.md),
            _AdminBlocksList(ctrl: ctrl),
            const SizedBox(height: ESizes.md),
            _AdminBlockForm(ctrl: ctrl),
            if (ctrl.errorMessage.value != null)
              Padding(
                padding: const EdgeInsets.only(top: ESizes.md),
                child: Text(
                  ctrl.errorMessage.value!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: ESizes.fontSizeLabel),
                ),
              ),
            if (ctrl.successMessage.value != null)
              Padding(
                padding: const EdgeInsets.only(top: ESizes.md),
                child: Text(
                  ctrl.successMessage.value!,
                  style: const TextStyle(color: EColors.primary, fontSize: ESizes.fontSizeLabel),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _sectionHeader(String label) => Text(
    label,
    style: const TextStyle(
      color: EColors.primary,
      fontSize: ESizes.fontSizeSm,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    ),
  );
}
