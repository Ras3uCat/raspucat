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
                _TimePicker(h['open'] as String, (v) {
                  h['open'] = v;
                  onChanged();
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ESizes.xs),
                  child: Text(
                    '–',
                    style: TextStyle(color: EColors.textSecondary.withValues(alpha: 0.4)),
                  ),
                ),
                _TimePicker(h['close'] as String, (v) {
                  h['close'] = v;
                  onChanged();
                }),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker(this.value, this.onChanged);
  final String value;
  final ValueChanged<String> onChanged;

  static const _bg = Color(0xFF0D0D1A);

  TimeOfDay _parse(String v) {
    try {
      final parts = v.trim().split(' ');
      final tp = parts[0].split(':');
      int hour = int.parse(tp[0]);
      final minute = int.parse(tp[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (hour == 12) {
        hour = isPm ? 12 : 0;
      } else if (isPm) {
        hour += 12;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _format(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pick(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _parse(value),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: EColors.primary,
            onPrimary: _bg,
            surface: _bg,
            onSurface: Colors.white,
            surfaceContainerHigh: _bg,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: _bg,
            dialBackgroundColor: EColors.primary.withValues(alpha: 0.07),
            dialHandColor: EColors.primary,
            dialTextColor: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected) ? _bg : Colors.white70,
            ),
            hourMinuteColor: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? EColors.primary.withValues(alpha: 0.18)
                  : EColors.primary.withValues(alpha: 0.05),
            ),
            hourMinuteTextColor: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected) ? EColors.primary : Colors.white70,
            ),
            dayPeriodColor: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? EColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            dayPeriodTextColor: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected) ? EColors.primary : Colors.white54,
            ),
            dayPeriodBorderSide: BorderSide(color: EColors.primary.withValues(alpha: 0.2)),
            entryModeIconColor: EColors.primary,
            helpTextStyle: TextStyle(
              color: EColors.primary.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
              side: BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
            ),
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: EColors.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) onChanged(_format(result));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.15)),
        ),
        child: Text(value, style: const TextStyle(color: EColors.textWhite, fontSize: 12)),
      ),
    );
  }
}
