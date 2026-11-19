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

void main() {
  late AppDatabase db;
  late Handler handler;
  late Connection lock;
  late Directory files;

  setUpAll(() async {
    final admin = Pool<void>.withUrl(
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
    db = await AppDatabase.open(testDatabaseUrl);
    await db.migrate('migrations');
    await db.truncateAll();
    await seedDemo(db, password);
    files = await Directory.systemTemp.createTemp('ibuild-object-');
    handler = buildHandler(db: db, env: _env(files.path));
  });

  tearDownAll(() async {
    await db.close();
    if (files.existsSync()) await files.delete(recursive: true);
    await lock.execute('SELECT pg_advisory_unlock(424242)');
    await lock.close();
  });

  test('object edits wait for the platform admin', () async {
    final director = Client(handler);
    expect((await director.login('a.director', password)).status, 200);
    expect((await director.send('GET', '/api/auth/me')).body!['platformAdmin'], false);
    final projects = await director.send('GET', '/api/projects');
    final project = (projects.body!['projects'] as List).cast<Map<String, dynamic>>().singleWhere(
      (item) => item['name'] == 'ЖК Навои',
    );
    final projectId = project['id'] as String;
    expect(project['name'], 'ЖК Навои');

    final proposed = await director.send(
      'POST',
      '/api/projects/$projectId/changes',
      bytes: _form(
        name: 'ЖК Навои обновлён',
        address: 'Ташкент, новый адрес',
        photo: _png,
      ),
      contentType: 'multipart/form-data; boundary=ibuildboundary',
      withCsrf: true,
    );
    expect(proposed.status, 201, reason: '${proposed.body}');
    expect(proposed.body!['status'], 'pending');
    expect(proposed.body!['hasPhoto'], true);
    final changeId = proposed.body!['id'] as String;

    final again = await director.send(
      'POST',
      '/api/projects/$projectId/changes',
      json: {'name': 'Ещё раз', 'address': 'Ташкент'},
      withCsrf: true,
    );
    expect(again.status, 409);

    final still = await director.send('GET', '/api/projects/$projectId');
    expect(still.body!['name'], 'ЖК Навои');
    expect(still.body!['hasPhoto'], false);

    final bank = Client(handler);
    await bank.login('a.observer', password);
    final denied = await bank.send(
      'POST',
      '/api/admin/changes/$changeId/approve',
      json: {},
      withCsrf: true,
    );
    expect(denied.status, 403);

    final other = Client(handler);
    await other.login('b.director', password);
    final hidden = await other.send('GET', '/api/projects/$projectId/changes');
    expect(hidden.status, 404);
    final foreignQueue = await other.send('GET', '/api/admin/changes');
    expect(foreignQueue.status, 403);

    final admin = Client(handler);
    final signedIn = await admin.login('a.admin', password);
    expect(signedIn.status, 200);
    expect(signedIn.body!['platformAdmin'], true);
    final visible = await admin.send('GET', '/api/projects');
    expect((visible.body!['projects'] as List).length, 2);
    final queue = await admin.send('GET', '/api/admin/changes');
    expect(queue.status, 200);
    final pending = (queue.body!['changes'] as List).cast<Map<String, dynamic>>();
    expect(pending.single['name'], 'ЖК Навои обновлён');
    expect(pending.single['currentName'], 'ЖК Навои');

    final approved = await admin.send(
      'POST',
      '/api/admin/changes/$changeId/approve',
      json: {},
      withCsrf: true,
    );
    expect(approved.status, 200, reason: '${approved.body}');

    final published = await director.send('GET', '/api/projects/$projectId');
    expect(published.body!['name'], 'ЖК Навои обновлён');
    expect(published.body!['address'], 'Ташкент, новый адрес');
    expect(published.body!['hasPhoto'], true);
    final photo = await director.send('GET', '/api/projects/$projectId/photo');
    expect(photo.status, 200);
    expect(photo.bytes, _png);
  });
}

final _png = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0];

List<int> _form({
  required String name,
  required String address,
  required List<int> photo,
}) {
  const boundary = 'ibuildboundary';
  final builder = BytesBuilder();
  void field(String key, String value) {
    builder.add(utf8.encode(
      '--$boundary\r\ncontent-disposition: form-data; name="$key"\r\n\r\n$value\r\n',
    ));
  }

  field('name', name);
  field('address', address);
  builder.add(utf8.encode(
    '--$boundary\r\ncontent-disposition: form-data; name="photo"; filename="p.png"\r\ncontent-type: image/png\r\n\r\n',
  ));
  builder.add(photo);
  builder.add(utf8.encode('\r\n--$boundary--\r\n'));
  return builder.takeBytes();
}

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

class Call {
  Call(this.status, this.body, this.bytes);

  final int status;
  final Map<String, dynamic>? body;
  final List<int> bytes;
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
    List<int>? bytes,
    String? contentType,
    bool withCsrf = false,
  }) async {
    final headers = <String, String>{
      if (cookies.isNotEmpty)
        'cookie': cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
      if (json != null) 'content-type': 'application/json',
      if (contentType != null) 'content-type': contentType,
      if (withCsrf && csrf != null) 'x-csrf-token': csrf!,
    };
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: headers,
        body: json != null ? jsonEncode(json) : bytes,
      ),
    );
    final setCookies = response.headersAll['set-cookie'] ?? const <String>[];
    for (final line in setCookies) {
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
    final raw = await response.read().fold<List<int>>(<int>[], (list, chunk) => list..addAll(chunk));
    Map<String, dynamic>? body;
    if (raw.isNotEmpty && (response.headers['content-type'] ?? '').contains('json')) {
      final decoded = jsonDecode(utf8.decode(raw));
      if (decoded is Map) {
        body = decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (body?['csrfToken'] is String) csrf = body!['csrfToken'] as String;
    return Call(response.statusCode, body, raw);
  }
}
