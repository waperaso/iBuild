import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Root for everything operators upload. Public assets (unit media, photo
/// reports) sit directly inside it; KYC paperwork goes in [kPrivateSubdir].
const kUploadsRoot = 'uploads';

/// Sub-directory of [kUploadsRoot] holding identity documents. It is
/// deliberately *not* reachable through the public static route — those files
/// are passports and business licences, and a random UUID in a URL is not an
/// access control.
const kPrivateSubdir = 'private';

/// Largest accepted upload body. The multipart parser buffers the whole
/// request in memory, so without a cap a single request could exhaust the
/// server's heap.
const kMaxUploadBytes = 15 * 1024 * 1024;

/// Extensions we are willing to write to disk. The extension is attacker
/// controlled (it comes from the multipart filename), so anything unknown is
/// stored as `.bin` rather than trusted.
const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'pdf', 'heic'};

/// Derives a safe, lowercase extension from a client-supplied [filename].
/// Only the characters we expect are kept, which keeps path separators and
/// `..` out of the name we build the destination path from.
String safeExtension(String? filename) {
  if (filename == null || !filename.contains('.')) return 'bin';
  final raw = filename.split('.').last.toLowerCase();
  final cleaned = raw.replaceAll(RegExp('[^a-z0-9]'), '');
  if (cleaned.isEmpty || cleaned.length > 5) return 'bin';
  return _allowedExtensions.contains(cleaned) ? cleaned : 'bin';
}

/// Writes [data] under [kUploadsRoot] (optionally in [subdir]) with a random
/// name, returning the stored filename. Shared by every upload route so the
/// naming and sanitisation rules can only be defined once.
Future<String> saveUploadBytes(
  Uint8List data,
  String? originalFilename, {
  String? subdir,
}) async {
  final sep = Platform.pathSeparator;
  final dirPath = subdir == null
      ? kUploadsRoot
      : '$kUploadsRoot$sep$subdir';
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final fileName = '${_uuid.v4()}.${safeExtension(originalFilename)}';
  await File('$dirPath$sep$fileName').writeAsBytes(data);
  return fileName;
}

/// Image content types served from the two static roots. Anything else is
/// handed back as a generic binary download rather than being sniffed.
String contentTypeFor(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
}

/// Rejects anything that could escape [dir]: path separators (both flavours,
/// since the server also runs on Windows), parent-directory hops, absolute
/// paths, and NUL bytes.
bool isSafeUploadFilename(String filename) {
  if (filename.isEmpty) return false;
  if (filename.contains('..')) return false;
  if (filename.contains('/') || filename.contains(r'\')) return false;
  if (filename.contains('\u0000')) return false;
  return true;
}

/// Shared implementation for the two static roots: validate the filename,
/// stream the file if it exists, 404 otherwise.
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
        // Uploaded content is user-supplied: never let a browser re-interpret
        // it as HTML/JS on the API origin.
        'x-content-type-options': 'nosniff',
        'content-disposition': 'inline',
      },
    );
  };
}

/// Serves locally bundled residence photos from `residences-images/` at
/// `/v1/static/residences/<filename>`. Used by seed data for projects like
/// Hills Blue where we have real marketing assets instead of Wikimedia
/// placeholders.
Handler residencesStaticHandler({String? imagesDir}) {
  final dir =
      imagesDir ??
      '${Directory.current.path}${Platform.pathSeparator}residences-images';
  return _staticDirHandler(() => dir);
}

/// Serves *public* operator uploads (unit media, photo reports) from
/// `uploads/` at `/v1/static/uploads/<filename>`. KYC paperwork lives in
/// `uploads/private/` and is served by the authenticated document route
/// instead — this handler only reads the top-level directory, so a nested
/// private file cannot be reached through it.
Handler uploadsStaticHandler({String? uploadsDir}) =>
    _staticDirHandler(() => uploadsDir ?? kUploadsRoot);
