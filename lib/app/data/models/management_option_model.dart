import 'package:raspucat/app/utils/price_formatter.dart';

class ManagementOptionModel {
  const ManagementOptionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.annualSavings,
    required this.onetimePrice,
  });

  final String id;
  final String name;
  final String description;
  final int monthlyPrice;   // cents/month
  final int annualPrice;    // cents/year (billed annually)
  final int annualSavings;  // cents/year
  final int onetimePrice;   // cents one-time

  String get displayMonthly => PriceFormatter.cents(monthlyPrice);
  String get displayAnnual => PriceFormatter.cents(annualPrice);
  String get displayOnetime => PriceFormatter.cents(onetimePrice);
  String get displayAnnualSavings => PriceFormatter.cents(annualSavings);

  factory ManagementOptionModel.fromJson(Map<String, dynamic> json) {
    return ManagementOptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      monthlyPrice: json['monthly_price'] as int? ?? 0,
      annualPrice: json['annual_price'] as int? ?? 0,
      annualSavings: json['annual_savings'] as int? ?? 0,
      onetimePrice: json['onetime_price'] as int? ?? 0,
    );
  }
}
