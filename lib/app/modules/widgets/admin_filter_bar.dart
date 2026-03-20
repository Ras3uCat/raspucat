import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/controllers/admin_controller.dart';

class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({super.key, required this.ctrl});

  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ESizes.xl,
        ESizes.sm,
        ESizes.xl,
        ESizes.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            onChanged: (v) => ctrl.searchQuery.value = v,
            style: const TextStyle(
              color: EColors.textWhite,
              fontSize: ESizes.fontSizeSm,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              hintStyle: TextStyle(
                color: EColors.textSecondary.withValues(alpha: 0.5),
                fontSize: ESizes.fontSizeSm,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: EColors.textSecondary.withValues(alpha: 0.5),
                size: 18,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ESizes.md,
                vertical: ESizes.sm,
              ),
              filled: true,
              fillColor: EColors.primary.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                borderSide:
                    BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                borderSide:
                    BorderSide(color: EColors.primary.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                borderSide: BorderSide(
                  color: EColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: ESizes.sm),
          // Plans/Modules row
          _FilterRowLabel('Plans/Modules'),
          const SizedBox(height: 4),
          Obx(() => Wrap(
            spacing: ESizes.xs,
            runSpacing: ESizes.xs,
            children: [
              _FilterChip(
                label: 'All',
                selected: ctrl.statusFilter.value == 'all',
                onTap: () => ctrl.statusFilter.value = 'all',
              ),
              _FilterChip(
                label: 'Pending',
                selected: ctrl.statusFilter.value == 'pending',
                onTap: () => ctrl.statusFilter.value = 'pending',
              ),
              _FilterChip(
                label: 'Deposit Paid',
                selected: ctrl.statusFilter.value == 'deposit_paid',
                onTap: () => ctrl.statusFilter.value = 'deposit_paid',
              ),
              _FilterChip(
                label: 'Fully Paid',
                selected: ctrl.statusFilter.value == 'fully_paid',
                onTap: () => ctrl.statusFilter.value = 'fully_paid',
              ),
            ],
          )),
          const SizedBox(height: ESizes.sm),
          // Subscriptions row
          _FilterRowLabel('Subscriptions'),
          const SizedBox(height: 4),
          Obx(() => Wrap(
            spacing: ESizes.xs,
            runSpacing: ESizes.xs,
            children: [
              _FilterChip(
                label: 'All',
                selected: ctrl.billingFilter.value == 'all',
                onTap: () => ctrl.billingFilter.value = 'all',
              ),
              _FilterChip(
                label: 'Monthly',
                selected: ctrl.billingFilter.value == 'monthly',
                onTap: () => ctrl.billingFilter.value = 'monthly',
              ),
              _FilterChip(
                label: 'Yearly',
                selected: ctrl.billingFilter.value == 'annual',
                onTap: () => ctrl.billingFilter.value = 'annual',
              ),
              _FilterChip(
                label: 'Handover',
                selected: ctrl.billingFilter.value == 'onetime',
                onTap: () => ctrl.billingFilter.value = 'onetime',
              ),
            ],
          )),
        ],
      ),
    );
  }
}

class _FilterRowLabel extends StatelessWidget {
  const _FilterRowLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: EColors.textSecondary.withValues(alpha: 0.6),
        fontSize: ESizes.fontSizeLabel,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? EColors.primary : EColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? EColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.5 : 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
