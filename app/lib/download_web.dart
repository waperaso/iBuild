import 'package:web/web.dart';

void downloadRegistry({String? projectId, String? status}) {
  final params = <String>[
    if ((projectId ?? '').isNotEmpty) 'project=$projectId',
    if ((status ?? '').isNotEmpty) 'status=$status',
  ];
  final query = params.isEmpty ? '' : '?${params.join('&')}';
  window.open('/api/requests.csv$query', '_blank');
}

void openApplicationDocument(String applicationId, String documentId) {
  window.open('/api/admin/applications/$applicationId/documents/$documentId', '_blank');
}

void openBankFile(String path) {
  window.open(path, '_blank');
}
