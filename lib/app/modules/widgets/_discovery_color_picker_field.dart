import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:raspucat/utils/constants/exports.dart';
import 'portal_discovery_fields.dart';

class DiscoveryColorPickerField extends StatelessWidget {
  const DiscoveryColorPickerField(
    this.label,
    this.controller,
    this.dataKey, {
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String dataKey;
  final ValueChanged<String> onChanged;

  Color? _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return null;
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  void _openPicker(BuildContext context) {
    Color current = _parseHex(controller.text) ?? EColors.primary;
    showDialog<void>(
      context: context,
      builder: (_) => _ColorPickerDialog(
        initial: current,
        onPicked: (c) {
          final hex = c.toARGB32().toRadixString(16).substring(2).toUpperCase();
          controller.text = hex;
          onChanged(hex);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Row(
        children: [
          Expanded(
            child: DiscoveryLabeledField(
              label,
              controller,
              hint: 'e.g. 1A2B3C',
              maxLength: 7,
              onChanged: (v) {
                final clean = v.replaceAll('#', '').toUpperCase();
                if (controller.text != clean) {
                  controller.value = controller.value.copyWith(text: clean);
                }
                onChanged(clean);
              },
            ),
          ),
          const SizedBox(width: ESizes.sm),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, __, ___) {
              final c = _parseHex(controller.text);
              return GestureDetector(
                onTap: () => _openPicker(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c ?? EColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: c == null
                      ? Icon(
                          Icons.colorize,
                          size: 14,
                          color: EColors.primary.withValues(alpha: 0.4),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.onPicked});
  final Color initial;
  final ValueChanged<Color> onPicked;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        side: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _current,
          onColorChanged: (c) => setState(() => _current = c),
          pickerAreaHeightPercent: 0.7,
          hexInputBar: true,
          labelTypes: const [],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.5)),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onPicked(_current);
            Navigator.of(context).pop();
          },
          child: const Text('OK', style: TextStyle(color: EColors.primary)),
        ),
      ],
    );
  }
}
