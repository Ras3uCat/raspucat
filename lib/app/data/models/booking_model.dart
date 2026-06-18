class BookingModel {
  const BookingModel({
    required this.id,
    required this.sessionType,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.name,
    required this.email,
    required this.cancellationToken,
    this.message,
    this.meetUrl,
  });

  final String id;
  final String sessionType;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String name;
  final String email;
  final String? message;
  final String? meetUrl;
  final String cancellationToken;

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: json['id'] as String,
    sessionType: json['session_type'] as String,
    startAt: DateTime.parse(json['start_at'] as String),
    endAt: DateTime.parse(json['end_at'] as String),
    status: json['status'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    message: json['message'] as String?,
    meetUrl: json['meet_url'] as String?,
    cancellationToken: json['cancellation_token'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_type': sessionType,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt.toIso8601String(),
    'status': status,
    'name': name,
    'email': email,
    'message': message,
    'meet_url': meetUrl,
    'cancellation_token': cancellationToken,
  };
}

class AvailabilitySlot {
  const AvailabilitySlot({required this.startAt});

  final DateTime startAt;
  DateTime get endAt => startAt.add(const Duration(minutes: 30));
  bool get isPast => startAt.isBefore(DateTime.now());

  factory AvailabilitySlot.fromUtcIso(String iso) {
    final utc = DateTime.parse(iso);
    return AvailabilitySlot(startAt: utc.toLocal());
  }
}

class AvailabilityRule {
  const AvailabilityRule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.enabled,
  });

  // dayOfWeek: 0 = Sunday … 6 = Saturday
  final int dayOfWeek;
  final String startTime; // "HH:mm"
  final String endTime;
  final bool enabled;

  factory AvailabilityRule.fromJson(Map<String, dynamic> json) => AvailabilityRule(
    dayOfWeek: (json['day_of_week'] as num).toInt(),
    startTime: json['start_time'] as String,
    endTime: json['end_time'] as String,
    enabled: (json['is_active'] ?? json['enabled']) as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'enabled': enabled,
  };

  AvailabilityRule copyWith({int? dayOfWeek, String? startTime, String? endTime, bool? enabled}) =>
      AvailabilityRule(
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        enabled: enabled ?? this.enabled,
      );
}

class AvailabilityBlock {
  const AvailabilityBlock({required this.id, required this.from, required this.until, this.reason});

  final String id;
  final DateTime from;
  final DateTime until;
  final String? reason;

  factory AvailabilityBlock.fromJson(Map<String, dynamic> json) => AvailabilityBlock(
    id: json['id'] as String,
    from: DateTime.parse((json['blocked_from'] ?? json['from']) as String),
    until: DateTime.parse((json['blocked_until'] ?? json['until']) as String),
    reason: json['reason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from.toIso8601String(),
    'until': until.toIso8601String(),
    'reason': reason,
  };
}
