class PortalMessage {
  final String id;
  final String quoteId;
  final String sender;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? clientReadAt;

  const PortalMessage({
    required this.id,
    required this.quoteId,
    required this.sender,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.clientReadAt,
  });

  factory PortalMessage.fromJson(Map<String, dynamic> json) => PortalMessage(
        id: json['id'] as String,
        quoteId: json['quote_id'] as String,
        sender: json['sender'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
        clientReadAt: json['client_read_at'] != null
            ? DateTime.parse(json['client_read_at'] as String)
            : null,
      );

  bool get isFromClient => sender == 'client';
  bool get isUnreadByClient => sender == 'admin' && clientReadAt == null;

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }
}
