part of 'admin_availability_widget.dart';

const _kDayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

class _AdminScheduleEditor extends StatefulWidget {
  const _AdminScheduleEditor({required this.ctrl});
  final AdminAvailabilityController ctrl;

  @override
  State<_AdminScheduleEditor> createState() => _AdminScheduleEditorState();
}

class _AdminScheduleEditorState extends State<_AdminScheduleEditor> {
  late List<AvailabilityRule> _draft;

  @override
  void initState() {
    super.initState();
    _draft = List.from(widget.ctrl.rules);
  }

  void _toggleDay(int index, bool value) {
    setState(() {
      _draft[index] = _draft[index].copyWith(enabled: value);
    });
  }

  void _setTime(int index, bool isStart, String time) {
    setState(() {
      _draft[index] = isStart
          ? _draft[index].copyWith(startTime: time)
          : _draft[index].copyWith(endTime: time);
    });
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final current = isStart ? _draft[index].startTime : _draft[index].endTime;
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _setTime(index, isStart, formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_draft.length, (i) {
          final rule = _draft[i];
          return _DayRow(
            dayName: _kDayNames[rule.dayOfWeek],
            enabled: rule.enabled,
            startTime: rule.startTime,
            endTime: rule.endTime,
            onToggle: (v) => _toggleDay(i, v),
            onPickStart: () => _pickTime(i, true),
            onPickEnd: () => _pickTime(i, false),
          );
        }),
        const SizedBox(height: ESizes.md),
        Obx(
          () => NeonButton(
            onTap: widget.ctrl.isLoading.value ? null : () => widget.ctrl.saveRules(_draft),
            padding: const EdgeInsets.symmetric(vertical: ESizes.sm, horizontal: ESizes.md),
            child: widget.ctrl.isLoading.value
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: EColors.primary),
                  )
                : const Text(
                    'SAVE SCHEDULE',
                    style: TextStyle(
                      color: EColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      fontSize: ESizes.fontSizeSm,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.dayName,
    required this.enabled,
    required this.startTime,
    required this.endTime,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final String dayName;
  final bool enabled;
  final String startTime;
  final String endTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ESizes.xs),
      child: Row(
        children: [
          Switch(value: enabled, onChanged: onToggle, activeColor: EColors.primary),
          const SizedBox(width: ESizes.sm),
          SizedBox(
            width: 90,
            child: Text(
              dayName,
              style: TextStyle(
                color: enabled ? EColors.textWhite : EColors.textSecondary,
                fontSize: ESizes.fontSizeSm,
              ),
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: ESizes.sm),
            _TimeChip(label: startTime, onTap: onPickStart),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.xs),
              child: Text('–', style: TextStyle(color: EColors.textSecondary)),
            ),
            _TimeChip(label: endTime, onTap: onPickEnd),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: ESizes.xs),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: EColors.primary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
