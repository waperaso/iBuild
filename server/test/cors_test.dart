import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/src/http_helpers.dart';

Request _withOrigin(String? origin) => Request(
  'GET',
  Uri.parse('http://localhost/v1/health'),
  headers: {if (origin != null) 'origin': origin},
);

void main() {
  group('corsHeadersFor', () {
    test('always advertises the allowed methods/headers', () {
      final headers = corsHeadersFor(_withOrigin(null));
      expect(headers['Access-Control-Allow-Methods'], contains('GET'));
      expect(
        headers['Access-Control-Allow-Headers'],
        contains('Authorization'),
      );
    });

    // Dart can't mutate process env; these checks need ALLOWED_ORIGINS unset.
    final allowList = Platform.environment['ALLOWED_ORIGINS'];
    final envUnset = allowList == null || allowList.trim().isEmpty;

    test(
      'reflects loopback origins but never emits a wildcard by default',
      () {
        final local = corsHeadersFor(_withOrigin('http://localhost:8099'));
        expect(local['Access-Control-Allow-Origin'], 'http://localhost:8099');
        expect(local['Vary'], 'Origin');

        final loopbackIp = corsHeadersFor(_withOrigin('http://127.0.0.1:3000'));
        expect(
          loopbackIp['Access-Control-Allow-Origin'],
          'http://127.0.0.1:3000',
        );
      },
      skip: envUnset ? false : 'ALLOWED_ORIGINS is set in this environment',
    );

    test(
      'blocks unknown remote origins (no Access-Control-Allow-Origin)',
      () {
        final remote = corsHeadersFor(_withOrigin('https://evil.example.com'));
        expect(remote.containsKey('Access-Control-Allow-Origin'), isFalse);
      },
      skip: envUnset ? false : 'ALLOWED_ORIGINS is set in this environment',
    );

    test(
      'no origin header yields no Access-Control-Allow-Origin',
      () {
        final none = corsHeadersFor(_withOrigin(null));
        expect(none.containsKey('Access-Control-Allow-Origin'), isFalse);
      },
      skip: envUnset ? false : 'ALLOWED_ORIGINS is set in this environment',
    );
  });
}
