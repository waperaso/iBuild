import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

const sessionCookieName = 'ibuild_session';
const csrfCookieName = 'ibuild_csrf';

Response jsonResponse(
  int status,
  Map<String, Object?> body, {
  String? setCookie,
}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
      if (setCookie != null) 'set-cookie': setCookie,
    },
  );
}

Response jsonError(int status, String error, String message, {String? setCookie}) {
  return jsonResponse(status, {
    'error': error,
    'message': message,
  }, setCookie: setCookie);
}

String sessionCookie(String token, {required bool secure, required Duration maxAge}) {
  return _cookie(
    sessionCookieName,
    token,
    secure: secure,
    httpOnly: true,
    maxAge: maxAge,
  );
}

String clearSessionCookie({required bool secure}) {
  return _cookie(
    sessionCookieName,
    '',
    secure: secure,
    httpOnly: true,
    maxAge: Duration.zero,
  );
}

String csrfCookie(String token, {required bool secure}) {
  return _cookie(
    csrfCookieName,
    token,
    secure: secure,
    httpOnly: false,
    maxAge: const Duration(hours: 12),
  );
}

String _cookie(
  String name,
  String value, {
  required bool secure,
  required bool httpOnly,
  required Duration maxAge,
}) {
  final parts = <String>[
    '$name=$value',
    'Path=/',
    'SameSite=Lax',
    'Max-Age=${maxAge.inSeconds}',
  ];
  if (httpOnly) parts.add('HttpOnly');
  if (secure) parts.add('Secure');
  return parts.join('; ');
}

Map<String, String> readCookies(Request request) {
  final raw = request.headers['cookie'];
  if (raw == null || raw.isEmpty) return const {};
  final cookies = <String, String>{};
  for (final part in raw.split(';')) {
    final separator = part.indexOf('=');
    if (separator <= 0) continue;
    cookies[part.substring(0, separator).trim()] = part.substring(separator + 1).trim();
  }
  return cookies;
}

/// A body that stopped at [max] bytes. On overflow, [bytes] keeps only the
/// start, enough to recognise a file, and the rest of the stream is not read.
class BoundedBytes {
  BoundedBytes(this.bytes, {required this.overflow});

  final Uint8List bytes;
  final bool overflow;
}

/// Reads [source] until [max] bytes. A longer stream is cancelled instead of
/// being buffered, so a chunked request without Content-Length cannot fill memory.
Future<BoundedBytes> readAtMost(Stream<List<int>> source, int max) async {
  final builder = BytesBuilder(copy: false);
  var length = 0;
  Uint8List? head;
  await for (final chunk in source) {
    final piece = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    head ??= Uint8List.fromList(piece.length > 16 ? piece.sublist(0, 16) : piece);
    length += piece.length;
    if (length > max) return BoundedBytes(head, overflow: true);
    builder.add(piece);
  }
  return BoundedBytes(builder.takeBytes(), overflow: false);
}

/// Thrown when a request body passes the configured ceiling.
class BodyTooLarge implements Exception {
  const BodyTooLarge();
}

/// Refuses a declared or actual body above [maxBytes]. GET and HEAD pass through.
Handler applyBodyLimit(int maxBytes, Handler inner) {
  return (Request request) async {
    final declared = int.tryParse(request.headers['content-length'] ?? '');
    if (declared != null && declared > maxBytes) {
      return jsonError(413, 'too_large', 'Файл слишком большой.');
    }
    if (request.method == 'GET' || request.method == 'HEAD' || request.method == 'OPTIONS') {
      return inner(request);
    }
    try {
      return await inner(request.change(body: _cap(request.read(), maxBytes)));
    } on BodyTooLarge {
      return jsonError(413, 'too_large', 'Файл слишком большой.');
    }
  };
}

Stream<List<int>> _cap(Stream<List<int>> source, int max) async* {
  var seen = 0;
  await for (final chunk in source) {
    seen += chunk.length;
    if (seen > max) throw const BodyTooLarge();
    yield chunk;
  }
}

/// Address used for a public rate limit.
///
/// Behind the production proxy, Caddy replaces X-Forwarded-For with the TCP
/// client, and only then is the header trusted. The last hop is the one the
/// proxy added. A client-supplied list is ignored when the proxy is not trusted,
/// so rotating the header does not open a new bucket.
String clientAddress(Request request, {required bool trustProxy}) {
  if (trustProxy) {
    final hops = (request.headers['x-forwarded-for'] ?? '')
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (hops.isNotEmpty) return hops.last;
  }
  final info = request.context['shelf.io.connection_info'];
  if (info is HttpConnectionInfo) return info.remoteAddress.address;
  return 'local';
}

/// One secret from the environment or from a file. Both at once is refused.
/// A file may end with a newline; that newline is not part of the secret.
({String value, List<String> problems}) readSecret(Map<String, String> source, String name) {
  final direct = source[name] ?? '';
  final path = (source['${name}_FILE'] ?? '').trim();
  if (direct.isNotEmpty && path.isNotEmpty) {
    return (value: '', problems: ['$name и ${name}_FILE заданы вместе']);
  }
  if (path.isEmpty) return (value: direct, problems: const []);
  final file = File(path);
    if (!file.existsSync()) return (value: '', problems: ['${name}_FILE не найден']);
  try {
    final text = file.readAsStringSync().replaceAll(RegExp(r'[\r\n]+$'), '');
    return (value: text, problems: const []);
  } catch (_) {
      return (value: '', problems: ['${name}_FILE не читается']);
  }
}

Future<Object> readJsonObject(Request request) async {
  final limited = await readAtMost(request.read(), 20000);
  if (limited.overflow) return 'too_large';
  final raw = utf8.decode(limited.bytes);
  if (raw.length > 20000) return 'too_large';
  if (raw.trim().isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {
    return 'invalid';
  }
  return 'invalid';
}
