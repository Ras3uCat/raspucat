class IndustryBenchmark {
  const IndustryBenchmark({
    required this.sampleSize,
    required this.avgPagespeed,
    required this.pctWithBookingCta,
    required this.pctDiyPlatform,
    required this.pctHttps,
    required this.pctMobileViewport,
    required this.sampledAt,
  });

  final int sampleSize;
  final int? avgPagespeed;
  final double pctWithBookingCta;
  final double pctDiyPlatform;
  final double pctHttps;
  final double pctMobileViewport;
  final String sampledAt;

  factory IndustryBenchmark.fromJson(Map<String, dynamic> json) => IndustryBenchmark(
    sampleSize: (json['sample_size'] as num).toInt(),
    avgPagespeed: json['avg_pagespeed'] != null ? (json['avg_pagespeed'] as num).toInt() : null,
    pctWithBookingCta: (json['pct_with_booking_cta'] as num).toDouble(),
    pctDiyPlatform: (json['pct_diy_platform'] as num).toDouble(),
    pctHttps: (json['pct_https'] as num).toDouble(),
    pctMobileViewport: (json['pct_mobile_viewport'] as num).toDouble(),
    sampledAt: json['sampled_at'] as String,
  );
}

class IndustryProfileModel {
  const IndustryProfileModel({
    required this.slug,
    required this.name,
    required this.painPoints,
    required this.bookingCtaKeywords,
    required this.researchedAt,
    this.benchmark,
    this.rideAlongMd,
    this.moneyMapMd,
    this.clientLocatorMd,
    this.overviewMd,
    this.emailSubjectTemplate,
    this.emailBodyTemplate,
  });

  final String slug;
  final String name;
  final List<String> painPoints;
  final List<String> bookingCtaKeywords;
  final DateTime researchedAt;
  final IndustryBenchmark? benchmark;
  final String? rideAlongMd;
  final String? moneyMapMd;
  final String? clientLocatorMd;
  final String? overviewMd;
  final String? emailSubjectTemplate;
  final String? emailBodyTemplate;

  factory IndustryProfileModel.fromJson(Map<String, dynamic> json) {
    final signals = json['audit_signals'] as Map<String, dynamic>?;
    final bJson = signals?['benchmark'] as Map<String, dynamic>?;
    return IndustryProfileModel(
      slug: json['slug'] as String,
      name: json['name'] as String,
      painPoints: (json['pain_points'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      bookingCtaKeywords: (json['booking_cta_keywords'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      researchedAt: DateTime.parse(json['researched_at'] as String),
      benchmark: bJson != null ? IndustryBenchmark.fromJson(bJson) : null,
      rideAlongMd: json['ride_along_md'] as String?,
      moneyMapMd: json['money_map_md'] as String?,
      clientLocatorMd: json['client_locator_md'] as String?,
      overviewMd: json['overview_md'] as String?,
      emailSubjectTemplate: json['email_subject_template'] as String?,
      emailBodyTemplate: json['email_body_template'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'painPoints': painPoints,
    'bookingCtaKeywords': bookingCtaKeywords,
    'researchedAt': researchedAt.toIso8601String(),
    if (rideAlongMd != null) 'rideAlongMd': rideAlongMd,
    if (moneyMapMd != null) 'moneyMapMd': moneyMapMd,
    if (clientLocatorMd != null) 'clientLocatorMd': clientLocatorMd,
    if (overviewMd != null) 'overviewMd': overviewMd,
    if (emailSubjectTemplate != null) 'emailSubjectTemplate': emailSubjectTemplate,
    if (emailBodyTemplate != null) 'emailBodyTemplate': emailBodyTemplate,
  };

  IndustryProfileModel copyWith({
    String? slug,
    String? name,
    List<String>? painPoints,
    List<String>? bookingCtaKeywords,
    DateTime? researchedAt,
    IndustryBenchmark? benchmark,
    String? rideAlongMd,
    String? moneyMapMd,
    String? clientLocatorMd,
    String? overviewMd,
    String? emailSubjectTemplate,
    String? emailBodyTemplate,
  }) => IndustryProfileModel(
    slug: slug ?? this.slug,
    name: name ?? this.name,
    painPoints: painPoints ?? this.painPoints,
    bookingCtaKeywords: bookingCtaKeywords ?? this.bookingCtaKeywords,
    researchedAt: researchedAt ?? this.researchedAt,
    benchmark: benchmark ?? this.benchmark,
    rideAlongMd: rideAlongMd ?? this.rideAlongMd,
    moneyMapMd: moneyMapMd ?? this.moneyMapMd,
    clientLocatorMd: clientLocatorMd ?? this.clientLocatorMd,
    overviewMd: overviewMd ?? this.overviewMd,
    emailSubjectTemplate: emailSubjectTemplate ?? this.emailSubjectTemplate,
    emailBodyTemplate: emailBodyTemplate ?? this.emailBodyTemplate,
  );
}
