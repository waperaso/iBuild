import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Upload root. Public media lives here; KYC docs go under [kPrivateSubdir].
const kUploadsRoot = 'uploads';

/// KYC docs under [kUploadsRoot]. Not served by the public static route
/// (UUID-in-URL is not access control).
const kPrivateSubdir = 'private';

/// Max upload size. Multipart is buffered in memory; uncapped uploads can OOM.
const kMaxUploadBytes = 15 * 1024 * 1024;

/// Allowed on-disk extensions. Unknown client extensions become `.bin`.
const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'pdf', 'heic'};

/// Safe lowercase extension from a client [filename] (strips separators / `..`).
String safeExtension(String? filename) {
  if (filename == null || !filename.contains('.')) return 'bin';
  final raw = filename.split('.').last.toLowerCase();
  final cleaned = raw.replaceAll(RegExp('[^a-z0-9]'), '');
  if (cleaned.isEmpty || cleaned.length > 5) return 'bin';
  return _allowedExtensions.contains(cleaned) ? cleaned : 'bin';
}

/// Writes [data] under [kUploadsRoot] (optional [subdir]) with a random name.
Future<String> saveUploadBytes(
  Uint8List data,
  String? originalFilename, {
  String? subdir,
}) async {
  final sep = Platform.pathSeparator;
  final dirPath = subdir == null ? kUploadsRoot : '$kUploadsRoot$sep$subdir';
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final fileName = '${_uuid.v4()}.${safeExtension(originalFilename)}';
  await File('$dirPath$sep$fileName').writeAsBytes(data);
  return fileName;
}

/// Content-Type by extension; unknown → `application/octet-stream` (no sniffing).
String contentTypeFor(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
}

/// Rejects path traversal: separators, `..`, absolute paths, NUL.
bool isSafeUploadFilename(String filename) {
  if (filename.isEmpty) return false;
  if (filename.contains('..')) return false;
  if (filename.contains('/') || filename.contains(r'\')) return false;
  if (filename.contains('\u0000')) return false;
  return true;
}

/// Serve a file from [resolveDir] after filename checks; 404 if missing.
Handler _staticDirHandler(String Function() resolveDir) {
  return (Request request) async {
    final filename = request.url.pathSegments.isEmpty
        ? ''
        : request.url.pathSegments.last;
    if (!isSafeUploadFilename(filename)) {
      return Response.forbidden('Invalid path');
    }
    final file = File('${resolveDir()}${Platform.pathSeparator}$filename');
    if (!await file.exists()) {
      return Response.notFound('File not found');
    }
    return Response.ok(
      await file.readAsBytes(),
      headers: {
        'content-type': contentTypeFor(filename),
        'cache-control': 'public, max-age=86400',
        // User-supplied bytes: block MIME sniffing on the API origin.
        'x-content-type-options': 'nosniff',
        'content-disposition': 'inline',
      },
    );
  };
}

/// Bundled residence photos from `residences-images/` at `/v1/static/residences/<filename>`.
Handler residencesStaticHandler({String? imagesDir}) {
  final dir =
      imagesDir ??
      '${Directory.current.path}${Platform.pathSeparator}residences-images';
  return _staticDirHandler(() => dir);
}

/// Public uploads at `/v1/static/uploads/<filename>` (top-level only; not `private/`).
Handler uploadsStaticHandler({String? uploadsDir}) =>
    _staticDirHandler(() => uploadsDir ?? kUploadsRoot);
