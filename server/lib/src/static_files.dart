import 'dart:io';

import 'package:shelf/shelf.dart';

/// Serves locally bundled residence photos from `residences-images/` at
/// `/v1/static/residences/<filename>`. Used by seed data for projects like
/// Hills Blue where we have real marketing assets instead of Wikimedia
/// placeholders.
Handler residencesStaticHandler({String? imagesDir}) {
  final dir =
      imagesDir ??
      '${Directory.current.path}${Platform.pathSeparator}residences-images';

  String contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  return (Request request) async {
    final filename = request.url.pathSegments.last;
    if (filename.isEmpty || filename.contains('..') || filename.contains('/')) {
      return Response.forbidden('Invalid path');
    }

    final file = File('$dir${Platform.pathSeparator}$filename');
    if (!await file.exists()) {
      return Response.notFound('File not found: $filename');
    }

    final bytes = await file.readAsBytes();
    return Response.ok(
      bytes,
      headers: {
        'content-type': contentTypeFor(filename),
        'cache-control': 'public, max-age=86400',
      },
    );
  };
}
