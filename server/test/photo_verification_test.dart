import 'dart:convert';
import 'dart:typed_data';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _password = 'Pilot-2026-demo';
const _testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

/// Builds a valid minimal JPEG with an APP1 EXIF segment containing Make, Model,
/// DateTimeOriginal, GPSLatitude, GPSLongitude, GPSAltitude, and GPSImgDirection.
Uint8List buildJpegWithExif({
  required String make,
  required String model,
  required String dateTimeOriginal,
  required double lat,
  required double lon,
  double altitudeM = 465.0,
  double headingDeg = 185.5,
  bool bigEndian = false,
  int uniqueTag = 0,
}) {
  final endian = bigEndian ? Endian.big : Endian.little;
  final latRef = lat >= 0 ? 'N' : 'S';
  final lonRef = lon >= 0 ? 'E' : 'W';
  final latAbs = lat.abs();
  final lonAbs = lon.abs();

  List<(int, int)> dms(double deg) {
    final d = deg.floor();
    final remMin = (deg - d) * 60.0;
    final m = remMin.floor();
    final sec = ((remMin - m) * 60.0 * 1000).round();
    return [(d, 1), (m, 1), (sec, 1000)];
  }

  final buf = BytesBuilder();
  // TIFF header (8 bytes): byte order + 42 + offset to IFD0 (8).
  buf.add(bigEndian ? [0x4D, 0x4D] : [0x49, 0x49]);
  void addU16(int v) {
    final bd = ByteData(2)..setUint16(0, v, endian);
    buf.add(bd.buffer.asUint8List());
  }

  void addU32(int v) {
    final bd = ByteData(4)..setUint32(0, v, endian);
    buf.add(bd.buffer.asUint8List());
  }

  addU16(42);
  addU32(8);

  // Layout offsets (relative to TIFF start):
  // IFD0 at 8: 4 entries (Make, Model, ExifIFD, GPSIFD) -> 2 + 4*12 + 4 = 54 bytes -> ends at 62.
  final makeBytes = [...utf8.encode(make), 0];
  final modelBytes = [...utf8.encode(model), 0];
  final dtBytes = [...utf8.encode(dateTimeOriginal), 0];

  final makeOff = 62;
  final modelOff = makeOff + makeBytes.length;
  final exifIfdOff = (modelOff + modelBytes.length + 1) & ~1;
  // ExifIFD: 1 entry (DateTimeOriginal) -> 2 + 12 + 4 = 18 bytes.
  final dtOff = exifIfdOff + 18;
  final gpsIfdOff = (dtOff + dtBytes.length + 1) & ~1;
  // GPSIFD: 7 entries (LatRef, Lat, LonRef, Lon, AltRef, Alt, ImgDirection) -> 2 + 7*12 + 4 = 90 bytes.
  final gpsLatOff = gpsIfdOff + 90;
  final gpsLonOff = gpsLatOff + 24;
  final gpsAltOff = gpsLonOff + 24;
  final gpsDirOff = gpsAltOff + 8;

  void addEntry(int tag, int type, int count, int valueOrOffset) {
    addU16(tag);
    addU16(type);
    addU32(count);
    addU32(valueOrOffset);
  }

  void addAsciiInline(int tag, String text) {
    addU16(tag);
    addU16(2);
    addU32(text.length + 1);
    final raw = Uint8List(4);
    final enc = utf8.encode(text);
    for (var i = 0; i < enc.length && i < 3; i++) {
      raw[i] = enc[i];
    }
    buf.add(raw);
  }

  // IFD0
  addU16(4);
  addEntry(0x010F, 2, makeBytes.length, makeOff);
  addEntry(0x0110, 2, modelBytes.length, modelOff);
  addEntry(0x8769, 4, 1, exifIfdOff);
  addEntry(0x8825, 4, 1, gpsIfdOff);
  addU32(0); // next IFD

  buf.add(makeBytes);
  buf.add(modelBytes);
  while (buf.length < exifIfdOff) {
    buf.addByte(0);
  }

  // ExifIFD
  addU16(1);
  addEntry(0x9003, 2, dtBytes.length, dtOff);
  addU32(0);
  buf.add(dtBytes);
  while (buf.length < gpsIfdOff) {
    buf.addByte(0);
  }

  // GPSIFD
  addU16(7);
  addAsciiInline(0x0001, latRef);
  addEntry(0x0002, 5, 3, gpsLatOff);
  addAsciiInline(0x0003, lonRef);
  addEntry(0x0004, 5, 3, gpsLonOff);
  addEntry(0x0005, 1, 1, 0); // above sea level
  addEntry(0x0006, 5, 1, gpsAltOff);
  addEntry(0x0011, 5, 1, gpsDirOff);
  addU32(0);

  for (final r in dms(latAbs)) {
    addU32(r.$1);
    addU32(r.$2);
  }
  for (final r in dms(lonAbs)) {
    addU32(r.$1);
    addU32(r.$2);
  }
  addU32((altitudeM * 10).round());
  addU32(10);
  addU32((headingDeg * 10).round());
  addU32(10);

  final tiff = buf.toBytes();
  final app1Payload = BytesBuilder()
    ..add(utf8.encode('Exif\x00\x00'))
    ..add(tiff);
  final payloadBytes = app1Payload.toBytes();
  final app1Len = payloadBytes.length + 2;

  final jpeg = BytesBuilder();
  jpeg.add([0xFF, 0xD8]); // SOI
  jpeg.add([0xFF, 0xE1, (app1Len >> 8) & 0xFF, app1Len & 0xFF]); // APP1
  jpeg.add(payloadBytes);
  // Comment marker so tests can generate distinct SHA-256 bytes easily.
  final comment = utf8.encode('ibuild-test-$uniqueTag');
  final comLen = comment.length + 2;
  jpeg.add([0xFF, 0xFE, (comLen >> 8) & 0xFF, comLen & 0xFF]);
  jpeg.add(comment);
  jpeg.add([0xFF, 0xD9]); // EOI
  return jpeg.toBytes();
}

Uint8List buildPlainJpeg(int seed) => Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xFE, 0x00, 0x06,
      (seed >> 24) & 0xFF, (seed >> 16) & 0xFF, (seed >> 8) & 0xFF, seed & 0xFF,
      0xFF, 0xD9,
    ]);

void main() {
  group('EXIF parser & photo forensics unit tests', () {
    test('extracts Make, Model, DateTimeOriginal and GPS tags from Little-Endian JPEG', () {
      final bytes = buildJpegWithExif(
        make: 'Apple',
        model: 'iPhone 15 Pro',
        dateTimeOriginal: '2026:11:24 14:30:15',
        lat: 41.3115,
        lon: 69.2407,
        altitudeM: 465.0,
        headingDeg: 185.5,
      );

      final exif = parseExif(bytes);
      expect(exif.present, isTrue);
      expect(exif.cameraMake, 'Apple');
      expect(exif.cameraModel, 'iPhone 15 Pro');
      expect(exif.takenAt, isNotNull);
      expect(exif.takenAt!.year, 2026);
      expect(exif.takenAt!.month, 11);
      expect(exif.takenAt!.day, 24);
      expect(exif.lat, closeTo(41.3115, 0.0001));
      expect(exif.lon, closeTo(69.2407, 0.0001));
      expect(exif.altitude, closeTo(465.0, 0.2));
      expect(exif.heading, closeTo(185.5, 0.2));
    });

    test('extracts negative South/West GPS coordinates from Big-Endian JPEG', () {
      final bytes = buildJpegWithExif(
        make: 'Samsung',
        model: 'Galaxy S24',
        dateTimeOriginal: '2026:11:20 09:00:00',
        lat: -33.8688,
        lon: -151.2093,
        bigEndian: true,
      );

      final exif = parseExif(bytes);
      expect(exif.present, isTrue);
      expect(exif.cameraMake, 'Samsung');
      expect(exif.cameraModel, 'Galaxy S24');
      expect(exif.lat, closeTo(-33.8688, 0.0001));
      expect(exif.lon, closeTo(-151.2093, 0.0001));
    });

    test('marks fresh on-site camera photo as verified with zero flags', () {
      final now = DateTime.utc(2026, 11, 25, 10, 0);
      final bytes = buildJpegWithExif(
        make: 'Apple',
        model: 'iPhone 15 Pro',
        dateTimeOriginal: '2026:11:25 09:50:00',
        lat: 41.3111,
        lon: 69.2406,
      );

      final v = verifyPhotoBytes(
        bytes: bytes,
        isPhoto: true,
        client: ClientPhotoMeta(
          captureSource: 'camera',
          capturedAt: now,
          gpsLat: 41.3112,
          gpsLon: 69.2406,
          gpsAccuracy: 12.0,
          gpsHeading: 185.0,
        ),
        projectLat: 41.311081,
        projectLon: 69.240562,
        now: now,
        enforce: true,
      );

      expect(v.sha256, hasLength(64));
      expect(v.verifyStatus, 'verified');
      expect(v.verifyFlags, isEmpty);
      expect(v.distanceM, isNotNull);
      expect(v.distanceM!, lessThan(100));
    });

    test('flags far_from_site, geo_mismatch, stale_photo and duplicate_checksum', () {
      final now = DateTime.utc(2026, 11, 25, 10, 0);
      final bytes = buildJpegWithExif(
        make: 'Canon',
        model: 'EOS',
        dateTimeOriginal: '2025:01:10 10:00:00',
        lat: 41.4000, // ~10 km from site
        lon: 69.3500,
      );

      final v = verifyPhotoBytes(
        bytes: bytes,
        isPhoto: true,
        client: const ClientPhotoMeta(
          captureSource: 'upload',
          gpsLat: 41.3111, // disagrees with EXIF GPS
          gpsLon: 69.2406,
        ),
        projectLat: 41.311081,
        projectLon: 69.240562,
        duplicateOfFileId: 'prev-file-1',
        now: now,
        enforce: true,
      );

      expect(v.verifyStatus, 'alert');
      expect(v.verifyFlags, containsAll([
        'duplicate_checksum',
        'far_from_site',
        'geo_mismatch',
        'stale_photo',
        'uploaded_from_gallery',
      ]));
      expect(v.duplicateOfFileId, 'prev-file-1');
    });

    test('flags no_exif and no_geo on plain stripped JPEG without device GPS', () {
      final v = verifyPhotoBytes(
        bytes: buildPlainJpeg(7),
        isPhoto: true,
        client: const ClientPhotoMeta(captureSource: 'upload'),
        projectLat: 41.311081,
        projectLon: 69.240562,
        enforce: true,
      );

      expect(v.verifyStatus, 'warning');
      expect(v.verifyFlags, containsAll(['no_exif', 'no_geo', 'uploaded_from_gallery']));
    });
  });

  group('mandatory tranche photo & bank forensics integration', () {
    late AppDatabase db;
    late Handler handler;
    late Connection lock;

    setUpAll(() async {
      await _ensureTestDatabase();
      lock = await Connection.openFromUrl(_testDatabaseUrl);
      await lock.execute('SELECT pg_advisory_lock(424242)');
      db = await AppDatabase.open(_testDatabaseUrl);
      await db.migrate('migrations');
      await db.truncateAll();
      await seedDemo(db, _password);
      await ensureBankCabinet(db, _password);
      handler = buildHandler(db: db, env: _env());
    });

    tearDownAll(() async {
      await db.close();
      await lock.execute('SELECT pg_advisory_unlock(424242)');
      await lock.close();
    });

    test('Permissions-Policy allows same-origin camera and geolocation', () async {
      final res = await handler(Request('GET', Uri.parse('http://localhost/api/health')));
      final policy = res.headers['permissions-policy'] ?? '';
      expect(policy, contains('camera=(self)'));
      expect(policy, contains('geolocation=(self)'));
    });

    test('draw submit rejects without photo, persists EXIF+SHA-256+GPS, detects duplicates, far geo & UP-11 30% equity on bank card', () async {
      final dev = _Client(handler);
      expect((await dev.login('a.director', _password)).status, 200);
      final bank = _Client(handler);
      expect((await bank.login('a.observer', _password)).status, 200);

      // Create a fresh project with site coordinates and a linked bank facility.
      final created = await dev.send('POST', '/api/projects', csrf: true, json: {
        'name': 'ЖК Фотоконтроль',
        'address': 'Ташкент, ул. Амира Темура, 1',
      });
      expect(created.status, 201);
      final projectId = created.body!['id'] as String;

      await db.owner.execute(
        Sql.named('UPDATE projects SET latitude = 41.311081, longitude = 69.240562 WHERE id = @id::uuid'),
        parameters: {'id': projectId},
      );

      final users = ((await dev.send('GET', '/api/company/users')).body!['users'] as List)
          .cast<Map<String, dynamic>>();
      final observerId = users.firstWhere((u) => u['login'] == 'a.observer')['id'] as String;
      await dev.send('POST', '/api/projects/$projectId/members', csrf: true, json: {
        'userId': observerId,
        'role': 'observer',
      });

      final firms = ((await dev.send('GET', '/api/contractor-firms')).body!['firms'] as List)
          .cast<Map<String, dynamic>>();
      final firmId = firms.first['id'] as String;

      expect(
        (await dev.send('POST', '/api/projects/$projectId/budget/import', csrf: true, json: {
          'contractorFirmId': firmId,
          'csv': '03,Монолит,hard,use,1000.00',
        }))
            .status,
        201,
      );

      // Add funding sources with < 30% developer equity (200 equity vs 800 loan = 20%)
      // to verify UP-11 30% own-funds warning too.
      final equitySrc = await dev.send('POST', '/api/projects/$projectId/sources', csrf: true, json: {
        'name': 'Собственные средства',
        'kind': 'equity',
        'amount': '200.00',
      });
      final loanSrc = await dev.send('POST', '/api/projects/$projectId/sources', csrf: true, json: {
        'name': 'Проектное финансирование',
        'kind': 'loan',
        'amount': '800.00',
      });
      expect(equitySrc.status, 201);
      expect(loanSrc.status, 201);

      final loan = await dev.send('GET', '/api/projects/$projectId/loan');
      final uses = (loan.body!['lines'] as List)
          .cast<Map<String, dynamic>>()
          .where((l) => l['budget_side'] == 'use')
          .toList();
      final lineId = uses.first['id'] as String;
      final loanSourceId = loanSrc.body!['id'] as String;

      final bankRows = await db.owner.execute('SELECT bank_id::text FROM project_facilities LIMIT 1');
      await db.owner.execute(
        Sql.named('''
          INSERT INTO project_facilities (project_id, bank_id, developer_name, credit_limit, issued_amount)
          VALUES (@p::uuid, @b::uuid, 'ООО Фотоконтроль', 5000.00, 0)
        '''),
        parameters: {'p': projectId, 'b': bankRows.first.first},
      );

      Future<String> prepareDraftDraw(String name, String amount) async {
        final draw = await dev.send('POST', '/api/draws', csrf: true, json: {
          'projectId': projectId,
          'name': name,
        });
        expect(draw.status, 201);
        final drawId = draw.body!['id'] as String;
        final detail = await dev.send('GET', '/api/draws/$drawId');
        final reqs = (detail.body!['requirements'] as List).cast<Map<String, dynamic>>();
        for (final req in reqs) {
          if (req['required'] != true) continue;
          final r = await dev.upload(
            '/api/draws/$drawId/documents/${req['item_id']}?name=doc.pdf',
            Uint8List.fromList('%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n'.codeUnits),
            contentType: 'application/octet-stream',
          );
          expect(r.status, 201);
        }
        final patched = await dev.send('PATCH', '/api/draws/$drawId', csrf: true, json: {
          'signedName': 'Директор',
          'lines': [
            {
              'budgetItemId': lineId,
              'requested': amount,
              'retainageWithheld': '0.00',
              'retainageReleased': '0.00',
              'storedMaterials': '0.00',
            },
          ],
          'sources': [
            {'sourceId': loanSourceId, 'amount': amount},
          ],
          'requirements': [
            for (final req in reqs)
              if (req['required'] == true) {'itemId': req['item_id'], 'status': 'attached'},
          ],
        });
        expect(patched.status, 200);
        return drawId;
      }

      // 1. Draw without site photo -> submit MUST fail with 400!
      final drawId = await prepareDraftDraw('Транш Фото 1', '100.00');
      final blockedSubmit = await dev.send('POST', '/api/draws/$drawId/submit', csrf: true);
      expect(blockedSubmit.status, 400);
      expect(blockedSubmit.body!['message'], contains('фото с объекта'));

      // 2. Upload real EXIF + GPS photo captured on site.
      final nowUtc = DateTime.now().toUtc();
      final exifDate =
          '${nowUtc.year.toString().padLeft(4, '0')}:'
          '${nowUtc.month.toString().padLeft(2, '0')}:'
          '${nowUtc.day.toString().padLeft(2, '0')} '
          '${nowUtc.hour.toString().padLeft(2, '0')}:'
          '${nowUtc.minute.toString().padLeft(2, '0')}:'
          '${nowUtc.second.toString().padLeft(2, '0')}';
      final verifiedJpeg = buildJpegWithExif(
        make: 'Apple',
        model: 'iPhone 15 Pro',
        dateTimeOriginal: exifDate,
        lat: 41.31112,
        lon: 69.24059,
        uniqueTag: 101,
      );
      final expectedHash = sha256Bytes(verifiedJpeg);

      final uploadRes = await dev.upload(
        '/api/requests/$drawId/files',
        verifiedJpeg,
        headers: {
          'x-capture-source': 'camera',
          'x-geo-lat': '41.31110',
          'x-geo-lon': '69.24058',
          'x-geo-accuracy': '10.5',
          'x-geo-heading': '185.0',
          'x-captured-at': nowUtc.toIso8601String(),
        },
      );
      expect(uploadRes.status, 201);
      final fileJson = uploadRes.body!;
      expect(fileJson['sha256'], expectedHash);
      expect(fileJson['captureSource'], 'camera');
      expect(fileJson['cameraMake'], 'Apple');
      expect(fileJson['cameraModel'], 'iPhone 15 Pro');
      expect(fileJson['verifyStatus'], 'verified');
      expect(fileJson['verifyFlags'], isEmpty);
      expect((fileJson['distanceM'] as num).toDouble(), lessThan(50));

      // Verify draw GET returns `photos` with full forensic fields.
      final drawGet = await dev.send('GET', '/api/draws/$drawId');
      expect(drawGet.status, 200);
      final photos = (drawGet.body!['photos'] as List).cast<Map<String, dynamic>>();
      expect(photos, hasLength(1));
      expect(photos.first['sha256'], expectedHash);

      // Submit now succeeds!
      final okSubmit = await dev.send('POST', '/api/draws/$drawId/submit', csrf: true);
      expect(okSubmit.status, 200);

      Future<String> trancheIdFor(String requestId) async {
        final rows = await db.owner.execute(
          Sql.named('SELECT id::text FROM bank_tranches WHERE request_id = @r::uuid'),
          parameters: {'r': requestId},
        );
        expect(rows, hasLength(1));
        return rows.first[0]! as String;
      }

      // 3. Bank specialist views tranche card: sees sitePhotos, passed_photos, own_funds_30 warning, and can download photo.
      final tranche1Id = await trancheIdFor(drawId);
      final cardRes = await bank.send('GET', '/api/bank/tranches/$tranche1Id');
      expect(cardRes.status, 200);
      final sitePhotos = (cardRes.body!['sitePhotos'] as List).cast<Map<String, dynamic>>();
      expect(sitePhotos, hasLength(1));
      expect(sitePhotos.first['sha256'], expectedHash);
      expect(sitePhotos.first['verifyStatus'], 'verified');
      final photoUrl = sitePhotos.first['url'] as String;
      expect(photoUrl, startsWith('/api/bank/tranches/$tranche1Id/photos/'));

      final photoDownload = await bank.rawGet(photoUrl);
      expect(photoDownload.statusCode, 200);
      final downloadedBytes = await photoDownload.read().expand((c) => c).toList();
      expect(sha256Bytes(Uint8List.fromList(downloadedBytes)), expectedHash);

      List<Map<String, dynamic>> allChecks(Map<String, dynamic> card) {
        final raw = card['checks'] as Map<String, dynamic>;
        return [
          ...(raw['open'] as List).cast<Map<String, dynamic>>(),
          ...(raw['passed'] as List).cast<Map<String, dynamic>>(),
        ];
      }

      final checks = allChecks(cardRes.body!);
      expect(checks.any((c) => c['code'] == 'passed_photos' && c['passed'] == true), isTrue);
      expect(checks.any((c) => c['code'] == 'own_funds_30' && c['level'] == 'warning'), isTrue);

      // 4. The same file uploaded again is accepted during the test period:
      // checksum is stored, and it does not block the bank.
      final draw2Id = await prepareDraftDraw('Транш Фото 2 (дубликат)', '50.00');
      final dupUpload = await dev.upload(
        '/api/requests/$draw2Id/files',
        verifiedJpeg,
        headers: {
          'x-capture-source': 'upload',
        },
      );
      expect(dupUpload.status, 201);
      final dupFile = dupUpload.body!;
      expect(dupFile['sha256'], expectedHash);
      expect(dupFile['verifyStatus'], 'verified');
      expect(dupFile['verifyFlags'], isEmpty);

      expect((await dev.send('POST', '/api/draws/$draw2Id/submit', csrf: true)).status, 200);
      final tranche2Id = await trancheIdFor(draw2Id);
      final card2Res = await bank.send('GET', '/api/bank/tranches/$tranche2Id');
      expect(card2Res.status, 200);
      final checks2 = allChecks(card2Res.body!);
      expect(checks2.any((c) => c['code'] == 'passed_photos' && c['passed'] == true), isTrue);
      expect(checks2.any((c) => c['code'] == 'photo_duplicate'), isFalse);

      // 5. A photo taken far from the site is also accepted during the test period.
      final draw3Id = await prepareDraftDraw('Транш Фото 3 (далеко)', '50.00');
      final farJpeg = buildJpegWithExif(
        make: 'Samsung',
        model: 'S24',
        dateTimeOriginal: exifDate,
        lat: 41.4500,
        lon: 69.4000,
        uniqueTag: 303,
      );
      final farUpload = await dev.upload(
        '/api/requests/$draw3Id/files',
        farJpeg,
        headers: {
          'x-capture-source': 'upload',
        },
      );
      expect(farUpload.status, 201);
      expect(farUpload.body!['verifyStatus'], 'verified');
      expect(farUpload.body!['verifyFlags'], isEmpty);

      expect((await dev.send('POST', '/api/draws/$draw3Id/submit', csrf: true)).status, 200);
      final tranche3Id = await trancheIdFor(draw3Id);
      final card3Res = await bank.send('GET', '/api/bank/tranches/$tranche3Id');
      final checks3 = allChecks(card3Res.body!);
      expect(checks3.any((c) => c['code'] == 'passed_photos' && c['passed'] == true), isTrue);
      expect(checks3.any((c) => c['code'] == 'photo_geo'), isFalse);
    });
  });
}

AppEnv _env() => AppEnv(
      databaseUrl: _testDatabaseUrl,
      host: 'localhost',
      port: 8080,
      seedOnStart: false,
      seedPassword: _password,
      webRoot: null,
      cookieSecure: false,
      migrationsDir: 'migrations',
      sessionTtl: const Duration(hours: 12),
      loginFailureLimit: 5,
      loginWindow: const Duration(minutes: 15),
    );

Future<void> _ensureTestDatabase() async {
  final admin = await Connection.openFromUrl(
    'postgres://ibuild:ibuild@localhost:5433/postgres?sslmode=disable',
  );
  try {
    final rows = await admin.execute(
      "SELECT 1 FROM pg_database WHERE datname = 'ibuild_test'",
    );
    if (rows.isEmpty) {
      await admin.execute('CREATE DATABASE ibuild_test');
    }
  } finally {
    await admin.close();
  }
}

class _Call {
  _Call(this.status, this.body);
  final int status;
  final Map<String, dynamic>? body;
}

class _Client {
  _Client(this.handler);

  final Handler handler;
  final cookies = <String, String>{};
  String? csrf;

  Future<_Call> login(String login, String password) async {
    await send('GET', '/api/auth/csrf');
    return send('POST', '/api/auth/login', csrf: true, json: {
      'login': login,
      'password': password,
    });
  }

  Future<_Call> send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    bool csrf = false,
    Map<String, String> headers = const {},
  }) async {
    final sent = <String, String>{
      ...headers,
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (csrf && this.csrf != null) 'x-csrf-token': this.csrf!,
    };
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: sent,
        body: json == null ? null : jsonEncode(json),
      ),
    );
    _captureCookies(response);
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty && raw.startsWith('{')) {
      body = (jsonDecode(raw) as Map).map((k, v) => MapEntry(k.toString(), v));
      if (body['csrfToken'] is String) this.csrf = body['csrfToken'] as String;
    }
    return _Call(response.statusCode, body);
  }

  Future<_Call> upload(
    String path,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
    Map<String, String> headers = const {},
  }) async {
    final sent = <String, String>{
      'content-type': contentType,
      ...headers,
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      if (csrf != null) 'x-csrf-token': csrf!,
    };
    final response = await handler(
      Request('POST', Uri.parse('http://localhost$path'), headers: sent, body: bytes),
    );
    _captureCookies(response);
    final raw = await response.readAsString();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty && raw.startsWith('{')) {
      body = (jsonDecode(raw) as Map).map((k, v) => MapEntry(k.toString(), v));
    }
    return _Call(response.statusCode, body);
  }

  Future<Response> rawGet(String path) async => handler(
        Request(
          'GET',
          Uri.parse('http://localhost$path'),
          headers: {
            if (cookies.isNotEmpty)
              'cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
          },
        ),
      );

  void _captureCookies(Response response) {
    for (final line in response.headersAll['set-cookie'] ?? const <String>[]) {
      final first = line.split(';').first;
      final sep = first.indexOf('=');
      if (sep <= 0) continue;
      final name = first.substring(0, sep).trim();
      final value = first.substring(sep + 1).trim();
      cookies[name] = value;
      if (name == 'ibuild_csrf') csrf = value;
    }
  }
}
