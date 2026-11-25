import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'picked_file.dart';

/// Reads the device's current geolocation (lat, lon, accuracy, heading) with a short timeout.
Future<PhotoCaptureMeta> _captureGeo(String source) {
  final now = DateTime.now().toUtc();
  final completer = Completer<PhotoCaptureMeta>();
  try {
    final geo = window.navigator.geolocation;
    geo.getCurrentPosition(
      ((GeolocationPosition pos) {
        if (completer.isCompleted) return;
        final c = pos.coords;
        final heading = c.heading;
        completer.complete(
          PhotoCaptureMeta(
            captureSource: source,
            capturedAt: now,
            gpsLat: c.latitude,
            gpsLon: c.longitude,
            gpsAccuracy: c.accuracy,
            gpsHeading: (heading != null && heading.isFinite && heading >= 0 && heading <= 360)
                ? heading
                : null,
            geoStatus: 'ok',
          ),
        );
      }).toJS,
      ((GeolocationPositionError err) {
        if (completer.isCompleted) return;
        completer.complete(
          PhotoCaptureMeta(
            captureSource: source,
            capturedAt: now,
            geoStatus: err.code == 1 ? 'denied' : 'unavailable',
          ),
        );
      }).toJS,
      PositionOptions(enableHighAccuracy: true, timeout: 5500, maximumAge: 10000),
    );
    // Safety net in case the browser ignores timeout on an unresponded prompt.
    Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) {
        completer.complete(PhotoCaptureMeta(captureSource: source, capturedAt: now));
      }
    });
  } catch (_) {
    if (!completer.isCompleted) {
      completer.complete(PhotoCaptureMeta(captureSource: source, capturedAt: now));
    }
  }
  return completer.future;
}

/// Picks any tranche file (photo or PDF) via file input, capturing device geolocation too.
Future<PickedFile?> pickRequestFile() async {
  return _pickFromInput(
    accept: 'image/jpeg,image/png,image/webp,application/pdf',
    captureCamera: false,
  );
}

/// Captures a site photo either live from the device camera or by uploading an image file,
/// always collecting browser geolocation, accuracy, heading and timestamp alongside the photo.
Future<PickedFile?> pickTranchePhoto({required bool camera}) async {
  if (!camera) {
    return _pickFromInput(
      accept: 'image/jpeg,image/png,image/webp',
      captureCamera: false,
    );
  }
  // On mobile/touch devices, native <input capture="environment"> opens the hardware camera
  // and preserves full hardware EXIF (Make, Model, DateTimeOriginal, GPS tags).
  final isTouchDevice = window.matchMedia('(pointer: coarse)').matches;
  if (!isTouchDevice) {
    final live = await _captureFromLiveWebcam();
    if (live != null) return live;
  }
  return _pickFromInput(
    accept: 'image/jpeg,image/png,image/webp',
    captureCamera: true,
  );
}

Future<PickedFile?> _pickFromInput({
  required String accept,
  required bool captureCamera,
}) async {
  final source = captureCamera ? 'camera' : 'upload';
  // A plain file upload must not wait on a location prompt. GPS is requested
  // only when the photo is taken with the camera.
  final geoFuture = captureCamera
      ? _captureGeo(source)
      : Future<PhotoCaptureMeta>.value(
          PhotoCaptureMeta(captureSource: source, capturedAt: DateTime.now().toUtc()),
        );

  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  if (captureCamera) {
    input.setAttribute('capture', 'environment');
  }

  final result = Completer<PickedFile?>();
  var settled = false;
  void done(PickedFile? value) {
    if (settled) return;
    settled = true;
    input.remove();
    if (!result.isCompleted) result.complete(value);
  }

  input.onchange = ((Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      done(null);
      return;
    }
    file.arrayBuffer().toDart.then((buffer) async {
      final meta = await geoFuture;
      done(
        PickedFile(
          name: file.name,
          bytes: Uint8List.view(buffer.toDart),
          meta: meta,
        ),
      );
    }, onError: (_) {
      done(null);
    });
  }).toJS;

  input.addEventListener(
    'cancel',
    ((Event _) => done(null)).toJS,
  );

  document.body?.append(input);
  input.click();
  return result.future;
}

/// Opens a live camera overlay on desktop browsers via MediaDevices.getUserMedia.
/// Returns null if camera is unavailable, denied, or user cancels (caller may fall back).
Future<PickedFile?> _captureFromLiveWebcam() async {
  MediaStream? stream;
  try {
    final mediaDevices = window.navigator.mediaDevices;
    final constraints = MediaStreamConstraints(
      audio: false.toJS,
      video: {
        'facingMode': {'ideal': 'environment'},
        'width': {'ideal': 1920},
        'height': {'ideal': 1080},
      }.jsify()!,
    );
    stream = await mediaDevices.getUserMedia(constraints).toDart;
  } catch (_) {
    return null;
  }

  final geoFuture = _captureGeo('camera');
  final completer = Completer<PickedFile?>();

  final overlay = HTMLDivElement()
    ..style.position = 'fixed'
    ..style.inset = '0'
    ..style.zIndex = '999999'
    ..style.backgroundColor = 'rgba(10, 14, 22, 0.86)'
    ..style.display = 'flex'
    ..style.flexDirection = 'column'
    ..style.alignItems = 'center'
    ..style.justifyContent = 'center'
    ..style.padding = '20px'
    ..style.gap = '14px';

  final card = HTMLDivElement()
    ..style.width = 'min(720px, 100%)'
    ..style.backgroundColor = '#111827'
    ..style.borderRadius = '14px'
    ..style.padding = '16px'
    ..style.display = 'flex'
    ..style.flexDirection = 'column'
    ..style.gap = '12px'
    ..style.color = '#F8FAFC'
    ..style.fontFamily = 'system-ui, -apple-system, sans-serif';

  final header = HTMLDivElement()
    ..style.display = 'flex'
    ..style.justifyContent = 'space-between'
    ..style.alignItems = 'center'
    ..style.fontSize = '15px'
    ..style.fontWeight = '600'
    ..textContent = 'Фотофиксация на месте';

  final geoLabel = HTMLDivElement()
    ..style.fontSize = '12px'
    ..style.color = '#94A3B8'
    ..textContent = 'Определяем геолокацию…';

  final video = HTMLVideoElement()
    ..autoplay = true
    ..playsInline = true
    ..muted = true
    ..style.width = '100%'
    ..style.maxHeight = '62vh'
    ..style.borderRadius = '10px'
    ..style.backgroundColor = '#000'
    ..style.objectFit = 'cover'
    ..srcObject = stream;

  final actions = HTMLDivElement()
    ..style.display = 'flex'
    ..style.justifyContent = 'flex-end'
    ..style.gap = '10px';

  final cancelBtn = HTMLButtonElement()
    ..type = 'button'
    ..textContent = 'Отмена'
    ..style.padding = '10px 16px'
    ..style.borderRadius = '8px'
    ..style.border = '1px solid #334155'
    ..style.backgroundColor = 'transparent'
    ..style.color = '#E2E8F0'
    ..style.cursor = 'pointer'
    ..style.fontSize = '14px';

  final shootBtn = HTMLButtonElement()
    ..type = 'button'
    ..textContent = 'Сделать снимок'
    ..style.padding = '10px 18px'
    ..style.borderRadius = '8px'
    ..style.border = 'none'
    ..style.backgroundColor = '#2563EB'
    ..style.color = '#FFFFFF'
    ..style.fontWeight = '600'
    ..style.cursor = 'pointer'
    ..style.fontSize = '14px';

  void closeStream() {
    try {
      final tracks = stream!.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
    } catch (_) {}
    overlay.remove();
  }

  geoFuture.then((meta) {
    if (meta.hasGeo) {
      final acc = meta.gpsAccuracy != null ? ' (±${meta.gpsAccuracy!.round()} м)' : '';
      geoLabel.textContent =
          'GPS: ${meta.gpsLat!.toStringAsFixed(6)}, ${meta.gpsLon!.toStringAsFixed(6)}$acc';
      geoLabel.style.color = '#4ADE80';
    } else if (meta.geoStatus == 'denied') {
      geoLabel.textContent = 'Доступ к геолокации запрещён в браузере';
      geoLabel.style.color = '#FBBF24';
    } else {
      geoLabel.textContent = 'Геолокация недоступна на этом устройстве';
      geoLabel.style.color = '#FBBF24';
    }
  });

  cancelBtn.onclick = ((Event _) {
    closeStream();
    if (!completer.isCompleted) completer.complete(null);
  }).toJS;

  Future<void> captureFrame() async {
    final w = video.videoWidth > 0 ? video.videoWidth : 1280;
    final h = video.videoHeight > 0 ? video.videoHeight : 720;
    final canvas = HTMLCanvasElement()
      ..width = w
      ..height = h;
    final ctx = canvas.getContext('2d') as CanvasRenderingContext2D?;
    if (ctx == null) {
      closeStream();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    ctx.drawImage(video, 0, 0, w, h);
    final meta = await geoFuture;
    final blobCompleter = Completer<Blob?>();
    canvas.toBlob(
      ((Blob? b) {
        if (!blobCompleter.isCompleted) blobCompleter.complete(b);
      }).toJS,
      'image/jpeg',
      0.92.toJS,
    );
    final blob = await blobCompleter.future;
    closeStream();
    if (blob == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final buffer = await blob.arrayBuffer().toDart;
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (!completer.isCompleted) {
      completer.complete(
        PickedFile(
          name: 'site-photo-$stamp.jpg',
          bytes: Uint8List.view(buffer.toDart),
          meta: PhotoCaptureMeta(
            captureSource: 'camera',
            capturedAt: DateTime.now().toUtc(),
            gpsLat: meta.gpsLat,
            gpsLon: meta.gpsLon,
            gpsAccuracy: meta.gpsAccuracy,
            gpsHeading: meta.gpsHeading,
            geoStatus: meta.geoStatus,
          ),
        ),
      );
    }
  }

  shootBtn.onclick = ((Event _) {
    unawaited(captureFrame());
  }).toJS;

  actions.append(cancelBtn);
  actions.append(shootBtn);
  card.append(header);
  card.append(geoLabel);
  card.append(video);
  card.append(actions);
  overlay.append(card);
  document.body?.append(overlay);

  return completer.future;
}
