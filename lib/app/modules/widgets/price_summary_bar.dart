import 'package:raspucat/app/utils/price_formatter.dart';
import 'package:raspucat/utils/constants/exports.dart';

class PriceSummaryBar extends StatelessWidget {
  const PriceSummaryBar({
    super.key,
    required this.plan,
    required this.setupPrice,
    required this.selectedAddonCount,
    required this.addonSavings,
    required this.selectedManagement,
    required this.isAnnual,
    this.promoDiscountCents = 0,
    this.appliedPromoCode = '',
    this.promoSubscriptionLabel,
    this.subDiscountPct,
    this.subDiscountFixed,
  });

  final PlanModel plan;
  final int setupPrice;
  final int selectedAddonCount;
  final int addonSavings;
  final ManagementOptionModel? selectedManagement;
  final bool isAnnual;
  final int promoDiscountCents;
  final String appliedPromoCode;
  final String? promoSubscriptionLabel;
  final int? subDiscountPct;
  final int? subDiscountFixed;

  String? get _savingsLabel {
    int baseSavings = 0;
    String? baseSuffix;
    if (!plan.isCustom) {
      baseSavings = plan.bundleSavingsCents ?? 0;
    } else if (addonSavings > 0) {
      baseSavings = addonSavings;
      final pct = selectedAddonCount >= 9
          ? 15
          : selectedAddonCount >= 6
          ? 10
          : 5;
      baseSuffix = '$pct% off';
    }
    final totalSavings = baseSavings + promoDiscountCents;
    if (totalSavings <= 0) return null;
    final dollars = PriceFormatter.dollars((totalSavings / 100).round());
    if (baseSuffix != null && promoDiscountCents <= 0) {
      return 'Saving \$$dollars ($baseSuffix)';
    }
    return 'Saving \$$dollars';
  }

  int get _effectiveSetup => setupPrice - promoDiscountCents;
  int get _depositCents => (_effectiveSetup / 2).floor();
  int get _balanceCents => _effectiveSetup - _depositCents;
  bool get _isHandover => selectedManagement != null && selectedManagement!.onetimePrice > 0;

  int _discountedMgmt(int fullCents) {
    if (subDiscountPct != null) {
      return (fullCents * (1 - subDiscountPct! / 100)).round();
    }
    if (subDiscountFixed != null) {
      return (fullCents - subDiscountFixed!).clamp(0, fullCents);
    }
    return fullCents;
  }

  int get _dueOnLaunchCents {
    int total = _balanceCents;
    if (selectedManagement == null) return total;
    if (_isHandover) {
      total += selectedManagement!.onetimePrice;
    } else {
      final full = isAnnual ? selectedManagement!.annualPrice : selectedManagement!.monthlyPrice;
      total += _discountedMgmt(full);
    }
    return total;
  }

  String _dueOnLaunchLabel(int balanceCents, int totalCents) {
    final total = PriceFormatter.dollars((totalCents / 100).round());
    if (selectedManagement == null) {
      return 'Due on launch: \$$total';
    }
    final balance = PriceFormatter.dollars((balanceCents / 100).round());
    if (_isHandover) {
      final fee = PriceFormatter.dollars((selectedManagement!.onetimePrice / 100).round());
      return 'Due on launch: \$$total (\$$balance + \$$fee handover)';
    }
    if (isAnnual) {
      final fee = PriceFormatter.dollars(
        (_discountedMgmt(selectedManagement!.annualPrice) / 100).round(),
      );
      return 'Due on launch: \$$total (\$$balance + \$$fee 1st year)';
    }
    final fee = PriceFormatter.dollars(
      (_discountedMgmt(selectedManagement!.monthlyPrice) / 100).round(),
    );
    return 'Due on launch: \$$total (\$$balance + \$$fee 1st month)';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFormatted = PriceFormatter.dollars((_effectiveSetup / 100).round());
    final setupFormatted = PriceFormatter.dollars((setupPrice / 100).round());
    final promoFormatted = PriceFormatter.dollars((promoDiscountCents / 100).round());
    final depositFormatted = PriceFormatter.dollars((_depositCents / 100).round());
    final balanceCents = _balanceCents;
    final dueOnLaunchCents = _dueOnLaunchCents;
    final savings = _savingsLabel;

    return Container(
      decoration: BoxDecoration(
        color: EColors.backgroundDark.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: EColors.primary.withValues(alpha: 0.2), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: ESizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Setup headline + Savings pill ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  promoDiscountCents > 0
                      ? 'Setup: \$$effectiveFormatted'
                      : 'Setup: \$$setupFormatted',
                  style: const TextStyle(
                    color: EColors.textWhite,
                    fontSize: ESizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (savings != null) _SavingsBadge(label: savings),
            ],
          ),
          const SizedBox(height: 6),
          // ── Row 2: Details left | Due amounts right ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left — promo & management breakdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (promoDiscountCents > 0)
                      Text(
                        '$appliedPromoCode: -\$$promoFormatted',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: ESizes.fontSizeLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (selectedManagement != null)
                      Text(
                        _isHandover
                            ? '+ ${selectedManagement!.name}: ${selectedManagement!.displayOnetime}'
                            : isAnnual
                            ? '+ ${selectedManagement!.name}: ${PriceFormatter.cents(_discountedMgmt(selectedManagement!.annualPrice))}/yr'
                            : '+ ${selectedManagement!.name}: ${PriceFormatter.cents(_discountedMgmt(selectedManagement!.monthlyPrice))}/mo',
                        style: TextStyle(
                          color: EColors.textSecondary,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                      ),
                    if (promoSubscriptionLabel != null)
                      Text(
                        '$appliedPromoCode: $promoSubscriptionLabel (subscription)',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: ESizes.fontSizeLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: ESizes.sm),
              // Right — payment schedule
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Due today: \$$depositFormatted (50%)',
                      style: TextStyle(
                        color: EColors.gold,
                        fontSize: ESizes.fontSizeLabel,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    if (dueOnLaunchCents > 0)
                      Text(
                        _dueOnLaunchLabel(balanceCents, dueOnLaunchCents),
                        style: TextStyle(
                          color: EColors.textSecondary,
                          fontSize: ESizes.fontSizeLabel,
                        ),
                        textAlign: TextAlign.end,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavingsBadge extends StatelessWidget {
  const _SavingsBadge({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 4),
      decoration: BoxDecoration(
        color: EColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusSM),
        border: Border.all(color: EColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        label!,
        style: const TextStyle(
          color: EColors.gold,
          fontSize: ESizes.fontSizeLabel,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
