import '../../../core/network/ws_client.dart';

/// A locally-persisted notification synthesized from a pushed [WsEvent]
/// (see `notifications_providers.dart`), reusing [WsEventType] rather than
/// duplicating a parallel enum.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.projectId,
  });

  final String id;
  final WsEventType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? projectId;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    projectId: projectId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    'projectId': projectId,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: WsEventType.parse(json['type'] as String?),
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
        projectId: json['projectId'] as String?,
      );
}
