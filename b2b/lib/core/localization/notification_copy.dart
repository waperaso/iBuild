import '../../l10n/gen/app_localizations.dart';
import 'status_labels.dart';

/// Localized title/body for an admin inbox notification.
({String title, String? body}) notificationCopy(
  AppLocalizations l10n,
  Map<String, dynamic> notification,
) {
  final type = notification['type']?.toString();
  final payload = _payloadOf(notification);

  switch (type) {
    case 'developer_submitted':
      final name = _str(payload, 'developerName') ??
          _afterColon(notification['title']) ??
          '';
      return (
        title: l10n.notifDeveloperSubmittedTitle(name),
        body: l10n.notifDeveloperSubmittedBody(name),
      );
    case 'document_uploaded':
      final rawType = _str(payload, 'documentType') ??
          _afterColon(notification['title']) ??
          '';
      final docLabel = documentTypeLabel(l10n, rawType);
      final name = _str(payload, 'developerName') ?? '';
      return (
        title: l10n.notifDocumentUploadedTitle(docLabel),
        body: name.isEmpty
            ? null
            : l10n.notifDocumentUploadedBody(name, docLabel),
      );
    case 'project_created':
      final name = _str(payload, 'projectName') ??
          _afterColon(notification['title']) ??
          '';
      final developer = _str(payload, 'developerName');
      return (
        title: l10n.notifProjectCreatedTitle(name),
        body: developer == null || developer.isEmpty
            ? l10n.notifProjectCreatedBodyAnonymous
            : l10n.notifProjectCreatedBody(developer),
      );
    case 'project_submitted':
      final name = _str(payload, 'projectName') ??
          _afterColon(notification['title']) ??
          '';
      final developer = _str(payload, 'developerName');
      return (
        title: l10n.notifProjectSubmittedTitle(name),
        body: developer == null || developer.isEmpty
            ? l10n.notifProjectSubmittedBodyAnonymous
            : l10n.notifProjectSubmittedBody(developer),
      );
    case 'project_updated':
      final name = _str(payload, 'projectName') ??
          _afterColon(notification['title']) ??
          '';
      final fields = payload['changedFields'];
      final fieldsLabel = fields is List
          ? fields.map((e) => e.toString()).join(', ')
          : (notification['body']?.toString() ?? '');
      return (
        title: l10n.notifProjectUpdatedTitle(name),
        body: fieldsLabel.isEmpty
            ? null
            : l10n.notifProjectUpdatedBody(fieldsLabel),
      );
    case 'progress_deviation':
      final name = _str(payload, 'projectName') ??
          _afterColon(notification['title']) ??
          '';
      final actual = _int(payload, 'actual') ?? 0;
      final planned = _int(payload, 'planned') ?? 0;
      final gap = _int(payload, 'gap') ?? (planned - actual);
      return (
        title: l10n.notifProgressDeviationTitle(name),
        body: l10n.notifProgressDeviationBody(actual, planned, gap),
      );
    default:
      return (
        title: notification['title']?.toString() ?? '',
        body: notification['body']?.toString(),
      );
  }
}

Map<String, dynamic> _payloadOf(Map<String, dynamic> n) {
  final raw = n['payload'];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const {};
}

String? _str(Map<String, dynamic> map, String key) {
  final v = map[key]?.toString().trim();
  if (v == null || v.isEmpty) return null;
  return v;
}

int? _int(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v?.toString() ?? '');
}

/// Legacy English titles used `"Label: value"` — recover the value for old rows.
String? _afterColon(Object? title) {
  final s = title?.toString();
  if (s == null) return null;
  final i = s.indexOf(': ');
  if (i < 0 || i + 2 >= s.length) return null;
  return s.substring(i + 2).trim();
}
