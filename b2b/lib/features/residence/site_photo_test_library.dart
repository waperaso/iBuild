import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/env.dart';
import '../../l10n/gen/app_localizations.dart';

const _prefsKey = 'site_photo_test_library_v1';
const _maxLocalItems = 12;
const _maxBytes = 1500000;

/// Built-in construction-check still served from `/v1/static/residences/`.
const kSitePhotoBuiltinA = 'first-check-photo.jpg';
const kSitePhotoBuiltinB = 'second-check-photo.jpg';
const kSitePhotoBuiltinBefore = 'before-site-photo.jpg';
const kSitePhotoBuiltinAfter = 'after-site-photo.jpg';

final sitePhotoTestLibraryProvider = Provider<SitePhotoTestLibrary>((ref) {
  return SitePhotoTestLibrary(ref.watch(apiClientProvider));
});

enum SitePhotoLibraryKind { builtin, local }

class SitePhotoLibraryEntry {
  const SitePhotoLibraryEntry({
    required this.id,
    required this.kind,
    required this.label,
    this.builtinFilename,
    this.previewUrl,
  });

  final String id;
  final SitePhotoLibraryKind kind;
  final String label;
  final String? builtinFilename;
  final String? previewUrl;

  factory SitePhotoLibraryEntry.builtin({
    required String id,
    required String label,
    required String filename,
  }) {
    return SitePhotoLibraryEntry(
      id: id,
      kind: SitePhotoLibraryKind.builtin,
      label: label,
      builtinFilename: filename,
      previewUrl: Env.resolveUrl('/v1/static/residences/$filename'),
    );
  }

  factory SitePhotoLibraryEntry.local({
    required String id,
    required String label,
    required String previewDataUrl,
  }) {
    return SitePhotoLibraryEntry(
      id: id,
      kind: SitePhotoLibraryKind.local,
      label: label,
      previewUrl: previewDataUrl,
    );
  }
}

/// Resolved pick ready for upload or demo JSON attach.
class SitePhotoLibraryPick {
  const SitePhotoLibraryPick({
    required this.entry,
    this.bytes,
    this.filename,
    this.demoSampleFile,
  });

  final SitePhotoLibraryEntry entry;
  final Uint8List? bytes;
  final String? filename;

  /// When set, demo mode can attach the bundled still without re-uploading.
  final String? demoSampleFile;
}

class SitePhotoLibraryTooLargeException implements Exception {}

class SitePhotoTestLibrary {
  SitePhotoTestLibrary(this._dio);

  final Dio _dio;

  List<SitePhotoLibraryEntry> builtins(AppLocalizations l10n) => [
    SitePhotoLibraryEntry.builtin(
      id: 'builtin-a',
      label: l10n.siteCycleLibrarySampleA,
      filename: kSitePhotoBuiltinA,
    ),
    SitePhotoLibraryEntry.builtin(
      id: 'builtin-b',
      label: l10n.siteCycleLibrarySampleB,
      filename: kSitePhotoBuiltinB,
    ),
    SitePhotoLibraryEntry.builtin(
      id: 'builtin-before',
      label: l10n.siteCycleLibrarySampleBefore,
      filename: kSitePhotoBuiltinBefore,
    ),
    SitePhotoLibraryEntry.builtin(
      id: 'builtin-after',
      label: l10n.siteCycleLibrarySampleAfter,
      filename: kSitePhotoBuiltinAfter,
    ),
  ];

  Future<List<SitePhotoLibraryEntry>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    return raw.map((line) {
      final map = jsonDecode(line) as Map<String, dynamic>;
      return SitePhotoLibraryEntry.local(
        id: map['id'] as String,
        label: map['label'] as String? ?? map['filename'] as String? ?? 'Photo',
        previewDataUrl: map['preview'] as String,
      );
    }).toList();
  }

  Future<SitePhotoLibraryPick> resolvePick(SitePhotoLibraryEntry entry) async {
    if (entry.kind == SitePhotoLibraryKind.builtin &&
        entry.builtinFilename != null) {
      return SitePhotoLibraryPick(
        entry: entry,
        demoSampleFile: entry.builtinFilename,
        bytes: await _loadBuiltinBytes(entry.builtinFilename!),
        filename: entry.builtinFilename,
      );
    }
    final local = await _readLocalBytes(entry.id);
    if (local == null) {
      throw StateError('Local library item missing');
    }
    return SitePhotoLibraryPick(
      entry: entry,
      bytes: local.$1,
      filename: local.$2,
    );
  }

  Future<void> addFromDevice() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return;
    if (bytes.length > _maxBytes) {
      throw SitePhotoLibraryTooLargeException();
    }
    final id = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final label = file.name.trim().isEmpty ? 'Photo' : file.name.trim();
    final preview = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_prefsKey) ?? <String>[];
    items.insert(
      0,
      jsonEncode({
        'id': id,
        'label': label,
        'filename': file.name,
        'preview': preview,
        'bytes': base64Encode(bytes),
      }),
    );
    while (items.length > _maxLocalItems) {
      items.removeLast();
    }
    await prefs.setStringList(_prefsKey, items);
  }

  Future<void> removeLocal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_prefsKey) ?? <String>[];
    items.removeWhere((line) {
      final map = jsonDecode(line) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList(_prefsKey, items);
  }

  Future<Uint8List> _loadBuiltinBytes(String filename) async {
    final url = Env.resolveUrl('/v1/static/residences/$filename');
    if (url == null) throw StateError('Invalid static URL');
    final res = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = res.data;
    if (data == null || data.isEmpty) throw StateError('Empty image');
    return Uint8List.fromList(data);
  }

  Future<(Uint8List, String)?> _readLocalBytes(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_prefsKey) ?? const [];
    for (final line in items) {
      final map = jsonDecode(line) as Map<String, dynamic>;
      if (map['id'] != id) continue;
      final encoded = map['bytes'] as String?;
      if (encoded == null) return null;
      final filename = map['filename'] as String? ?? 'photo.jpg';
      return (base64Decode(encoded), filename);
    }
    return null;
  }
}
