import '../../../core/network/ws_client.dart';

/// Locally persisted notification built from a [WsEvent] ([WsEventType] reused).
///
/// [title]/[body] are English fallbacks for older persisted rows; new events
/// store [status] / [offerTitle] and the UI formats copy via l10n.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.projectId,
    this.status,
    this.offerTitle,
  });

  final String id;
  final WsEventType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? projectId;

  /// Wire status for [WsEventType.leadStatusChanged] (e.g. `contacted`).
  final String? status;

  /// Offer headline for [WsEventType.newOffer], when the server sent one.
  final String? offerTitle;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    projectId: projectId,
    status: status,
    offerTitle: offerTitle,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    'projectId': projectId,
    if (status != null) 'status': status,
    if (offerTitle != null) 'offerTitle': offerTitle,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: WsEventType.parse(json['type'] as String?),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
        projectId: json['projectId'] as String?,
        status: json['status'] as String?,
        offerTitle: json['offerTitle'] as String?,
      );
}
