import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const password = 'Pilot-2026-demo';
const testDatabaseUrl =
    'postgres://ibuild:ibuild@localhost:5433/ibuild_test?sslmode=disable';

late AppDatabase db;
late Handler handler;
late Directory files;

void main() {
  late Connection lock;

  setUpAll(() async {
    final admin = Pool.withUrl(
      'postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable',
    );
    try {
      final existing = await admin.execute(
        "SELECT 1 FROM pg_database WHERE datname = 'ibuild_test'",
      );
      if (existing.isEmpty) await admin.execute('CREATE DATABASE ibuild_test');
    } finally {
      await admin.close();
    }
    lock = await Connection.openFromUrl(testDatabaseUrl);
    await lock.execute('SELECT pg_advisory_lock(424242)');
    files = await Directory.systemTemp.createTemp('ibuild-files');
    db = await AppDatabase.open(testDatabaseUrl);
    await db.migrate('migrations');
    await db.truncateAll();
    await seedDemo(db, password);
    handler = buildHandler(db: db, env: _env(files.path));
  });

  tearDownAll(() async {
    await db.close();
    if (files.existsSync()) await files.delete(recursive: true);
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  test('a draft is private and does not reserve the budget', () async {
    final mason = await _session('a.contractor');
    final other = await _session('a.contractor2');
    final director = await _session('a.director');
    final projectId = mason.projectId;
    final before = await mason.client.send('GET', '/api/projects/$projectId');
    expect(before.body!['reserved'], '0.00');
    expect(before.body!['available'], navoiMasonryPlan);

    final budget = await mason.client.send('GET', '/api/projects/$projectId/budget');
    final lines = (budget.body!['items'] as List).cast<Map<String, dynamic>>();
    final foundation = lines.firstWhere((item) => item['title'] == 'Фундамент');
    final directorBudget = await director.client.send('GET', '/api/projects/$projectId/budget');
    final engineering = ((directorBudget.body!['items'] as List).cast<Map<String, dynamic>>())
        .firstWhere((item) => item['title'] == 'Инженерия');

    final missing = await mason.client.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': foundation['id'],
      'amount': '10.00',
      'description': 'без подписи',
    });
    expect(missing.status, 403);

    final foreignLine = await mason.client.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': engineering['id'],
      'amount': '10.00',
      'description': 'чужая статья',
    }, withCsrf: true);
    expect(foreignLine.status, 404);

    final filed = await director.client.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': foundation['id'],
      'amount': '10.00',
      'description': 'заявка директора',
    }, withCsrf: true);
    expect(filed.status, 201, reason: filed.body.toString());
    expect(filed.body!['status'], 'draft');
    expect(filed.body!['mine'], isTrue);
    expect((await mason.client.send('GET', '/api/requests/${filed.body!['id']}')).status, 404);

    final created = await mason.client.send('POST', '/api/requests', json: {
      'projectId': projectId,
      'budgetItemId': foundation['id'],
      'amount': '2500000',
      'description': 'Бетон на отметке 0',
    }, withCsrf: true);
    expect(created.status, 201);
    expect(created.body!['status'], 'draft');
    expect(created.body!['amount'], '2500000.00');
    expect(created.body!['mine'], isTrue);
    expect(created.body!.containsKey('storagePath'), isFalse);
    final requestId = created.body!['id'] as String;

    final after = await mason.client.send('GET', '/api/projects/$projectId');
    expect(after.body!['reserved'], '0.00');
    expect(after.body!['available'], navoiMasonryPlan);
    expect(after.body!['budgetLocked'], isFalse);
    final stillOpen = await mason.client.send('GET', '/api/projects/$projectId/budget');
    expect(stillOpen.body!['locked'], isFalse);

    expect((await director.client.send('GET', '/api/requests/$requestId')).status, 404);
    expect((await other.client.send('GET', '/api/requests/$requestId')).status, 404);
    final directorList = await director.client.send('GET', '/api/requests');
    final listed = (directorList.body!['requests'] as List).cast<Map<String, dynamic>>();
    expect(listed.where((item) => item['id'] == requestId), isEmpty);
    final ownList = await mason.client.send('GET', '/api/requests');
    expect(
      (ownList.body!['requests'] as List).cast<Map<String, dynamic>>().single['id'],
      requestId,
    );

    final edited = await mason.client.send('PATCH', '/api/requests/$requestId', json: {
      'budgetItemId': foundation['id'],
      'amount': '1800000.50',
      'description': 'Бетон, правка',
    }, withCsrf: true);
    expect(edited.status, 200);
    expect(edited.body!['amount'], '1800000.50');
    expect(edited.body!['description'], 'Бетон, правка');
    final stillFree = await director.client.send('GET', '/api/projects/$projectId');
    expect(stillFree.body!['reserved'], '0.00');
    expect(stillFree.body!['available'], navoiPlan);

    final jpeg = _jpeg();
    final photo = await mason.client.sendBytes('POST', '/api/requests/$requestId/files', jpeg);
    expect(photo.status, 201, reason: photo.raw);
    final photoJson = jsonDecode(photo.raw) as Map<String, dynamic>;
    expect(photoJson['kind'], 'photo');
    expect(photoJson['contentType'], 'image/jpeg');
    expect(photoJson.containsKey('storagePath'), isFalse);
    expect(photoJson.containsKey('url'), isFalse);
    final fileId = photoJson['id'] as String;

    final png = await mason.client.sendBytes('POST', '/api/requests/$requestId/files', _png());
    expect(png.status, 201);
    final webp = await mason.client.sendBytes('POST', '/api/requests/$requestId/files', _webp());
    expect(webp.status, 201);
    final pdf = await mason.client.sendBytes('POST', '/api/requests/$requestId/files', _pdf());
    expect(pdf.status, 201);
    final pdfJson = jsonDecode(pdf.raw) as Map<String, dynamic>;
    expect(pdfJson['kind'], 'pdf');

    final text = await mason.client.sendBytes(
      'POST',
      '/api/requests/$requestId/files',
      Uint8List.fromList('not a photo'.codeUnits),
    );
    expect(text.status, 400);
    expect(jsonDecode(text.raw)['message'], 'Подойдёт фото (JPEG, PNG, WebP) или PDF.');

    final secondPdf = await mason.client.sendBytes('POST', '/api/requests/$requestId/files', _pdf());
    expect(secondPdf.status, 400);
    expect(jsonDecode(secondPdf.raw)['message'], 'PDF уже добавлен.');

    expect((await mason.client.sendBytes('POST', '/api/requests/$requestId/files', _jpeg())).status, 201);
    expect((await mason.client.sendBytes('POST', '/api/requests/$requestId/files', _jpeg())).status, 201);
    final sixth = await mason.client.sendBytes('POST', '/api/requests/$requestId/files', _jpeg());
    expect(sixth.status, 400);
    expect(jsonDecode(sixth.raw)['message'], 'Можно добавить не больше 5 фото.');

    final huge = Uint8List(5 * 1024 * 1024 + 1);
    huge[0] = 0xFF;
    huge[1] = 0xD8;
    huge[2] = 0xFF;
    final tooBig = await mason.client.sendBytes('POST', '/api/requests/$requestId/files', huge);
    expect(tooBig.status, 400);
    expect(jsonDecode(tooBig.raw)['message'], 'Фото больше 5 МБ.');

    final anon = Client(handler);
    expect((await anon.sendBytes('GET', '/api/requests/$requestId/files/$fileId')).status, 401);
    expect((await director.client.sendBytes('GET', '/api/requests/$requestId/files/$fileId')).status, 404);
    final downloaded = await mason.client.sendBytes('GET', '/api/requests/$requestId/files/$fileId');
    expect(downloaded.status, 200);
    expect(downloaded.contentType, contains('image/jpeg'));
    expect(downloaded.headers['content-disposition'], 'inline; filename="photo.jpg"');
    expect(downloaded.bytes, jpeg);

    final leaked = await mason.client.sendBytes('GET', '/data/files/$requestId/$fileId');
    expect(leaked.bytes, isNot(jpeg));

    final removed = await mason.client.send('DELETE', '/api/requests/$requestId/files/$fileId', withCsrf: true);
    expect(removed.status, 204);
    expect((await mason.client.sendBytes('GET', '/api/requests/$requestId/files/$fileId')).status, 404);

    final card = await mason.client.send('GET', '/api/requests/$requestId');
    final names = jsonEncode(card.body);
    expect(names.contains('storagePath'), isFalse);
    expect((card.body!['files'] as List).length, 5);
  });
}

Uint8List _jpeg() => Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

Uint8List _png() => Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00,
]);

Uint8List _webp() => Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
]);

Uint8List _pdf() => Uint8List.fromList('%PDF-1.4'.codeUnits);

AppEnv _env(String fileRoot) {
  return AppEnv(
    databaseUrl: testDatabaseUrl,
    host: 'localhost',
    port: 8080,
    seedOnStart: false,
    seedPassword: password,
    webRoot: null,
    cookieSecure: false,
    migrationsDir: 'migrations',
    sessionTtl: const Duration(hours: 12),
    loginFailureLimit: 5,
    loginWindow: const Duration(minutes: 15),
    fileRoot: fileRoot,
  );
}

Future<Session> _session(String login) async {
  final client = Client(handler);
  final signed = await client.login(login, password);
  expect(signed.status, 200, reason: login);
  final projects = await client.send('GET', '/api/projects');
  final list = (projects.body!['projects'] as List).cast<Map<String, dynamic>>();
  final project = list.firstWhere((item) => item['name'] == 'ЖК Навои');
  return Session(client, project);
}

class Session {
  Session(this.client, this.project);

  final Client client;
  final Map<String, dynamic> project;

  String get projectId => project['id'] as String;
}

class Client {
  Client(this.handler);

  final Handler handler;
  final cookies = <String, String>{};
  String? csrf;

  Future<Call> login(String login, String password) async {
    await send('GET', '/api/auth/csrf');
    return send('POST', '/api/auth/login', json: {
      'login': login,
      'password': password,
    }, withCsrf: true);
  }

  Future<Call> send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    bool withCsrf = false,
  }) async {
    final raw = await _call(method, path, body: json == null ? null : utf8.encode(jsonEncode(json)), jsonBody: json != null, withCsrf: withCsrf);
    Map<String, dynamic>? body;
    if (raw.bytes.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(raw.bytes));
      if (decoded is Map) {
        body = decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (body?['csrfToken'] is String) csrf = body!['csrfToken'] as String;
    return Call(raw.status, body);
  }

  Future<RawCall> sendBytes(String method, String path, [Uint8List? bytes]) {
    return _call(
      method,
      path,
      body: bytes,
      jsonBody: false,
      withCsrf: method != 'GET',
      binary: true,
    );
  }

  Future<RawCall> _call(
    String method,
    String path, {
    List<int>? body,
    required bool jsonBody,
    required bool withCsrf,
    bool binary = false,
  }) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (jsonBody) 'content-type': 'application/json',
      if (binary && body != null) 'content-type': 'application/octet-stream',
      if (withCsrf && csrf != null) 'x-csrf-token': csrf!,
    };
    final response = await handler(
      Request(method, Uri.parse('http://localhost$path'), headers: headers, body: body),
    );
    for (final line in response.headersAll['set-cookie'] ?? const <String>[]) {
      final first = line.split(';').first;
      final separator = first.indexOf('=');
      if (separator <= 0) continue;
      final name = first.substring(0, separator).trim();
      final value = first.substring(separator + 1).trim();
      if (line.toLowerCase().contains('max-age=0') || value.isEmpty) {
        cookies.remove(name);
      } else {
        cookies[name] = value;
      }
      if (name == 'ibuild_csrf') csrf = value;
    }
    final bytes = await response.read().fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    return RawCall(response.statusCode, Uint8List.fromList(bytes), response.headers);
  }
}

class Call {
  Call(this.status, this.body);

  final int status;
  final Map<String, dynamic>? body;
}

class RawCall {
  RawCall(this.status, this.bytes, this.headers);

  final int status;
  final Uint8List bytes;
  final Map<String, String> headers;

  String get raw => utf8.decode(bytes, allowMalformed: true);
  String? get contentType => headers['content-type'];
}
