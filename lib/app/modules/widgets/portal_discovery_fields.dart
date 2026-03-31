import 'package:raspucat/utils/constants/exports.dart';

// Reusable form input widgets for the discovery form (portal + admin).

class DiscoveryLabeledField extends StatelessWidget {
  const DiscoveryLabeledField(
    this.label,
    this.controller, {
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: EColors.textSecondary.withValues(alpha: 0.5),
            fontSize: ESizes.fontSizeLabel,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.25),
              fontSize: ESizes.fontSizeSm,
            ),
            counterStyle: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.3),
              fontSize: 10,
            ),
            filled: true,
            fillColor: EColors.primary.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.5)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class DiscoveryHexField extends StatelessWidget {
  const DiscoveryHexField(this.label, this.controller, this.dataKey, {required this.onChanged});
  final String label;
  final TextEditingController controller;
  final String dataKey;
  final ValueChanged<String> onChanged;

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
                if (controller.text != clean)
                  controller.value = controller.value.copyWith(text: clean);
                onChanged(clean);
              },
            ),
          ),
          const SizedBox(width: ESizes.sm),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, __, ___) {
              Color? c;
              final h = controller.text.replaceAll('#', '');
              if (h.length == 6)
                try {
                  c = Color(int.parse('FF$h', radix: 16));
                } catch (_) {}
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c ?? EColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DiscoveryRadioGroup extends StatelessWidget {
  const DiscoveryRadioGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ESizes.sm,
      runSpacing: ESizes.sm,
      children: options.map((o) {
        final active = selected == o.$1;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
            decoration: BoxDecoration(
              color: active
                  ? EColors.primary.withValues(alpha: 0.12)
                  : EColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
              border: Border.all(
                color: active
                    ? EColors.primary.withValues(alpha: 0.6)
                    : EColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              o.$2,
              style: TextStyle(
                color: active ? EColors.primary : EColors.textSecondary.withValues(alpha: 0.6),
                fontSize: ESizes.fontSizeSm,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DiscoveryTimezoneDropdown extends StatelessWidget {
  const DiscoveryTimezoneDropdown({
    required this.value,
    required this.timezones,
    required this.onChanged,
  });
  final String? value;
  final List<String> timezones;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md),
      decoration: BoxDecoration(
        color: EColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: timezones.contains(value) ? value : null,
          hint: Text(
            'Select timezone',
            style: TextStyle(
              color: EColors.textSecondary.withValues(alpha: 0.3),
              fontSize: ESizes.fontSizeSm,
            ),
          ),
          dropdownColor: const Color(0xFF0D1117),
          style: const TextStyle(color: EColors.textWhite, fontSize: ESizes.fontSizeSm),
          isExpanded: true,
          items: timezones.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class DiscoveryHoursGrid extends StatelessWidget {
  const DiscoveryHoursGrid({required this.days, required this.hours, required this.onChanged});
  final List<String> days;
  final Map<String, Map<String, dynamic>> hours;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: days.map((day) {
        final h = hours[day]!;
        final isClosed = h['closed'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: ESizes.xs),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  day.substring(0, 3),
                  style: TextStyle(
                    color: EColors.textSecondary.withValues(alpha: 0.55),
                    fontSize: ESizes.fontSizeSm,
                  ),
                ),
              ),
              Checkbox(
                value: isClosed,
                onChanged: (v) {
                  h['closed'] = v ?? false;
                  onChanged();
                },
                activeColor: EColors.primary,
                side: BorderSide(color: EColors.primary.withValues(alpha: 0.3)),
              ),
              Text(
                'Closed',
                style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.4), fontSize: 11),
              ),
              if (!isClosed) ...[
                const SizedBox(width: ESizes.sm),
                Expanded(
                  child: _TimeInput(h['open'] as String, (v) {
                    h['open'] = v;
                    onChanged();
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.xs),
                  child: Text(
                    '–',
                    style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.4)),
                  ),
                ),
                Expanded(
                  child: _TimeInput(h['close'] as String, (v) {
                    h['close'] = v;
                    onChanged();
                  }),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimeInput extends StatelessWidget {
  const _TimeInput(this.value, this.onChanged);
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      style: const TextStyle(color: EColors.textWhite, fontSize: 12),
      decoration: InputDecoration(
        filled: true,
        fillColor: EColors.primary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.4)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}
