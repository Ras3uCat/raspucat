class LeadModel {
  const LeadModel({
    required this.id,
    required this.companyName,
    required this.industry,
    required this.score,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.sources,
    this.website,
    this.city,
    this.state,
    this.phone,
    this.email,
    this.emailSource,
    this.notes,
    this.lastContactedAt,
    this.nextFollowupAt,
    this.lastBounceAt,
    this.decisionMakerName,
    this.decisionMakerTitle,
    this.rating,
    this.reviewCount,
    this.websiteAudit,
    this.blueprintMd,
    this.brandBriefHtml,
    this.competitorHtml,
    this.brandAlignmentHtml,
    this.customPlanDraftMd,
    this.customPlanMd,
    this.proposalHtml,
  });

  final String id;
  final String companyName;
  final String industry;
  final int score;
  final String status;
  final String source;
  final DateTime createdAt;
  final List<String> sources;
  final String? website;
  final String? city;
  final String? state;
  final String? phone;
  final String? email;
  final String? emailSource;
  final String? notes;
  final DateTime? lastContactedAt;
  final DateTime? nextFollowupAt;
  final DateTime? lastBounceAt;
  final String? decisionMakerName;
  final String? decisionMakerTitle;
  final double? rating;
  final int? reviewCount;
  // Keys: platform, hasHttps, hasViewport, hasBookingCta, pagespeedScore,
  //       painPointMatches (List<String>), lastAuditedAt
  final Map<String, dynamic>? websiteAudit;
  final String? blueprintMd;
  final String? brandBriefHtml;
  final String? competitorHtml;
  final String? brandAlignmentHtml;
  final String? customPlanDraftMd;
  final String? customPlanMd;
  final String? proposalHtml;

  bool get hasReports =>
      blueprintMd != null ||
      brandBriefHtml != null ||
      competitorHtml != null ||
      brandAlignmentHtml != null ||
      customPlanDraftMd != null ||
      customPlanMd != null ||
      proposalHtml != null;

  factory LeadModel.fromJson(Map<String, dynamic> json) => LeadModel(
    id: json['id'] as String,
    companyName: json['company_name'] as String,
    industry: json['industry'] as String,
    score: (json['score'] as num?)?.toInt() ?? 0,
    status: json['status'] as String,
    source: json['source'] as String? ?? 'manual',
    createdAt: DateTime.parse(json['created_at'] as String),
    sources: (json['sources'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    website: json['website'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    emailSource: json['email_source'] as String?,
    notes: json['notes'] as String?,
    lastContactedAt: json['last_contacted_at'] != null
        ? DateTime.parse(json['last_contacted_at'] as String)
        : null,
    nextFollowupAt: json['next_followup_at'] != null
        ? DateTime.parse(json['next_followup_at'] as String)
        : null,
    lastBounceAt: json['last_bounce_at'] != null
        ? DateTime.parse(json['last_bounce_at'] as String)
        : null,
    decisionMakerName: json['decision_maker_name'] as String?,
    decisionMakerTitle: json['decision_maker_title'] as String?,
    rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    reviewCount: json['review_count'] != null ? (json['review_count'] as num).toInt() : null,
    websiteAudit: json['website_audit'] as Map<String, dynamic>?,
    blueprintMd: json['blueprint_md'] as String?,
    brandBriefHtml: json['brand_brief_html'] as String?,
    competitorHtml: json['competitor_html'] as String?,
    brandAlignmentHtml: json['brand_alignment_html'] as String?,
    customPlanDraftMd: json['custom_plan_draft_md'] as String?,
    customPlanMd: json['custom_plan_md'] as String?,
    proposalHtml: json['proposal_html'] as String?,
  );

  LeadModel copyWith({
    String? companyName,
    String? industry,
    int? score,
    String? status,
    String? website,
    String? city,
    String? state,
    String? phone,
    String? email,
    String? notes,
    DateTime? lastContactedAt,
    DateTime? nextFollowupAt,
    List<String>? sources,
    String? decisionMakerName,
    String? decisionMakerTitle,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? websiteAudit,
  }) => LeadModel(
    id: id,
    companyName: companyName ?? this.companyName,
    industry: industry ?? this.industry,
    score: score ?? this.score,
    status: status ?? this.status,
    source: source,
    createdAt: createdAt,
    sources: sources ?? this.sources,
    website: website ?? this.website,
    city: city ?? this.city,
    state: state ?? this.state,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    emailSource: emailSource,
    notes: notes ?? this.notes,
    lastContactedAt: lastContactedAt ?? this.lastContactedAt,
    nextFollowupAt: nextFollowupAt ?? this.nextFollowupAt,
    decisionMakerName: decisionMakerName ?? this.decisionMakerName,
    decisionMakerTitle: decisionMakerTitle ?? this.decisionMakerTitle,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    websiteAudit: websiteAudit ?? this.websiteAudit,
    blueprintMd: blueprintMd,
    brandBriefHtml: brandBriefHtml,
    competitorHtml: competitorHtml,
    brandAlignmentHtml: brandAlignmentHtml,
    customPlanDraftMd: customPlanDraftMd,
    customPlanMd: customPlanMd,
    proposalHtml: proposalHtml,
  );

  String get locationDisplay {
    if (city != null && state != null) return '$city, $state';
    if (city != null) return city!;
    return '';
  }

  bool get isOverdue => nextFollowupAt != null && nextFollowupAt!.isBefore(DateTime.now());
  bool get isClosed => status == 'closed_won' || status == 'closed_lost';

  List<String> get painPointMatches {
    final matches = websiteAudit?['painPointMatches'];
    if (matches == null) return [];
    return (matches as List<dynamic>).map((e) => e as String).toList();
  }
}

class OutreachEmailModel {
  const OutreachEmailModel({
    required this.id,
    required this.leadId,
    required this.subject,
    required this.bodyHtml,
    required this.sequenceStep,
    required this.createdAt,
    this.notes,
    this.resendId,
    this.sentAt,
    this.openedAt,
    this.clickedAt,
    this.repliedAt,
  });

  final String id;
  final String leadId;
  final String subject;
  final String bodyHtml;
  final int sequenceStep;
  final DateTime createdAt;
  final String? notes;
  final String? resendId;
  final DateTime? sentAt;
  final DateTime? openedAt;
  final DateTime? clickedAt;
  final DateTime? repliedAt;

  bool get isSent => sentAt != null;
  bool get isDraft => sentAt == null;

  factory OutreachEmailModel.fromJson(Map<String, dynamic> json) => OutreachEmailModel(
    id: json['id'] as String,
    leadId: json['lead_id'] as String,
    subject: json['subject'] as String,
    bodyHtml: json['body_html'] as String,
    sequenceStep: (json['sequence_step'] as num).toInt(),
    createdAt: DateTime.parse(json['created_at'] as String),
    notes: json['notes'] as String?,
    resendId: json['resend_id'] as String?,
    sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
    openedAt: json['opened_at'] != null ? DateTime.parse(json['opened_at'] as String) : null,
    clickedAt: json['clicked_at'] != null ? DateTime.parse(json['clicked_at'] as String) : null,
    repliedAt: json['replied_at'] != null ? DateTime.parse(json['replied_at'] as String) : null,
  );
}

class OutreachSettings {
  const OutreachSettings({
    required this.id,
    required this.emailsPerRun,
    required this.runsPerWeek,
    required this.followUpDays,
    required this.maxFollowUps,
    required this.targetIndustries,
    required this.targetCities,
    required this.discoveryRunsPerWeek,
    required this.lastDiscoveryCount,
    this.nextDiscoveryRunAt,
    this.lastDiscoveryAt,
  });

  final String id;
  final int emailsPerRun;
  final int runsPerWeek;
  final int followUpDays;
  final int maxFollowUps;
  final List<String> targetIndustries;
  final List<String> targetCities;
  final int discoveryRunsPerWeek;
  final int lastDiscoveryCount;
  final DateTime? nextDiscoveryRunAt;
  final DateTime? lastDiscoveryAt;

  factory OutreachSettings.fromJson(Map<String, dynamic> json) => OutreachSettings(
    id: json['id'] as String,
    emailsPerRun: (json['emails_per_run'] as num).toInt(),
    runsPerWeek: (json['runs_per_week'] as num).toInt(),
    followUpDays: (json['follow_up_days'] as num).toInt(),
    maxFollowUps: (json['max_follow_ups'] as num).toInt(),
    targetIndustries: (json['target_industries'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    targetCities: (json['target_cities'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    discoveryRunsPerWeek: (json['discovery_runs_per_week'] as num?)?.toInt() ?? 2,
    lastDiscoveryCount: (json['last_discovery_count'] as num?)?.toInt() ?? 0,
    nextDiscoveryRunAt: json['next_discovery_run_at'] != null
        ? DateTime.parse(json['next_discovery_run_at'] as String)
        : null,
    lastDiscoveryAt: json['last_discovery_at'] != null
        ? DateTime.parse(json['last_discovery_at'] as String)
        : null,
  );

  static const defaults = OutreachSettings(
    id: '',
    emailsPerRun: 3,
    runsPerWeek: 2,
    followUpDays: 3,
    maxFollowUps: 2,
    targetIndustries: [],
    targetCities: [],
    discoveryRunsPerWeek: 2,
    lastDiscoveryCount: 0,
  );

  Map<String, dynamic> toJson() => {
    'emailsPerRun': emailsPerRun,
    'runsPerWeek': runsPerWeek,
    'followUpDays': followUpDays,
    'maxFollowUps': maxFollowUps,
    'targetIndustries': targetIndustries,
    'targetCities': targetCities,
    'discoveryRunsPerWeek': discoveryRunsPerWeek,
  };
}
