class AppProject {
  final String id;
  final String name;
  final String? description;
  final String status;
  final List<String> techStack;
  final String? slug;
  final String? aliasEmail;
  final String? supabaseUrl;
  final String? repoUrl;
  final String? webUrl;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final String? stripeDashboardUrl;
  final String? crashReportUrl;
  final String? cloudflareRoutingRuleId;
  final DateTime? emailProvisionedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppProject({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.techStack = const [],
    this.slug,
    this.aliasEmail,
    this.supabaseUrl,
    this.repoUrl,
    this.webUrl,
    this.appStoreUrl,
    this.playStoreUrl,
    this.stripeDashboardUrl,
    this.crashReportUrl,
    this.cloudflareRoutingRuleId,
    this.emailProvisionedAt,
  });

  factory AppProject.fromJson(Map<String, dynamic> json) => AppProject(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    status: json['status'] as String? ?? 'development',
    techStack: List<String>.from(json['tech_stack'] as List? ?? []),
    slug: json['slug'] as String?,
    aliasEmail: json['alias_email'] as String?,
    supabaseUrl: json['supabase_url'] as String?,
    repoUrl: json['repo_url'] as String?,
    webUrl: json['web_url'] as String?,
    appStoreUrl: json['app_store_url'] as String?,
    playStoreUrl: json['play_store_url'] as String?,
    stripeDashboardUrl: json['stripe_dashboard_url'] as String?,
    crashReportUrl: json['crash_report_url'] as String?,
    cloudflareRoutingRuleId: json['cloudflare_routing_rule_id'] as String?,
    emailProvisionedAt: json['email_provisioned_at'] != null
        ? DateTime.parse(json['email_provisioned_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'status': status,
    'tech_stack': techStack,
    'alias_email': aliasEmail,
    'supabase_url': supabaseUrl,
    'repo_url': repoUrl,
    'web_url': webUrl,
    'app_store_url': appStoreUrl,
    'play_store_url': playStoreUrl,
    'stripe_dashboard_url': stripeDashboardUrl,
    'crash_report_url': crashReportUrl,
  };

  AppProject copyWith({
    String? name,
    String? description,
    String? status,
    List<String>? techStack,
    String? aliasEmail,
    String? supabaseUrl,
    String? repoUrl,
    String? webUrl,
    String? appStoreUrl,
    String? playStoreUrl,
    String? stripeDashboardUrl,
    String? crashReportUrl,
  }) => AppProject(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    status: status ?? this.status,
    techStack: techStack ?? this.techStack,
    aliasEmail: aliasEmail ?? this.aliasEmail,
    supabaseUrl: supabaseUrl ?? this.supabaseUrl,
    repoUrl: repoUrl ?? this.repoUrl,
    webUrl: webUrl ?? this.webUrl,
    appStoreUrl: appStoreUrl ?? this.appStoreUrl,
    playStoreUrl: playStoreUrl ?? this.playStoreUrl,
    stripeDashboardUrl: stripeDashboardUrl ?? this.stripeDashboardUrl,
    crashReportUrl: crashReportUrl ?? this.crashReportUrl,
    cloudflareRoutingRuleId: cloudflareRoutingRuleId,
    emailProvisionedAt: emailProvisionedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  bool get emailProvisioned => aliasEmail != null && cloudflareRoutingRuleId != null;

  String get statusLabel => switch (status) {
    'planning' => 'Planning',
    'development' => 'Development',
    'beta' => 'Beta',
    'live' => 'Live',
    'paused' => 'Paused',
    _ => status,
  };
}
