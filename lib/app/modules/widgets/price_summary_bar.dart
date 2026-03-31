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
  final int setupPrice;             // cents — volume-discounted but pre-promo
  final int selectedAddonCount;
  final int addonSavings;           // cents saved via volume discount
  final ManagementOptionModel? selectedManagement;
  final bool isAnnual;
  final int promoDiscountCents;     // cents saved via promo code
  final String appliedPromoCode;
  final String? promoSubscriptionLabel;
  final int? subDiscountPct;        // e.g. 99 → 99% off subscription
  final int? subDiscountFixed;      // cents off per period

  String? get _savingsLabel {
    // Base savings: bundle discount (Pro/Premium) or addon volume discount (Custom)
    int baseSavings = 0;
    String? baseSuffix;
    if (!plan.isCustom) {
      baseSavings = plan.bundleSavingsCents ?? 0;
    } else if (addonSavings > 0) {
      baseSavings = addonSavings;
      final pct = selectedAddonCount >= 9 ? 15
          : selectedAddonCount >= 6 ? 10
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
  // Deposit is always 50% of effective (post-promo) setup fee.
  int get _depositCents => (_effectiveSetup / 2).floor();
  int get _balanceCents => _effectiveSetup - _depositCents;

  bool get _isHandover =>
      selectedManagement != null && selectedManagement!.onetimePrice > 0;

  /// Applies the subscription promo discount to a management price in cents.
  int _discountedMgmt(int fullCents) {
    if (subDiscountPct != null) {
      return (fullCents * (1 - subDiscountPct! / 100)).round();
    }
    if (subDiscountFixed != null) {
      return (fullCents - subDiscountFixed!).clamp(0, fullCents);
    }
    return fullCents;
  }

  // Due on launch = remaining setup balance + management fee (handover or first period)
  int get _dueOnLaunchCents {
    int total = _balanceCents;
    if (selectedManagement == null) return total;
    if (_isHandover) {
      total += selectedManagement!.onetimePrice; // handover is one-time, not a subscription
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
      final fee = PriceFormatter.dollars((_discountedMgmt(selectedManagement!.annualPrice) / 100).round());
      return 'Due on launch: \$$total (\$$balance + \$$fee 1st year)';
    }
    final fee = PriceFormatter.dollars((_discountedMgmt(selectedManagement!.monthlyPrice) / 100).round());
    return 'Due on launch: \$$total (\$$balance + \$$fee 1st month)';
  }

  @override
  Widget build(BuildContext context) {
    final setupFormatted = PriceFormatter.dollars((setupPrice / 100).round());
    final effectiveFormatted = PriceFormatter.dollars((_effectiveSetup / 100).round());
    final promoFormatted = PriceFormatter.dollars((promoDiscountCents / 100).round());
    final depositFormatted = PriceFormatter.dollars((_depositCents / 100).round());
    final balanceCents = _balanceCents;
    final dueOnLaunchCents = _dueOnLaunchCents;

    return Container(
      decoration: BoxDecoration(
        color: EColors.backgroundDark.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: EColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ESizes.lg,
        vertical: ESizes.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  promoDiscountCents > 0
                      ? 'Setup: \$$effectiveFormatted'
                      : 'Setup: \$$setupFormatted',
                  style: TextStyle(
                    color: EColors.textWhite,
                    fontSize: ESizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
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
                        ? '+ ${selectedManagement!.name}: ${selectedManagement!.displayOnetime} (collected on delivery)'
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
                const SizedBox(height: 4),
                Text(
                  'Due today: \$$depositFormatted (50% deposit)',
                  style: TextStyle(
                    color: EColors.gold,
                    fontSize: ESizes.fontSizeLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dueOnLaunchCents > 0)
                  Text(
                    _dueOnLaunchLabel(balanceCents, dueOnLaunchCents),
                    style: TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeLabel,
                    ),
                  ),
              ],
            ),
          ),
          _SavingsBadge(label: _savingsLabel),
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
        style: TextStyle(
          color: EColors.gold,
          fontSize: ESizes.fontSizeLabel,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
