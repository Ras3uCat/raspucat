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
      );

  String get stageLabel => switch (portalStage) {
        'compiling' => 'Compiling',
        'deployed' => 'Deployed',
        _ => 'Transmitting',
      };

  Color get stageColor => switch (portalStage) {
        'compiling' => const Color(0xFF00B4D8),
        'deployed' => const Color(0xFF06D6A0),
        _ => const Color(0xFFFFB703),
      };

  String get formattedSetupTotal =>
      '\$${(setupTotalCents / 100).toStringAsFixed(0)}';

  String get planLabel =>
      planId.isEmpty ? planId : '${planId[0].toUpperCase()}${planId.substring(1)}';
}
