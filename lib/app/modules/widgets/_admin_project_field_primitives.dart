import 'package:raspucat/utils/constants/exports.dart';

const _kStatuses = ['planning', 'development', 'beta', 'live', 'paused'];

class AdminProjectField extends StatelessWidget {
  const AdminProjectField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
        hintStyle: TextStyle(
          color: EColors.textSecondary.withValues(alpha: 0.5),
          fontSize: ESizes.fontSizeSm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.error),
        ),
        filled: true,
        fillColor: EColors.backgroundDark.withValues(alpha: 0.4),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}

class AdminProjectStatusDropdown extends StatelessWidget {
  const AdminProjectStatusDropdown({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: EColors.circuitSlate,
      style: const TextStyle(color: EColors.cyanTintedWhite, fontSize: ESizes.fontSizeSm),
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          borderSide: const BorderSide(color: EColors.primary),
        ),
        filled: true,
        fillColor: EColors.backgroundDark.withValues(alpha: 0.4),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
      ),
      items: _kStatuses
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                s[0].toUpperCase() + s.substring(1),
                style: const TextStyle(color: EColors.cyanTintedWhite),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}
