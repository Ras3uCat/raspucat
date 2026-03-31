import 'package:raspucat/app/utils/price_formatter.dart';

class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.label,
    required this.price,
    required this.idealFor,
    required this.features,
    required this.isFeatured,
    required this.isCustom,
    this.setupPrice = 0,
    this.basePrice = 0,
    this.monthlyPriceCents = 0,
    this.bundleSavingsCents,
    this.lockedModuleIds = const [],
  });

  final String id;
  final String name;
  final String label;
  final String price;
  final String idealFor;
  final List<String> features;
  final bool isFeatured;
  final bool isCustom;

  // Supabase-sourced fields
  final int setupPrice;         // cents
  final int basePrice;          // cents
  final int monthlyPriceCents;  // cents
  final int? bundleSavingsCents;
  final List<String> lockedModuleIds;

  String get monthlyPrice {
    if (monthlyPriceCents == 0) return '';
    final dollars = (monthlyPriceCents / 100).round();
    return '+ from \$$dollars/mo';
  }

  String? get bundleSavings {
    if (bundleSavingsCents == null || bundleSavingsCents == 0) return null;
    final dollars = (bundleSavingsCents! / 100).round();
    return 'Save ~\$$dollars';
  }

  PlanModel withFeatures(List<String> features) {
    return PlanModel(
      id: id,
      name: name,
      label: label,
      price: price,
      idealFor: idealFor,
      features: features,
      isFeatured: isFeatured,
      isCustom: isCustom,
      setupPrice: setupPrice,
      basePrice: basePrice,
      monthlyPriceCents: monthlyPriceCents,
      bundleSavingsCents: bundleSavingsCents,
      lockedModuleIds: lockedModuleIds,
    );
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final isCustom = json['is_custom'] as bool? ?? false;
    final setupPrice = json['setup_price'] as int? ?? 0;
    return PlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      label: json['label'] as String? ?? '',
      price: _buildPriceString(isCustom, setupPrice),
      idealFor: json['ideal_for'] as String? ?? '',
      features: const [],
      isFeatured: json['is_featured'] as bool? ?? false,
      isCustom: isCustom,
      setupPrice: setupPrice,
      basePrice: json['base_price'] as int? ?? 0,
      monthlyPriceCents: json['monthly_price'] as int? ?? 0,
      bundleSavingsCents: json['bundle_savings'] as int?,
      lockedModuleIds: (json['locked_module_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static String _buildPriceString(bool isCustom, int setupCents) {
    if (setupCents == 0) return 'Custom Quote';
    final formatted = PriceFormatter.dollars((setupCents / 100).round());
    return isCustom ? 'From \$$formatted' : '\$$formatted';
  }
}
