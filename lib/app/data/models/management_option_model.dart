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

  String get displayMonthly => _formatCents(monthlyPrice);
  String get displayAnnual => _formatCents(annualPrice);
  String get displayOnetime => _formatCents(onetimePrice);
  String get displayAnnualSavings => _formatCents(annualSavings);

  static String _formatCents(int cents) {
    final dollars = (cents / 100).round();
    return '\$${_formatDollars(dollars)}';
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
