import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:raspucat/app/controllers/booking_controller.dart';
import 'package:raspucat/utils/constants/colors.dart';
import 'package:raspucat/utils/constants/sizes.dart';

part '_booking_slot_grid.dart';
part '_booking_day_chips.dart';

class BookingWidget extends StatelessWidget {
  const BookingWidget({super.key, required this.controller, this.onSlotSelected});

  final BookingController controller;
  final VoidCallback? onSlotSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookingDayChips(
          controller: controller,
          onDateSelected: (date) async {
            await controller.selectDate(date);
          },
        ),
        const SizedBox(height: ESizes.md),
        _BookingSlotGrid(controller: controller, onSlotSelected: onSlotSelected),
      ],
    );
  }
}
