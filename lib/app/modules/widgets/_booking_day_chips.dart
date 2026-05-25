part of 'booking_widget.dart';

class _BookingDayChips extends StatelessWidget {
  const _BookingDayChips({required this.controller, required this.onDateSelected});

  final BookingController controller;
  final Future<void> Function(DateTime) onDateSelected;

  static const _dayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (i) {
      final d = today.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return SizedBox(
      height: 72,
      child: Obx(() {
        final sel = controller.selectedDate.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: ESizes.sm),
          itemBuilder: (_, i) {
            final day = days[i];
            final isSelected = sel != null && _isSameDay(sel, day);
            return _DayChip(
              day: day,
              dayLabel: _dayLabels[day.weekday % 7],
              isSelected: isSelected,
              onTap: () => onDateSelected(day),
            );
          },
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.dayLabel,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final String dayLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        decoration: BoxDecoration(
          color: isSelected
              ? EColors.primary.withValues(alpha: 0.15)
              : EColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(
            color: isSelected ? EColors.primary : EColors.primary.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                color: isSelected ? EColors.primary : EColors.textSecondary,
                fontSize: ESizes.fontSizeLabel,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: ESizes.xs),
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? EColors.primary : EColors.textWhite,
                fontSize: ESizes.fontSizeMd,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
