import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Computes SHA-256 checksum (64-char lowercase hex) of raw file bytes.
String sha256Bytes(Uint8List bytes) => sha256.convert(bytes).toString();

/// Client-supplied capture and geolocation metadata sent alongside a photo upload.
class ClientPhotoMeta {
  const ClientPhotoMeta({
    this.captureSource = 'upload',
    this.capturedAt,
    this.gpsLat,
    this.gpsLon,
    this.gpsAccuracy,
    this.gpsHeading,
  });

  final String captureSource; // 'camera' | 'upload'
  final DateTime? capturedAt;
  final double? gpsLat;
  final double? gpsLon;
  final double? gpsAccuracy;
  final double? gpsHeading;

  factory ClientPhotoMeta.fromHeaders(Map<String, String> headers) {
    String? h(String key) => headers[key] ?? headers[key.toLowerCase()];
    final rawSource = (h('x-capture-source') ?? '').trim().toLowerCase();
    final source = rawSource == 'camera' ? 'camera' : 'upload';

    final lat = _parseDouble(h('x-geo-lat'), -90, 90);
    final lon = _parseDouble(h('x-geo-lon'), -180, 180);
    final hasPair = lat != null && lon != null;

    final accuracy = _parseDouble(h('x-geo-accuracy'), 0, 100000);
    final heading = _parseDouble(h('x-geo-heading'), 0, 360);

    DateTime? capturedAt;
    final rawAt = (h('x-captured-at') ?? '').trim();
    if (rawAt.isNotEmpty) {
      capturedAt = DateTime.tryParse(rawAt)?.toUtc();
    }

    return ClientPhotoMeta(
      captureSource: source,
      capturedAt: capturedAt,
      gpsLat: hasPair ? lat : null,
      gpsLon: hasPair ? lon : null,
      gpsAccuracy: hasPair ? accuracy : null,
      gpsHeading: heading,
    );
  }

  static double? _parseDouble(String? raw, double min, double max) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value.isNaN || value.isInfinite) return null;
    if (value < min || value > max) return null;
    return value;
  }
}

/// EXIF metadata extracted directly from JPEG (APP1) or WebP (EXIF chunk) bytes.
class ParsedExif {
  const ParsedExif({
    this.present = false,
    this.cameraMake = '',
    this.cameraModel = '',
    this.software = '',
    this.lensModel = '',
    this.orientation,
    this.takenAt,
    this.lat,
    this.lon,
    this.altitude,
    this.heading,
    this.pixelWidth,
    this.pixelHeight,
    this.raw = const {},
  });

  final bool present;
  final String cameraMake;
  final String cameraModel;
  final String software;
  final String lensModel;
  final int? orientation;
  final DateTime? takenAt;
  final double? lat;
  final double? lon;
  final double? altitude;
  final double? heading;
  final int? pixelWidth;
  final int? pixelHeight;
  final Map<String, Object?> raw;

  Map<String, Object?> toJson() => {
        if (cameraMake.isNotEmpty) 'make': cameraMake,
        if (cameraModel.isNotEmpty) 'model': cameraModel,
        if (software.isNotEmpty) 'software': software,
        if (lensModel.isNotEmpty) 'lensModel': lensModel,
        if (orientation != null) 'orientation': orientation,
        if (takenAt != null) 'takenAt': takenAt!.toIso8601String(),
        if (lat != null) 'lat': _round6(lat!),
        if (lon != null) 'lon': _round6(lon!),
        if (altitude != null) 'altitude': double.parse(altitude!.toStringAsFixed(1)),
        if (heading != null) 'heading': double.parse(heading!.toStringAsFixed(1)),
        if (pixelWidth != null) 'width': pixelWidth,
        if (pixelHeight != null) 'height': pixelHeight,
      };
}

/// Complete forensic analysis result stored alongside an uploaded photo.
class PhotoVerification {
  const PhotoVerification({
    required this.sha256,
    required this.captureSource,
    required this.capturedAt,
    required this.gpsLat,
    required this.gpsLon,
    required this.gpsAccuracy,
    required this.gpsHeading,
    required this.exifLat,
    required this.exifLon,
    required this.exifTakenAt,
    required this.exifHeading,
    required this.cameraMake,
    required this.cameraModel,
    required this.exifJson,
    required this.distanceM,
    required this.verifyStatus,
    required this.verifyFlags,
    required this.duplicateOfFileId,
  });

  final String sha256;
  final String captureSource;
  final DateTime? capturedAt;
  final double? gpsLat;
  final double? gpsLon;
  final double? gpsAccuracy;
  final double? gpsHeading;
  final double? exifLat;
  final double? exifLon;
  final DateTime? exifTakenAt;
  final double? exifHeading;
  final String cameraMake;
  final String cameraModel;
  final Map<String, Object?> exifJson;
  final int? distanceM;
  final String verifyStatus; // verified | warning | alert | unverified
  final List<String> verifyFlags;
  final String? duplicateOfFileId;
}

/// Maximum allowed distance (meters) from the project coordinates before flagging.
const photoMaxSiteDistanceM = 1500;

/// Maximum allowed discrepancy (meters) between EXIF GPS and browser/device GPS.
const photoMaxGeoMismatchM = 500;

/// Maximum photo age (days) before flagging as potentially stale/old.
const photoMaxAgeDays = 14;

/// Runs full forensic verification on an uploaded image file.
PhotoVerification verifyPhotoBytes({
  required Uint8List bytes,
  required bool isPhoto,
  required ClientPhotoMeta client,
  double? projectLat,
  double? projectLon,
  String? duplicateOfFileId,
  DateTime? now,
}) {
  final hash = sha256Bytes(bytes);
  if (!isPhoto) {
    return PhotoVerification(
      sha256: hash,
      captureSource: 'upload',
      capturedAt: client.capturedAt,
      gpsLat: null,
      gpsLon: null,
      gpsAccuracy: null,
      gpsHeading: null,
      exifLat: null,
      exifLon: null,
      exifTakenAt: null,
      exifHeading: null,
      cameraMake: '',
      cameraModel: '',
      exifJson: const {},
      distanceM: null,
      verifyStatus: 'unverified',
      verifyFlags: const [],
      duplicateOfFileId: duplicateOfFileId,
    );
  }

  final exif = parseExif(bytes);
  final flags = <String>[];
  final clock = (now ?? DateTime.now()).toUtc();

  if (duplicateOfFileId != null && duplicateOfFileId.isNotEmpty) {
    flags.add('duplicate_checksum');
  }

  if (!exif.present) {
    flags.add('no_exif');
  }

  final hasExifGeo = exif.lat != null && exif.lon != null;
  final hasDeviceGeo = client.gpsLat != null && client.gpsLon != null;
  final effectiveLat = hasExifGeo ? exif.lat : client.gpsLat;
  final effectiveLon = hasExifGeo ? exif.lon : client.gpsLon;

  if (effectiveLat == null || effectiveLon == null) {
    flags.add('no_geo');
  }

  if (hasExifGeo && hasDeviceGeo) {
    final diff = haversineMeters(exif.lat!, exif.lon!, client.gpsLat!, client.gpsLon!);
    if (diff > photoMaxGeoMismatchM) {
      flags.add('geo_mismatch');
    }
  }

  int? distanceM;
  if (effectiveLat != null &&
      effectiveLon != null &&
      projectLat != null &&
      projectLon != null) {
    distanceM = haversineMeters(effectiveLat, effectiveLon, projectLat, projectLon);
    if (distanceM > photoMaxSiteDistanceM) {
      flags.add('far_from_site');
    }
  }

  if (exif.takenAt != null) {
    final age = clock.difference(exif.takenAt!).inDays;
    if (age > photoMaxAgeDays) {
      flags.add('stale_photo');
    }
  }

  if (client.captureSource != 'camera') {
    flags.add('uploaded_from_gallery');
  }

  final hasAlert = flags.any(
    (f) => f == 'duplicate_checksum' || f == 'geo_mismatch' || f == 'far_from_site',
  );
  final hasWarning = flags.any(
    (f) => f == 'no_exif' || f == 'no_geo' || f == 'stale_photo',
  );
  final status = hasAlert
      ? 'alert'
      : hasWarning
          ? 'warning'
          : 'verified';

  return PhotoVerification(
    sha256: hash,
    captureSource: client.captureSource,
    capturedAt: client.capturedAt ?? exif.takenAt ?? clock,
    gpsLat: client.gpsLat == null ? null : _round6(client.gpsLat!),
    gpsLon: client.gpsLon == null ? null : _round6(client.gpsLon!),
    gpsAccuracy: client.gpsAccuracy == null
        ? null
        : double.parse(client.gpsAccuracy!.toStringAsFixed(2)),
    gpsHeading: client.gpsHeading == null
        ? null
        : double.parse(client.gpsHeading!.toStringAsFixed(2)),
    exifLat: exif.lat == null ? null : _round6(exif.lat!),
    exifLon: exif.lon == null ? null : _round6(exif.lon!),
    exifTakenAt: exif.takenAt,
    exifHeading: exif.heading == null
        ? null
        : double.parse(exif.heading!.toStringAsFixed(2)),
    cameraMake: exif.cameraMake,
    cameraModel: exif.cameraModel,
    exifJson: exif.toJson(),
    distanceM: distanceM,
    verifyStatus: status,
    verifyFlags: flags,
    duplicateOfFileId: duplicateOfFileId,
  );
}

double _round6(double value) => double.parse(value.toStringAsFixed(6));

/// Great-circle distance in meters between two WGS-84 coordinates.
int haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusM = 6371000.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return (earthRadiusM * c).round();
}

double _degToRad(double deg) => deg * math.pi / 180.0;

/// Extracts EXIF metadata from JPEG (APP1 Exif) or WebP (EXIF chunk) image bytes.
ParsedExif parseExif(Uint8List bytes) {
  try {
    final tiff = _findTiffPayload(bytes);
    if (tiff == null || tiff.length < 8) return const ParsedExif();
    return _parseTiff(tiff);
  } catch (_) {
    return const ParsedExif();
  }
}

Uint8List? _findTiffPayload(Uint8List bytes) {
  // JPEG: starts with SOI 0xFF 0xD8
  if (bytes.length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    var offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) break;
      while (offset < bytes.length && bytes[offset] == 0xFF) {
        offset++;
      }
      if (offset >= bytes.length) break;
      final marker = bytes[offset++];
      // SOS (0xDA) or EOI (0xD9) -> image data starts / ends.
      if (marker == 0xDA || marker == 0xD9) break;
      // Standalone markers without length
      if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
      if (offset + 2 > bytes.length) break;
      final segLen = (bytes[offset] << 8) | bytes[offset + 1];
      if (segLen < 2 || offset + segLen > bytes.length) break;
      if (marker == 0xE1 && segLen >= 8) {
        final dataStart = offset + 2;
        // "Exif\0\0"
        if (bytes[dataStart] == 0x45 &&
            bytes[dataStart + 1] == 0x78 &&
            bytes[dataStart + 2] == 0x69 &&
            bytes[dataStart + 3] == 0x66 &&
            bytes[dataStart + 4] == 0x00 &&
            bytes[dataStart + 5] == 0x00) {
          return Uint8List.sublistView(bytes, dataStart + 6, offset + segLen);
        }
      }
      offset += segLen;
    }
    return null;
  }

  // WebP: RIFF....WEBP with optional EXIF chunk
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    var offset = 12;
    final view = ByteData.sublistView(bytes);
    while (offset + 8 <= bytes.length) {
      final tag = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkLen = view.getUint32(offset + 4, Endian.little);
      final dataStart = offset + 8;
      if (dataStart + chunkLen > bytes.length) break;
      if (tag == 'EXIF' && chunkLen >= 8) {
        var tiffStart = dataStart;
        if (chunkLen >= 14 &&
            bytes[dataStart] == 0x45 &&
            bytes[dataStart + 1] == 0x78 &&
            bytes[dataStart + 2] == 0x69 &&
            bytes[dataStart + 3] == 0x66 &&
            bytes[dataStart + 4] == 0x00 &&
            bytes[dataStart + 5] == 0x00) {
          tiffStart = dataStart + 6;
        }
        return Uint8List.sublistView(bytes, tiffStart, dataStart + chunkLen);
      }
      offset = dataStart + chunkLen + (chunkLen.isOdd ? 1 : 0);
    }
  }
  return null;
}

ParsedExif _parseTiff(Uint8List tiff) {
  final endian = (tiff[0] == 0x49 && tiff[1] == 0x49)
      ? Endian.little
      : (tiff[0] == 0x4D && tiff[1] == 0x4D)
          ? Endian.big
          : null;
  if (endian == null) return const ParsedExif();
  final data = ByteData.sublistView(tiff);
  if (data.getUint16(2, endian) != 42) return const ParsedExif();
  final ifd0Offset = data.getUint32(4, endian);
  if (ifd0Offset >= tiff.length) return const ParsedExif();

  final ifd0 = _readIfd(tiff, data, ifd0Offset, endian);
  if (ifd0.isEmpty) return const ParsedExif();

  final make = _cleanAscii(ifd0[0x010F]);
  final model = _cleanAscii(ifd0[0x0110]);
  final software = _cleanAscii(ifd0[0x0131]);
  final orientation = _asInt(ifd0[0x0112]);
  final dateTime0 = _cleanAscii(ifd0[0x0132]);

  final exifOffset = _asInt(ifd0[0x8769]);
  final gpsOffset = _asInt(ifd0[0x8825]);

  final exifIfd = (exifOffset != null && exifOffset > 0 && exifOffset < tiff.length)
      ? _readIfd(tiff, data, exifOffset, endian)
      : const <int, Object?>{};
  final gpsIfd = (gpsOffset != null && gpsOffset > 0 && gpsOffset < tiff.length)
      ? _readIfd(tiff, data, gpsOffset, endian)
      : const <int, Object?>{};

  final dtOriginal = _cleanAscii(exifIfd[0x9003]);
  final dtDigitized = _cleanAscii(exifIfd[0x9004]);
  final offsetOriginal = _cleanAscii(exifIfd[0x9011]);
  final lensModel = _cleanAscii(exifIfd[0xA434]);
  final pixelW = _asInt(exifIfd[0xA002]);
  final pixelH = _asInt(exifIfd[0xA003]);

  final latRef = _cleanAscii(gpsIfd[0x0001]).toUpperCase();
  final latDms = _asDoubleList(gpsIfd[0x0002]);
  final lonRef = _cleanAscii(gpsIfd[0x0003]).toUpperCase();
  final lonDms = _asDoubleList(gpsIfd[0x0004]);
  final altRef = _asInt(gpsIfd[0x0005]) ?? 0;
  final altVal = _asDouble(gpsIfd[0x0006]);
  final dirVal = _asDouble(gpsIfd[0x0011]);
  final gpsDate = _cleanAscii(gpsIfd[0x001D]);
  final gpsTime = _asDoubleList(gpsIfd[0x0007]);

  double? lat;
  double? lon;
  if (latDms != null && latDms.length >= 3 && lonDms != null && lonDms.length >= 3) {
    final parsedLat = _dmsToDecimal(latDms, negative: latRef == 'S');
    final parsedLon = _dmsToDecimal(lonDms, negative: lonRef == 'W');
    if (parsedLat >= -90 && parsedLat <= 90 && parsedLon >= -180 && parsedLon <= 180) {
      lat = parsedLat;
      lon = parsedLon;
    }
  }

  final altitude = altVal == null ? null : (altRef == 1 ? -altVal : altVal);
  final heading = (dirVal != null && dirVal >= 0 && dirVal <= 360) ? dirVal : null;

  DateTime? takenAt = _parseExifDateTime(
    dtOriginal.isNotEmpty
        ? dtOriginal
        : (dtDigitized.isNotEmpty ? dtDigitized : dateTime0),
    offsetOriginal,
  );
  takenAt ??= _parseGpsDateTime(gpsDate, gpsTime);

  final hasMeaningful = make.isNotEmpty ||
      model.isNotEmpty ||
      takenAt != null ||
      (lat != null && lon != null) ||
      software.isNotEmpty ||
      orientation != null;

  return ParsedExif(
    present: hasMeaningful,
    cameraMake: make,
    cameraModel: model,
    software: software,
    lensModel: lensModel,
    orientation: orientation,
    takenAt: takenAt,
    lat: lat,
    lon: lon,
    altitude: altitude,
    heading: heading,
    pixelWidth: pixelW,
    pixelHeight: pixelH,
  );
}

Map<int, Object?> _readIfd(Uint8List tiff, ByteData data, int offset, Endian endian) {
  final result = <int, Object?>{};
  if (offset + 2 > tiff.length) return result;
  final count = data.getUint16(offset, endian);
  if (count > 256) return result;
  var pos = offset + 2;
  for (var i = 0; i < count; i++) {
    if (pos + 12 > tiff.length) break;
    final tag = data.getUint16(pos, endian);
    final type = data.getUint16(pos + 2, endian);
    final numValues = data.getUint32(pos + 4, endian);
    final valueOffsetField = pos + 8;
    pos += 12;

    final typeSize = _tiffTypeSize(type);
    if (typeSize == 0 || numValues == 0 || numValues > 4096) continue;
    final totalBytes = typeSize * numValues;
    final dataPos = totalBytes <= 4
        ? valueOffsetField
        : data.getUint32(valueOffsetField, endian);
    if (dataPos < 0 || dataPos + totalBytes > tiff.length) continue;

    result[tag] = _readTiffValue(tiff, data, type, numValues, dataPos, endian);
  }
  return result;
}

int _tiffTypeSize(int type) {
  switch (type) {
    case 1: // BYTE
    case 2: // ASCII
    case 6: // SBYTE
    case 7: // UNDEFINED
      return 1;
    case 3: // SHORT
    case 8: // SSHORT
      return 2;
    case 4: // LONG
    case 9: // SLONG
    case 11: // FLOAT
      return 4;
    case 5: // RATIONAL
    case 10: // SRATIONAL
    case 12: // DOUBLE
      return 8;
    default:
      return 0;
  }
}

Object? _readTiffValue(
  Uint8List tiff,
  ByteData data,
  int type,
  int count,
  int pos,
  Endian endian,
) {
  switch (type) {
    case 1: // BYTE
      if (count == 1) return tiff[pos];
      return [for (var i = 0; i < count; i++) tiff[pos + i]];
    case 2: // ASCII
      final slice = tiff.sublist(pos, pos + count);
      var end = slice.length;
      while (end > 0 && slice[end - 1] == 0) {
        end--;
      }
      return utf8.decode(slice.sublist(0, end), allowMalformed: true);
    case 3: // SHORT
      if (count == 1) return data.getUint16(pos, endian);
      return [for (var i = 0; i < count; i++) data.getUint16(pos + i * 2, endian)];
    case 4: // LONG
      if (count == 1) return data.getUint32(pos, endian);
      return [for (var i = 0; i < count; i++) data.getUint32(pos + i * 4, endian)];
    case 5: // RATIONAL
      double readRat(int at) {
        final num = data.getUint32(at, endian);
        final den = data.getUint32(at + 4, endian);
        return den == 0 ? 0.0 : num / den;
      }
      if (count == 1) return readRat(pos);
      return [for (var i = 0; i < count; i++) readRat(pos + i * 8)];
    case 9: // SLONG
      if (count == 1) return data.getInt32(pos, endian);
      return [for (var i = 0; i < count; i++) data.getInt32(pos + i * 4, endian)];
    case 10: // SRATIONAL
      double readSRat(int at) {
        final num = data.getInt32(at, endian);
        final den = data.getInt32(at + 4, endian);
        return den == 0 ? 0.0 : num / den;
      }
      if (count == 1) return readSRat(pos);
      return [for (var i = 0; i < count; i++) readSRat(pos + i * 8)];
    default:
      return null;
  }
}

String _cleanAscii(Object? value) {
  if (value is! String) return '';
  return value.replaceAll(RegExp(r'[\x00-\x1F]'), '').trim();
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) return value.isFinite ? value : null;
  if (value is int) return value.toDouble();
  return null;
}

List<double>? _asDoubleList(Object? value) {
  if (value is! List) return null;
  final out = <double>[];
  for (final item in value) {
    final d = _asDouble(item);
    if (d == null) return null;
    out.add(d);
  }
  return out;
}

double _dmsToDecimal(List<double> dms, {required bool negative}) {
  final value = dms[0] + dms[1] / 60.0 + dms[2] / 3600.0;
  return negative ? -value : value;
}

DateTime? _parseExifDateTime(String raw, String offset) {
  final match = RegExp(r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})$').firstMatch(raw);
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final mo = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  final h = int.parse(match.group(4)!);
  final mi = int.parse(match.group(5)!);
  final s = int.parse(match.group(6)!);
  if (y < 1990 || y > 2100 || mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final isoOffset = RegExp(r'^[+-]\d{2}:\d{2}$').hasMatch(offset)
      ? offset
      : (offset == 'Z' ? 'Z' : '+05:00');
  final iso = '${y.toString().padLeft(4, '0')}-'
      '${mo.toString().padLeft(2, '0')}-'
      '${d.toString().padLeft(2, '0')}T'
      '${h.toString().padLeft(2, '0')}:'
      '${mi.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}$isoOffset';
  return DateTime.tryParse(iso)?.toUtc();
}

DateTime? _parseGpsDateTime(String date, List<double>? time) {
  final match = RegExp(r'^(\d{4}):(\d{2}):(\d{2})$').firstMatch(date);
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final mo = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  final h = (time != null && time.isNotEmpty) ? time[0].floor().clamp(0, 23) : 0;
  final mi = (time != null && time.length > 1) ? time[1].floor().clamp(0, 59) : 0;
  final s = (time != null && time.length > 2) ? time[2].floor().clamp(0, 59) : 0;
  return DateTime.utc(y, mo, d, h, mi, s);
}
