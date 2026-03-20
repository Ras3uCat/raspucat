class ModuleModel {
  const ModuleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.priceNote,
    this.upgradeOf,
  });

  final String id;
  final String name;
  final String description;
  final int price; // cents
  final String? priceNote;
  final String? upgradeOf;

  String get displayPrice {
    final dollars = (price / 100).round();
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

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      priceNote: json['price_note'] as String?,
      upgradeOf: json['upgrade_of'] as String?,
    );
  }
}
