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
  });

  final String slug;
  final String name;
  final List<String> painPoints;
  final List<String> bookingCtaKeywords;
  final DateTime researchedAt;
  final IndustryBenchmark? benchmark;

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
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'painPoints': painPoints,
    'bookingCtaKeywords': bookingCtaKeywords,
    'researchedAt': researchedAt.toIso8601String(),
  };
}
