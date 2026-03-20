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
  });

  final PlanModel plan;
  final int setupPrice;             // cents — already discounted
  final int selectedAddonCount;
  final int addonSavings;           // cents saved via volume discount
  final ManagementOptionModel? selectedManagement;
  final bool isAnnual;

  String? get _savingsLabel {
    if (!plan.isCustom) return plan.bundleSavings; // e.g. "Save ~$300"
    if (addonSavings <= 0) return null;
    final dollars = (addonSavings / 100).round();
    final pct = selectedAddonCount >= 9 ? 15
        : selectedAddonCount >= 6 ? 10
        : 5;
    return 'Saving \$${_formatDollars(dollars)} ($pct% off)';
  }

  // Deposit is always 50% of setup fee. Handover $400 is collected by admin at delivery.
  int get _depositCents => (setupPrice / 2).floor();
  int get _balanceCents => setupPrice - _depositCents;

  bool get _isHandover =>
      selectedManagement != null && selectedManagement!.onetimePrice > 0;

  // Due on launch = remaining setup balance + management fee (handover or first period)
  int get _dueOnLaunchCents {
    int total = _balanceCents;
    if (selectedManagement == null) return total;
    if (_isHandover) {
      total += selectedManagement!.onetimePrice;
    } else {
      total += isAnnual ? selectedManagement!.annualPrice : selectedManagement!.monthlyPrice;
    }
    return total;
  }

  String _dueOnLaunchLabel(int balanceCents, int totalCents) {
    final total = _formatDollars((totalCents / 100).round());
    if (selectedManagement == null) {
      return 'Due on launch: \$$total';
    }
    final balance = _formatDollars((balanceCents / 100).round());
    if (_isHandover) {
      final fee = _formatDollars((selectedManagement!.onetimePrice / 100).round());
      return 'Due on launch: \$$total (\$$balance + \$$fee handover)';
    }
    if (isAnnual) {
      final fee = _formatDollars((selectedManagement!.annualPrice / 100).round());
      return 'Due on launch: \$$total (\$$balance + \$$fee 1st year)';
    }
    final fee = _formatDollars((selectedManagement!.monthlyPrice / 100).round());
    return 'Due on launch: \$$total (\$$balance + \$$fee 1st month)';
  }

  @override
  Widget build(BuildContext context) {
    final setupFormatted = _formatDollars((setupPrice / 100).round());
    final depositFormatted = _formatDollars((_depositCents / 100).round());
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
                  'Setup: \$$setupFormatted',
                  style: TextStyle(
                    color: EColors.textWhite,
                    fontSize: ESizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (selectedManagement != null)
                  Text(
                    _isHandover
                        ? '+ ${selectedManagement!.name}: ${selectedManagement!.displayOnetime} (collected on delivery)'
                        : isAnnual
                            ? '+ ${selectedManagement!.name}: ${selectedManagement!.displayAnnual}/yr'
                            : '+ ${selectedManagement!.name}: ${selectedManagement!.displayMonthly}/mo',
                    style: TextStyle(
                      color: EColors.textSecondary,
                      fontSize: ESizes.fontSizeLabel,
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

  static String _formatDollars(int dollars) {
    final s = dollars.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
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
