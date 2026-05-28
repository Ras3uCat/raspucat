import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';

// Shared field widget used by DetailsStep and the promo section.
class DetailsStepField extends StatelessWidget {
  const DetailsStepField({
    super.key,
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
          style: const TextStyle(
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
          style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              borderSide: const BorderSide(color: Color(0xFFFF4D4D)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 1.5),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFF4D4D)),
          ),
        ),
      ],
    );
  }
}

class DetailsSummaryRow extends StatelessWidget {
  const DetailsSummaryRow(this.label, this.value, {super.key, this.valueColor});

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
            style: const TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
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

// Promo code row + feedback — extracted to keep DetailsStep under 300 lines.
class DetailsPromoSection extends StatelessWidget {
  const DetailsPromoSection({super.key, required this.state, required this.promoCtrl});

  final ConfiguratorState state;
  final TextEditingController promoCtrl;

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
    return Obx(() {
      final applied = state.appliedPromoCode.value;
      final loading = state.promoIsLoading.value;
      final error = state.promoError.value;
      final discount = state.promoDiscountCents.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: promoCtrl,
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
                      borderSide: BorderSide(
                        color: EColors.primary.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ESizes.sm),
              if (applied.isEmpty)
                NeonButton(
                  onTap: loading ? null : () => state.applyPromoCode(promoCtrl.text),
                  neonColor: EColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ESizes.md,
                    vertical: ESizes.sm + 4,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 2),
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
                    promoCtrl.clear();
                    state.clearPromoCode();
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
    });
  }
}
