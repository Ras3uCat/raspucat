part of 'admin_outreach_widget.dart';

class _ChipMultiInput extends StatelessWidget {
  const _ChipMultiInput({
    required this.label,
    required this.chips,
    required this.inputCtrl,
    required this.onAdd,
    required this.onRemove,
    this.warningCheck,
    this.warningTooltip,
  });
  final String label;
  final List<String> chips;
  final TextEditingController inputCtrl;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final bool Function(String)? warningCheck;
  final String? warningTooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: EColors.softGrey,
            fontSize: ESizes.fontSizeLabel,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: ESizes.sm,
          runSpacing: ESizes.sm,
          children: [
            ...chips.map((c) {
              final hasWarning = warningCheck?.call(c) ?? false;
              return GestureDetector(
                onTap: () => onRemove(c),
                child: Tooltip(
                  message: hasWarning ? (warningTooltip ?? '') : '',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasWarning
                          ? Colors.amber.withAlpha(20)
                          : EColors.primary.withAlpha(20),
                      border: Border.all(
                        color: hasWarning
                            ? Colors.amber.withAlpha(128)
                            : EColors.primary.withAlpha(77),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasWarning) ...[
                          const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.amber),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          c,
                          style: TextStyle(
                            color: hasWarning ? Colors.amber : EColors.primary,
                            fontSize: ESizes.fontSizeLabel,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          size: 12,
                          color: hasWarning ? Colors.amber : EColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(
              width: 140,
              child: TextField(
                controller: inputCtrl,
                style: const TextStyle(
                  color: EColors.cyanTintedWhite,
                  fontSize: ESizes.fontSizeLabel,
                ),
                decoration: InputDecoration(
                  hintText: 'Add...',
                  hintStyle: TextStyle(color: EColors.softGrey.withAlpha(128)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  final trimmed = v.trim();
                  if (trimmed.isNotEmpty) {
                    onAdd(trimmed);
                    inputCtrl.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
