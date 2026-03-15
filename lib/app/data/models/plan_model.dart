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
  });

  final String id;
  final String name;
  final String label;
  final String price;
  final String idealFor;
  final List<String> features;
  final bool isFeatured;
  final bool isCustom;
}
