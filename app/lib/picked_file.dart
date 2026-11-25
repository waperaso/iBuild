import 'dart:typed_data';

class PhotoCaptureMeta {
  const PhotoCaptureMeta({
    this.captureSource = 'upload',
    this.capturedAt,
    this.gpsLat,
    this.gpsLon,
    this.gpsAccuracy,
    this.gpsHeading,
    this.geoStatus = 'unavailable',
  });

  /// 'camera' when captured live on site, 'upload' when chosen from files/gallery.
  final String captureSource;
  final DateTime? capturedAt;
  final double? gpsLat;
  final double? gpsLon;
  final double? gpsAccuracy;
  final double? gpsHeading;

  /// 'ok', 'denied', or 'unavailable'.
  final String geoStatus;

  bool get hasGeo => gpsLat != null && gpsLon != null;

  Map<String, String> toHeaders() => {
    'x-capture-source': captureSource,
    if (capturedAt != null) 'x-captured-at': capturedAt!.toUtc().toIso8601String(),
    if (gpsLat != null) 'x-geo-lat': gpsLat!.toStringAsFixed(6),
    if (gpsLon != null) 'x-geo-lon': gpsLon!.toStringAsFixed(6),
    if (gpsAccuracy != null) 'x-geo-accuracy': gpsAccuracy!.toStringAsFixed(2),
    if (gpsHeading != null) 'x-geo-heading': gpsHeading!.toStringAsFixed(2),
  };
}

class PickedFile {
  const PickedFile({required this.name, required this.bytes, this.meta});

  final String name;
  final Uint8List bytes;
  final PhotoCaptureMeta? meta;
}
