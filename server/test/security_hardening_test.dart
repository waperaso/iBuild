import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ibuild_server/ibuild_server.dart';
import 'package:ibuild_server/src/http_util.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('a long chunked body is refused without reading the rest', () async {
    var pulled = 0;
    final limited = await readAtMost(() async* {
      for (var i = 0; i < 6; i++) {
        pulled++;
        yield Uint8List(40);
      }
    }(), 100);
    expect(limited.overflow, isTrue);
    expect(pulled, 3);

    pulled = 0;
    final response = await applyBodyLimit(100, (Request request) async {
      await for (final _ in request.read()) {}
      return Response.ok('should not');
    })(Request(
      'POST',
      Uri.parse('http://localhost/api/auth/login'),
      body: () async* {
        for (var i = 0; i < 6; i++) {
          pulled++;
          yield Uint8List(40);
        }
      }(),
    ));
    expect(response.statusCode, 413);
    expect(pulled, lessThan(6));

    final declared = await applyBodyLimit(10, (Request request) async => Response.ok('no'))(
      Request('POST', Uri.parse('http://localhost/x'), body: '12345678901'),
    );
    expect(declared.statusCode, 413);
  });

  test('the forwarded client is the last hop, and only when the proxy is trusted', () {
    final request = Request(
      'GET',
      Uri.parse('http://localhost/api/applications'),
      headers: {'x-forwarded-for': '1.1.1.1, 10.0.0.8'},
    );
    expect(clientAddress(request, trustProxy: true), '10.0.0.8');
    expect(clientAddress(request, trustProxy: false), 'local');
  });

  test('a database password comes from a file and is not left in the url raw', () async {
    final dir = await Directory.systemTemp.createTemp('ibuild-secret-');
    try {
      final file = File('${dir.path}/db_password');
      await file.writeAsString('p@ss:word\n');
      final env = AppEnv.parse({
        'APP_ENV': 'production',
        'COOKIE_SECURE': 'true',
        'SEED_ON_START': 'false',
        'DB_HOST': 'db',
        'DB_PASSWORD_FILE': file.path,
        'MAIL_KEY': base64Encode(Uint8List(32)),
        'TRUST_PROXY': 'true',
      });
      expect(env.secretProblems, isEmpty);
      expect(env.productionProblems(), isEmpty);
      expect(env.databaseUrl, contains('p%40ss%3Aword'));
      expect(env.databaseUrl, isNot(contains('p@ss:word')));
      expect(env.databaseUrl, contains('@db:5432/ibuild?sslmode=disable'));
      expect(env.trustProxy, isTrue);

      final both = AppEnv.parse({'DB_PASSWORD': 'plain', 'DB_PASSWORD_FILE': file.path});
      expect(both.secretProblems, contains('DB_PASSWORD и DB_PASSWORD_FILE заданы вместе'));
      final missing = AppEnv.parse({'MAIL_KEY_FILE': '${dir.path}/missing'});
      expect(missing.secretProblems, ['MAIL_KEY_FILE не найден']);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('the listener does not send X-Powered-By', () async {
    final server = await serveApi((Request request) => Response.ok('ok'), '127.0.0.1', 0);
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:${server.port}/api/health'));
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.value('x-powered-by'), isNull);
      await response.drain<void>();
    } finally {
      client.close(force: true);
      await server.close(force: true);
    }
  });

  test('production compose drops privileges and caddy hides the server', () {
    final compose = File('../docker-compose.prod.yml').readAsStringSync();
    expect(compose, contains('no-new-privileges:true'));
    expect(compose, contains('cap_drop:'));
    expect(compose, contains('- ALL'));
    expect(compose, contains('read_only: true'));
    expect(compose, contains('ibuild_pg:/var/lib/postgresql/data'));
    expect(compose, contains('ibuild_files:/app/data/files'));
    expect(compose, contains('NET_BIND_SERVICE'));
    final caddy = File('../deploy/Caddyfile').readAsStringSync();
    expect(caddy, contains('-X-Powered-By'));
    expect(caddy, contains('-Via'));
    expect(caddy, contains('X-Forwarded-For {remote_host}'));
  });
}
