class DeliveryStepDef {
  const DeliveryStepDef({
    required this.key,
    required this.label,
    required this.phase,
    this.modules = const [],
    this.isAuto = false,
  });
  final String key;
  final String label;
  final String phase;
  final List<String> modules;
  final bool isAuto;
}
