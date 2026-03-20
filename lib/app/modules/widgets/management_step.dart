import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/app/modules/widgets/configurator_state.dart';

class ManagementStep extends StatelessWidget {
  const ManagementStep({
    super.key,
    required this.state,
    required this.options,
  });

  final ConfiguratorState state;
  final List<ManagementOptionModel> options;

  bool get _hasAnnualOption =>
      options.any((o) => o.onetimePrice == 0 && o.annualSavings > 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ESizes.lg,
            ESizes.md,
            ESizes.lg,
            ESizes.sm,
          ),
          child: Row(
            children: [
              Text(
                'Choose a management plan',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSizeSm,
                  letterSpacing: 0.5,
                ),
              ),
              if (_hasAnnualOption) ...[
                const Spacer(),
                Obx(() => BillingToggle(
                  isAnnual: state.isAnnual.value,
                  onChanged: (v) => state.isAnnual.value = v,
                )),
              ],
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final selectedId = state.selectedManagement.value?.id;
            final annual = state.isAnnual.value;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                ESizes.lg,
                0,
                ESizes.lg,
                ESizes.sm,
              ),
              itemCount: options.length,
              itemBuilder: (_, i) {
                final opt = options[i];
                return ManagementCard(
                  option: opt,
                  isSelected: selectedId == opt.id,
                  isAnnual: annual,
                  onTap: () => state.selectedManagement.value = opt,
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class BillingToggle extends StatelessWidget {
  const BillingToggle({super.key, required this.isAnnual, required this.onChanged});

  final bool isAnnual;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
        border: Border.all(color: EColors.primary.withValues(alpha: 0.25)),
        color: EColors.primary.withValues(alpha: 0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            label: 'Monthly',
            active: !isAnnual,
            onTap: () => onChanged(false),
          ),
          _ToggleSegment(
            label: 'Annual',
            active: isAnnual,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: ESizes.sm + 2, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd - 1),
          color: active ? EColors.primary.withValues(alpha: 0.18) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? EColors.primary : EColors.textSecondary,
            fontSize: ESizes.fontSizeLabel,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class ManagementCard extends StatelessWidget {
  const ManagementCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isAnnual,
    required this.onTap,
  });

  final ManagementOptionModel option;
  final bool isSelected;
  final bool isAnnual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: ESizes.sm),
        padding: const EdgeInsets.all(ESizes.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
          border: Border.all(
            color: isSelected
                ? EColors.primary.withValues(alpha: 0.7)
                : EColors.primary.withValues(alpha: 0.14),
            width: isSelected ? 1.5 : 1.0,
          ),
          color: isSelected
              ? EColors.primary.withValues(alpha: 0.07)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? EColors.primary : EColors.textSecondary,
                  width: 1.5,
                ),
                color: isSelected
                    ? EColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: ESizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.name,
                        style: TextStyle(
                          color: EColors.textWhite,
                          fontSize: ESizes.fontSizeMd,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        option.onetimePrice > 0
                            ? '${option.displayOnetime} one-time'
                            : isAnnual
                                ? '${option.displayAnnual}/yr'
                                : '${option.displayMonthly}/mo',
                        style: TextStyle(
                          color: EColors.gold,
                          fontSize: ESizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeLabel,
                      height: 1.4,
                    ),
                  ),
                  if (option.annualSavings > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        isAnnual
                            ? 'Saving ${option.displayAnnualSavings}/yr'
                            : 'Save ${option.displayAnnualSavings}/yr billed annually',
                        style: TextStyle(
                          color: isAnnual ? EColors.gold : EColors.primary,
                          fontSize: ESizes.fontSizeLabel,
                          fontWeight: isAnnual ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
