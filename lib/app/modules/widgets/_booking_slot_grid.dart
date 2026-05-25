part of 'booking_widget.dart';

class _BookingSlotGrid extends StatelessWidget {
  const _BookingSlotGrid({required this.controller, this.onSlotSelected});

  final BookingController controller;
  final VoidCallback? onSlotSelected;

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedDate.value == null) {
        return const SizedBox.shrink();
      }

      if (controller.isLoadingSlots.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(ESizes.lg),
            child: CircularProgressIndicator(color: EColors.primary, strokeWidth: 1.5),
          ),
        );
      }

      if (controller.errorMessage.value != null) {
        return Padding(
          padding: const EdgeInsets.all(ESizes.md),
          child: Text(
            controller.errorMessage.value!,
            style: const TextStyle(color: Colors.redAccent, fontSize: ESizes.fontSizeLabel),
          ),
        );
      }

      final slots = controller.slots;
      if (slots.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(ESizes.md),
          decoration: BoxDecoration(
            color: EColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            border: Border.all(color: EColors.primary.withValues(alpha: 0.15)),
          ),
          child: const Text(
            'No slots available for this day.',
            style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSizeSm),
            textAlign: TextAlign.center,
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: ESizes.sm,
          mainAxisSpacing: ESizes.sm,
          childAspectRatio: 3.0,
        ),
        itemCount: slots.length,
        itemBuilder: (_, i) {
          final slot = slots[i];
          final isSelected = controller.selectedSlot.value?.startAt == slot.startAt;
          return _SlotTile(
            label: _formatTime(slot.startAt),
            isSelected: isSelected,
            onTap: () {
              controller.selectSlot(slot);
              onSlotSelected?.call();
            },
          );
        },
      );
    });
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? EColors.primary : EColors.textWhite,
            fontSize: ESizes.fontSizeSm,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
