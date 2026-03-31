import 'package:raspucat/app/utils/price_formatter.dart';

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

  String get displayPrice => PriceFormatter.cents(price);

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
