import 'package:raspucat/utils/constants/exports.dart';
import '_admin_delivery_step_def.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.checked, required this.total, required this.done});
  final int checked;
  final int total;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = total > 0 ? checked / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                done ? 'Delivered ✓' : '$checked / $total steps complete',
                style: TextStyle(
                  color: done ? EColors.primary : EColors.textWhite,
                  fontSize: ESizes.fontSizeLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(t * 100).round()}%',
              style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeLabel),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: t,
            backgroundColor: EColors.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? EColors.primary : EColors.primary.withValues(alpha: 0.7),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class PhaseLabel extends StatelessWidget {
  const PhaseLabel(this.phase, {super.key});
  final String phase;

  @override
  Widget build(BuildContext context) => Text(
    phase.toUpperCase(),
    style: const TextStyle(
      color: EColors.primary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    ),
  );
}

class DeliveryStepRow extends StatelessWidget {
  const DeliveryStepRow({
    super.key,
    required this.def,
    required this.checked,
    required this.checkedBy,
    required this.checkedAt,
    required this.onToggle,
  });

  final DeliveryStepDef def;
  final bool checked;
  final String? checkedBy;
  final String? checkedAt;
  final void Function(bool)? onToggle;

  static String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = checkedBy == 'system';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 20,
            child: isSystem
                ? Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: checked ? EColors.primary : EColors.textSecondary.withValues(alpha: 0.4),
                  )
                : GestureDetector(
                    onTap: onToggle != null ? () => onToggle!(!checked) : null,
                    child: Icon(
                      checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: checked
                          ? EColors.primary
                          : EColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.label,
                  style: TextStyle(
                    color: checked
                        ? EColors.textWhite
                        : def.isAuto
                        ? EColors.gold.withValues(alpha: 0.75)
                        : EColors.textSecondary,
                    fontSize: ESizes.fontSizeLabel,
                    decoration: checked ? TextDecoration.lineThrough : null,
                    decorationColor: EColors.textSecondary,
                  ),
                ),
                if (checked && checkedAt != null)
                  Text(
                    '${isSystem ? 'System' : 'Admin'} · ${_fmtDate(checkedAt)}',
                    style: TextStyle(
                      color: EColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
