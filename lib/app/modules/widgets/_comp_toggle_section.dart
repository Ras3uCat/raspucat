import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:raspucat/utils/constants/exports.dart';

/// Admin-only toggle for comping a project (waives deposit + Stripe flow).
/// Accepts an [RxBool] owned by the parent form state.
class CompToggleSection extends StatelessWidget {
  const CompToggleSection({super.key, required this.isComped});

  final RxBool isComped;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: isComped.value ? EColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(
            color: isComped.value
                ? EColors.primary.withValues(alpha: 0.35)
                : EColors.primary.withValues(alpha: 0.12),
          ),
        ),
        child: SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.xs),
          title: Text(
            'Comp this project',
            style: TextStyle(
              color: isComped.value ? EColors.primary : EColors.textSecondary,
              fontSize: ESizes.fontSizeMd,
              fontWeight: isComped.value ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            'Waives deposit — client skips payment step.',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
          ),
          value: isComped.value,
          onChanged: (v) => isComped.value = v,
          activeColor: EColors.primary,
        ),
      ),
    );
  }
}
