// Shared micro-widgets used by admin quote form and quote row files.
import 'package:raspucat/utils/constants/exports.dart';

class AdminFormSectionLabel extends StatelessWidget {
  const AdminFormSectionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: EColors.primary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    ),
  );
}

class AdminFormTextField extends StatelessWidget {
  const AdminFormTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeLabel),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
      contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm + 2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.6)),
      ),
      filled: true,
      fillColor: EColors.primary.withValues(alpha: 0.04),
    ),
  );
}

class AdminFormHeader extends StatelessWidget {
  const AdminFormHeader({super.key, required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm + 4),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
      ),
    ),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: EColors.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: ESizes.fontSizeMd,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: Icon(Icons.close, color: EColors.textSecondary, size: 20),
        ),
      ],
    ),
  );
}

class AdminFormSelectChip extends StatelessWidget {
  const AdminFormSelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? EColors.primary.withValues(alpha: 0.15)
            : EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(
          color: selected
              ? EColors.primary.withValues(alpha: 0.7)
              : EColors.primary.withValues(alpha: 0.2),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? EColors.primary : EColors.textSecondary,
          fontSize: ESizes.fontSizeLabel,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
}

class AdminFormPriceRow extends StatelessWidget {
  const AdminFormPriceRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel,
      )),
      Text(value, style: const TextStyle(
        color: EColors.textWhite,
        fontSize: ESizes.fontSizeLabel,
        fontWeight: FontWeight.w600,
      )),
    ],
  );
}

class AdminActionButton extends StatelessWidget {
  const AdminActionButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => NeonButton(
    onTap: isLoading ? null : onTap,
    neonColor: color,
    padding: const EdgeInsets.symmetric(
      horizontal: ESizes.md,
      vertical: ESizes.sm,
    ),
    child: isLoading
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(color: color, strokeWidth: 1.5),
          )
        : Text(
            label,
            style: TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
  );
}
