class PendingModuleModel {
  const PendingModuleModel({
    required this.pendingId,
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.priceNote,
    this.acknowledgedAt,
  });

  final String pendingId;
  final String id;
  final String name;
  final String description;
  final int price;
  final String? priceNote;
  final DateTime? acknowledgedAt;

  bool get isAcknowledged => acknowledgedAt != null;

  factory PendingModuleModel.fromJson(Map<String, dynamic> json) {
    final m = json['modules'] as Map<String, dynamic>;
    return PendingModuleModel(
      pendingId: json['id'] as String,
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String? ?? '',
      price: m['price'] as int? ?? 0,
      priceNote: m['price_note'] as String?,
      acknowledgedAt: json['acknowledged_at'] == null
          ? null
          : DateTime.parse(json['acknowledged_at'] as String),
    );
  }
}
