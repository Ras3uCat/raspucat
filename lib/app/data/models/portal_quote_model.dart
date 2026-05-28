import 'package:flutter/material.dart';

class PortalQuote {
  final String id;
  final String planId;
  final List<String> moduleIds;
  final String clientName;
  final String clientEmail;
  final String businessName;
  final int setupTotalCents;
  final int depositCents;
  final String status;
  final String portalStage;
  final String? stripeCustomerId;
  final String? stripePaymentMethodId;
  final DateTime createdAt;
  final DateTime? subscriptionStartedAt;
  final DateTime? subscriptionCancelAt;
  final DateTime? cancelledAt;
  final Map<String, dynamic> discoveryData;
  final Map<String, dynamic> discoveryPrefill;
  final DateTime? discoverySubmittedAt;
  final bool isComped;
  final String? stripeCheckoutUrl;

  const PortalQuote({
    required this.id,
    required this.planId,
    required this.moduleIds,
    required this.clientName,
    required this.clientEmail,
    required this.businessName,
    required this.setupTotalCents,
    required this.depositCents,
    required this.status,
    required this.portalStage,
    required this.createdAt,
    this.stripeCustomerId,
    this.stripePaymentMethodId,
    this.subscriptionStartedAt,
    this.subscriptionCancelAt,
    this.cancelledAt,
    this.discoveryData = const {},
    this.discoveryPrefill = const {},
    this.discoverySubmittedAt,
    this.isComped = false,
    this.stripeCheckoutUrl,
  });

  factory PortalQuote.fromJson(Map<String, dynamic> json) => PortalQuote(
    id: json['id'] as String,
    planId: json['plan_id'] as String,
    moduleIds: List<String>.from(json['module_ids'] as List? ?? []),
    clientName: json['client_name'] as String,
    clientEmail: json['client_email'] as String,
    businessName: json['business_name'] as String,
    setupTotalCents: json['setup_total_cents'] as int,
    depositCents: json['deposit_cents'] as int,
    status: json['status'] as String,
    portalStage: json['portal_stage'] as String? ?? 'transmitting',
    stripeCustomerId: json['stripe_customer_id'] as String?,
    stripePaymentMethodId: json['stripe_payment_method_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    subscriptionStartedAt: json['subscription_started_at'] != null
        ? DateTime.parse(json['subscription_started_at'] as String)
        : null,
    subscriptionCancelAt: json['subscription_cancel_at'] != null
        ? DateTime.parse(json['subscription_cancel_at'] as String)
        : null,
    cancelledAt: json['cancelled_at'] != null
        ? DateTime.parse(json['cancelled_at'] as String)
        : null,
    discoveryData: (json['discovery_data'] as Map<String, dynamic>?) ?? {},
    discoveryPrefill: (json['discovery_prefill'] as Map<String, dynamic>?) ?? {},
    discoverySubmittedAt: json['discovery_submitted_at'] != null
        ? DateTime.parse(json['discovery_submitted_at'] as String)
        : null,
    isComped: json['is_comped'] as bool? ?? false,
    stripeCheckoutUrl: json['stripe_checkout_url'] as String?,
  );

  bool get discoverySubmitted => discoverySubmittedAt != null;

  String get stageLabel => switch (portalStage) {
    'awaiting_deposit' => 'Awaiting Deposit',
    'awaiting_discovery' => 'Discovery',
    'compiling' => 'Compiling',
    'deployed' => 'Deployed',
    _ => 'Transmitting',
  };

  Color get stageColor => switch (portalStage) {
    'awaiting_deposit' => const Color(0xFFFBBF24),
    'awaiting_discovery' => const Color(0xFFFFB938),
    'compiling' => const Color(0xFF00B4D8),
    'deployed' => const Color(0xFF06D6A0),
    _ => const Color(0xFFFFB703),
  };

  String get formattedSetupTotal => '\$${(setupTotalCents / 100).toStringAsFixed(0)}';

  String get planLabel =>
      planId.isEmpty ? planId : '${planId[0].toUpperCase()}${planId.substring(1)}';
}
